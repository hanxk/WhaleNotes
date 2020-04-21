//
//  DBStore.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

class NoteStore {
    
    static let shared = NoteStore()
    
    let notesDao:NotesDao  =  NotesDao()
    let blockDao:NoteBlocksDao  =  NoteBlocksDao()
    
    fileprivate var db: Connection {
        return SQLiteManager.manager.getDB()
    }
    
    func getNotes() -> DBResult<[Note]> {
        do {
            let notes = try notesDao.getNotes(tagId: 1, order: 1)
            var newNotes:[Note] = []
            for note in notes {
                let blocks = try blockDao.getNoteBlocks(noteId: note.id)
                newNotes.append(note.clone(blocks: blocks))
            }
            return DBResult<[Note]>.success(newNotes)
        } catch let err {
            print(err)
            return DBResult<[Note]>.failure(DBError(code: .None))
        }
    }

    func insertNote(_ note:Note) -> DBResult<Note> {
      do {
        let noteId = try notesDao.insert(note)
        return DBResult<Note>.success(note.clone(id: noteId))
      } catch let err {
        print(err)
        return DBResult<Note>.failure(DBError(code: .None))
      }
    }
    
    
}
