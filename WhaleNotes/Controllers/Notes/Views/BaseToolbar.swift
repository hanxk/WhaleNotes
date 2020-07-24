//
//  BaseToolbar.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BaseToolbar: UIView {
    
    
    func generateUIBarButtonImage(imageName:String,imageSize:CGFloat = 24) -> UIImage {
        let weight:UIImage.SymbolWeight = .regular
        let image = UIImage(systemName: imageName, pointSize: imageSize, weight: weight)!
        return image
    }
    
}
