//
//  ActionButton.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
class ActionButton: UIButton {

  var originalBackgroundColor: UIColor!

  override var backgroundColor: UIColor? {
    didSet {
      if originalBackgroundColor == nil {
        originalBackgroundColor = backgroundColor
      }
    }
  }

  override var isHighlighted: Bool {
    didSet {
      guard let originalBackgroundColor = originalBackgroundColor else {
        return
      }

      backgroundColor = isHighlighted ? originalBackgroundColor.darker() : originalBackgroundColor
    }
  }
    
}
