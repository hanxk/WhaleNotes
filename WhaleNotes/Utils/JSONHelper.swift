//
//  JSONHelper.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation


//func json2StringArray(json:String) -> [String]? {
//    do {
//        let data = Data(json.utf8)
//        // make sure this JSON is in the format we expect
//        if let strArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String] {
//           return strArray
//        }
//        return nil
//    } catch let error as NSError {
//        print("Failed to load: \(error.localizedDescription)")
//    }
//    return nil
//}


func json2Object<T:Codable>(_ json:String,type:T.Type) -> T? {
    let decoder = JSONDecoder()
    do {
        let jsonData = Data(json.utf8)
        let obj = try decoder.decode(type, from: jsonData)
        return obj
    } catch {
        print(error.localizedDescription)
    }
    return nil
}


func json(from object:Encodable) -> String? {
    if let jsonData = object.toJSONData() {
        return String(data: jsonData, encoding: .utf8)!
    }
    return nil
}

extension Encodable {
    func toJSONData() -> Data? { try? JSONEncoder().encode(self) }
}
