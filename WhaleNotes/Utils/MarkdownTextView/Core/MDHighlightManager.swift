//
//  MDHighlightManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/7.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

class MDHighlightManager {
    let headerHightlighter = MDHeaderHighlighter(maxLevel: 3)
    
    let tagHightlighter = MDTagHighlighter()
    let linkHightlighter = MDLinkHighlighter()
    
    let bulletHightlighter = MDBulletListHighlighter()
    let numListHightlighter = MDNumListHighlighter()
    
    
    private lazy var mdHighlighters:[MDHighlighterType] = [headerHightlighter,tagHightlighter,linkHightlighter]
    
    
    func highlight(textStorage:NSTextStorage,range:NSRange) {
        for highlighter in mdHighlighters {
          highlighter.highlight(storage: textStorage, searchRange: range)
        }
    }
    
}
