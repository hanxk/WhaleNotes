//
//  MDHighlightManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/7.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

class MDHighlightManager {

    private(set) var headerHightlighter:MDHeaderHighlighter!
    private(set) var tagHightlighter:MDTagHighlighter!
    private(set) var linkHightlighter:MDLinkHighlighter!
    private(set) var bulletHightlighter:MDBulletListHighlighter!
    private(set) var numListHightlighter:MDNumListHighlighter!
    
    private var mdHighlighters:[MDHighlighterType]
    
    init(style:MDStyle) {
        headerHightlighter = MDHeaderHighlighter(maxLevel: 3)
        let linkFont  = MDStyle.generateDefaultFont(fontSize: style.font.pointSize, weight: .medium)
        tagHightlighter =  MDTagHighlighter(font: linkFont)
        linkHightlighter = MDLinkHighlighter(font: linkFont)
        bulletHightlighter = MDBulletListHighlighter()
        numListHightlighter = MDNumListHighlighter()
        self.mdHighlighters = [headerHightlighter,tagHightlighter,linkHightlighter]
    }
    
    
    func highlight(textStorage:NSTextStorage,range:NSRange) {
        for highlighter in mdHighlighters {
          highlighter.highlight(storage: textStorage, searchRange: range)
        }
    }
    
}
