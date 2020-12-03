//
//  ViewController.swift
//  Example
//
//  Created by Nabil on 05/10/17.
//  Copyright © 2017 Nabil. All rights reserved.
//

import UIKit
import SwiftSoup
import SnapKit
import YYCategories


extension String{
    func toCGFloat() -> CGFloat{
        if let f = NumberFormatter().number(from: self){
            return CGFloat(truncating: f)
        }else{
            return 0
        }
    }
}


class ViewController: UIViewController {
    
    typealias Item = (text: String, html: String)
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var urlTextField: UITextField!
    @IBOutlet var cssTextField: UITextField!
    
    lazy var resultLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .orange
        return label
    }()
    
    // current document
    var document: Document = Document.init("")
    // item founds
    var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        self.title = "SwiftSoup Example"
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = UITableView.automaticDimension
        
        urlTextField.text = "http://www.facebook.com"
        cssTextField.text = "div"
        
        // start first request
//        downloadHTML()
        tableView.isHidden = true
        
        urlTextField.text = """
<span style="font-size:14px;font-family: Poppins-Regular;">Add <span style="color: #ff4546;">2</span> More to Get <span style="color: #ff4546;">11%</span> Off</span>
"""
        
        view.addSubview(resultLabel)
        resultLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(32)
            make.trailing.equalTo(-32)
            make.top.equalTo(cssTextField.snp.bottom).offset(20)
        }
        
    }
    
    //Download HTML
    func downloadHTML() {
        // url string to URL
        guard let url = URL(string: urlTextField.text ?? "") else {
            // an error occurred
            UIAlertController.showAlert("Error: \(urlTextField.text ?? "") doesn't seem to be a valid URL", self)
            return
        }
        
        do {
            // content of url
            let html = try String.init(contentsOf: url)
            // parse it into a Document
            document = try SwiftSoup.parse(html)
            // parse css query
            parse()
        } catch let error {
            // an error occurred
            UIAlertController.showAlert("Error: \(error)", self)
        }
        
    }
    
    //Parse CSS selector
    func parse() {
        do {
            //empty old items
            items = []
            // firn css selector
            let elements: Elements = try document.select(cssTextField.text ?? "")
            //transform it into a local object (Item)
            for element in elements {
                let text = try element.text()
                let html = try element.outerHtml()
                items.append(Item(text: text, html: html))
            }
            
        } catch let error {
            UIAlertController.showAlert("Error: \(error)", self)
        }
        
        tableView.reloadData()
    }
    
    
    func style(style : String) -> [NSAttributedString.Key:Any]{
        let attri = style.components(separatedBy: ";").compactMap{(sub : String) -> [NSAttributedString.Key:Any]? in
            let trimSub = sub.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimSub.isEmpty{
                return nil
            }else{
                let attri = trimSub.components(separatedBy: ";")
                if attri.count <= 1 {
                    return nil
                }else{
                    let _style = Style(key: attri.first!, value: attri.last!)
                    guard let __style = _style else {
                        return nil
                    }
                    return __style.attributed()
                }
            }
        }
        
        
        
        return [:]
    }
    
    
    enum Style {
        case font(key: NSAttributedString.Key, font : UIFont)
        case color(key: NSAttributedString.Key, color : UIColor)
        
        init?(key : String, value : String) {
            let attributedKey = Self.mapping()[key]
            guard let _attributedKey = attributedKey else {
                return nil
            }
            switch _attributedKey {
            case .font:
                var fontSize : CGFloat
                if value.lowercased().hasSuffix("px") {
                    fontSize = value.toCGFloat() / UIScreen.main.scale
                }else{
                    fontSize = value.toCGFloat()
                }
                self = .font(key: _attributedKey, font: .systemFont(ofSize: fontSize))
            case .foregroundColor:
                //TODO:需要使用默认色和默认字体
                self = .color(key: _attributedKey, color: UIColor(hexString: value)!)
            default:
                return nil
            }
        }
        
        func attributed() -> [NSAttributedString.Key:Any]{
            switch self {
            case let .font(key, font):
                return [key:font]
            case let .color(key, color):
                return [key:color]
            }
        }
        
        static func mapping() -> [String : NSAttributedString.Key]{
            return ["font-size" : .font, "color" : .foregroundColor]
        }
        
    }
    
    
    @IBAction func chooseQuery(_ sender: Any) {
        
        do {
            let html = urlTextField.text!
            let doc: Document = try SwiftSoup.parse(html)
            
            let span = try doc.select("span").first()!
            let text = try span.text()
            let style = try span.getAttributes()?.getIgnoreCase(key: "style")
            let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor : UIColor(hexString: "")])
            
            for e : Element in span.children(){
                let text = try e.text()
                
                
                print("..... \(e)")
                print("..... \(try e.text())")
            }
            
//            let span = try doc.select("span").first()!
//            let subSpan = try span.children().select("span").first()!
//            let style = try span.getAttributes()?.get(key: "style")
//            resultLabel.text = style
            
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        return
        
        
        guard let viewController = storyboard?.instantiateViewController(
                withIdentifier: "QueryViewController") as? QueryViewController  else {
            return
        }
        viewController.completionHandler = {[weak self](resilt) in
            self?.navigationController?.popViewController(animated: true)
            self?.cssTextField.text = resilt.example
            self?.parse()
        }
        self.show(viewController, sender: self)
    }
    
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
            cell?.textLabel?.numberOfLines = 2
            cell?.detailTextLabel?.numberOfLines = 6
            
            cell?.textLabel?.textColor = UIColor.init(red: 1.0/255, green: 174.0/255, blue: 66.0/255, alpha: 1)
            cell?.detailTextLabel?.textColor = UIColor.init(red: 55.0/255, green: 67.0/255, blue: 55.0/255, alpha: 1)
            
            cell?.backgroundColor = UIColor.init(red: 245.0/255, green: 245.0/255, blue: 245.0/255, alpha: 1)
        }
        
        cell?.textLabel?.text = items[indexPath.row].text
        cell?.detailTextLabel?.text = items[indexPath.row].html
        
        let color1 = UIColor.init(red: 245.0/255, green: 245.0/255, blue: 245.0/255, alpha: 1)
        let color2 = UIColor.init(red: 240.0/255, green: 240.0/255, blue: 240.0/255, alpha: 1)
        cell?.backgroundColor = (indexPath.row % 2) == 0 ? color1 : color2
        
        return  cell!
    }
}

extension ViewController: UITableViewDelegate {
}

extension ViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == urlTextField {
            downloadHTML()
        }
        
        if textField == cssTextField {
            parse()
        }
    }
}

extension UIAlertController {
    static public func showAlert(_ message: String, _ controller: UIViewController) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
