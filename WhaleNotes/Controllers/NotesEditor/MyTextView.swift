//
//  MyTextView.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

class MyTextView: UITextView {
    
    override func caretRect(for position: UITextPosition) -> CGRect {
          var superRect = super.caretRect(for: position)
          guard let font = self.font else { return superRect }
        
        
        let lineHeight = font.lineHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0

          // "descender" is expressed as a negative value,
          // so to add its height you must subtract its value
          superRect.size.height = font.pointSize - font.descender + MDStyleConfig.lineSpacing*3
//        superRect.size.height *= 0.75
          return superRect
      }
}
