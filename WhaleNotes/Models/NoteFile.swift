//
//  NoteFile.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import DeepDiff

struct NoteFile {
    var id:String = UUID.init().uuidString
    var noteId:String
    var width:Double
    var height:Double
    var fileSize:Int
    var sort:Int
    var fileType:NoteFiletype = .photo
    var createdAt:Date
    var updatedAt:Date
}
extension NoteFile:DiffAware {
    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        (a.id == b.id)
    }
}

enum NoteFiletype:Int {
    case photo = 1
    case video = 2
}

extension NoteFile:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note_file" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "note_id" TEXT,
                      "width" double,
                      "height" double,
                      "file_size" INTEGER,
                      "sort" INTEGER,
                      "file_type" INTEGER,
                      "created_at" TIMESTAMP,
                      "updated_at" TIMESTAMP
                    );
        """
    }
}
