//
//  NoteAndTag.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
struct NoteAndTag {
    var id:String = UUID.init().uuidString
    var noteId:String = ""
    var tagId:String = ""
}

extension NoteAndTag:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "note_tag" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "note_id" TEXT NOT NULL,
                  "tag_id" TEXT NOT NULL,
                  UNIQUE("note_id","tag_id"),
                  FOREIGN KEY("note_id") REFERENCES note(id),
                  FOREIGN KEY("tag_id") REFERENCES tag(id)
                );
        """
    }
}
