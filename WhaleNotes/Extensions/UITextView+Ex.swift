//
//  UITextView+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

extension UITextView{

    func numberOfLines() -> Int{
        if let fontUnwrapped = self.font{
            return Int(self.contentSize.height / fontUnwrapped.lineHeight)
        }
        return 0
    }

}
