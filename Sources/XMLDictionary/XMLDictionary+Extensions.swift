//
//  XMLDictionary+Extensions.swift
//  XMLDictionary
//
//  Created by Volker Bublitz on 23/02/2017.
//
//

import Cocoa

enum XMLDictionaryKeys : String {
    case xmlDictionaryAttributesKey = "__attributes",
    xmlDictionaryCommentsKey = "__comments",
    xmlDictionaryTextKey = "__text",
    xmlDictionaryNodeNameKey = "__name",
    xmlDictionaryAttributePrefix = "_"
    
    func length() -> Int {
        return self.rawValue.characters.count
    }
    func isArtificialNonAttributesKey() -> Bool {
        switch self {
        case .xmlDictionaryCommentsKey, .xmlDictionaryNodeNameKey, .xmlDictionaryTextKey:
            return true
        default:
            return false
        }
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral {
    
    static func dictionaryWithXMLParser(parser:XMLParser) -> [String: Any]? {
        if let copy = XMLDictionaryParser.sharedInstance.copy() as? XMLDictionaryParser {
            return copy.dictionaryWithParser(parser: parser)
        }
        return nil
    }
    
    static func dictionaryWithXMLData(xmlData:Data) -> [String: Any]? {
        if let copy = XMLDictionaryParser.sharedInstance.copy() as? XMLDictionaryParser {
            return copy.dictionaryWithData(data: xmlData)
        }
        return nil
    }
    
    static func dictionaryWithXMLString(xmlString: String) -> [String: Any]? {
        if let copy = XMLDictionaryParser.sharedInstance.copy() as? XMLDictionaryParser {
            return copy.dictionaryWithString(string: xmlString)
        }
        return nil
    }
    
    static func dictionaryWithXMLFile(xmlFilePath: String) -> [String: Any]? {
        if let copy = XMLDictionaryParser.sharedInstance.copy() as? XMLDictionaryParser {
            return copy.dictionaryWithFile(path: xmlFilePath)
        }
        return nil
    }
    
    func attributes() -> [String : String]? {
        if let attributes = self[XMLDictionaryKeys.xmlDictionaryAttributesKey.rawValue as! Key] as? [String: String] {
            return attributes.count > 0 ? attributes : nil
        }
        else {
            let filteredDict = self.filter({ (key, value) -> Bool in
                if let kK = XMLDictionaryKeys(rawValue: String(describing: key)) {
                    return !kK.isArtificialNonAttributesKey()
                }
                return true
            })
            var result:[String : String] = [:]
            for (key, value) in filteredDict {
                guard let sValue = value as? String else {
                    continue
                }
                let sKey = String(describing: key)
                if sKey.hasPrefix(XMLDictionaryKeys.xmlDictionaryAttributePrefix.rawValue) {
                    let index = sKey.index(sKey.startIndex, offsetBy: XMLDictionaryKeys.xmlDictionaryAttributePrefix.length())
                    result[sKey.substring(from: index)] = sValue
                }
            }
            return result.count > 0 ? result : nil
        }
    }
    
    func childNodes() -> [String: Any]? {
        var result:[String:Any] = [:]
        self.forEach { (key, value) in
            let sKey = String(describing: key)
            if let _ = XMLDictionaryKeys(rawValue: sKey) {
                return
            }
            if sKey.hasPrefix(XMLDictionaryKeys.xmlDictionaryAttributePrefix.rawValue) {
                return
            }
            result[sKey] = value
        }
        return result.count > 0 ? result : nil
    }
    
    func comments() -> [String]? {
        return self[XMLDictionaryKeys.xmlDictionaryCommentsKey.rawValue as! Key] as? [String]
    }
    
    func nodeName() -> String? {
        return self[XMLDictionaryKeys.xmlDictionaryNodeNameKey.rawValue as! Key] as? String
    }
    
    func innerText() -> Any? {
        let tmpResult = self[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue as! Key]
        if let result = tmpResult as? [String] {
            return result.joined(separator: "\n")
        }
        return tmpResult
    }
    
    func innerXML() -> String {
        var nodes:[String] = []
        nodes.append(contentsOf: self.comments()?.map({ (comment) -> String in
            return "<!--\(comment.xmlEncodedString())-->"
        }) ?? [])
        nodes.append(contentsOf: self.childNodes()?.map({ (key, value) -> String in
            return XMLDictionaryParser.XMLStringForNode(node: value, withNodeName: key)
        }) ?? [])
        if let text = self.innerText() as? String {
            nodes.append(text)
        }
        return nodes.joined(separator: "\n")
    }
    
    func xmlString() -> String {
        let nodeName = self.nodeName()
        if self.count == 1 && nodeName == nil {
            return self.innerXML()
        }
        return XMLDictionaryParser.XMLStringForNode(node: self, withNodeName: nodeName ?? "root")
    }
}

extension String {
    func xmlEncodedString() -> String {
        return self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\'", with: "&apos;")
    }
}
