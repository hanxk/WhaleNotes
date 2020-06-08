//
//  Emoji2.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation


struct CategoryAndEmoji {
    var category:EmojiCategory
    var emojis:[Emoji]
}

struct EmojiCategory {
    var emoji:String
    var text:String
    var csvName:String
}

struct Emoji {
    let value:String
    let keywords:[String]
    
    init(value:String,keywords:[String]) {
        self.value = value
        self.keywords = keywords
    }
    
 }





