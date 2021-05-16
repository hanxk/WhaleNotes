//
//  MarkdownHeaderCommon.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import MarkdownKit

class MDHeaderCommon: MarkdownHeader {
    
    init() {
        super.init()
        self.font = MDStyleConfig.headerFont
        self.color = .primaryText
    }
    
    override var regex: String {
        return "^(#{1,\(6)})\\s+(.*)$"
    }
    
    override func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int) {
        attributedString.deleteCharacters(in: range)
    }
    
    override func attributesForLevel(_ level: Int) -> [NSAttributedString.Key: AnyObject] {
        var attributes = self.attributes
        let newLevel = 1
        if let font = font {
            let headerFontSize: CGFloat = font.pointSize
            
            attributes[NSAttributedString.Key.font] = font.withSize(headerFontSize).bold()
        }
        return attributes
    }
}
