//
//  NoteBlock.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct NoteBlock {
    var id: Int64
    var type: BlockType
    var data: [String: Any]?
    var sort: Int
    var noteId: Int64
}

extension NoteBlock {
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func toJSONData() -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else {
            return ""
        }
        let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!
        return jsonString
    }
}

enum BlockType: Int {
    case title = 1
    case content = 2
}
