//
//  PhotoViewerViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import JXPhotoBrowser


class PhotoViewerViewController:JXPhotoBrowser {
    var imageUrls:[String] = []
    var srcImageView:UIImageArgu?
    var images:[UIImage] = []
    
    
    public typealias PhotoViewerTranAnimProvider = (_ index: Int, _ destinationView: UIView) -> (transitionView: UIView, thumbnailFrame: CGRect)
    
    convenience init(blocks:[Block],pageIndex:Int = 0) {
        
        let imageUrls:[String] = blocks.map {
                      ImageUtil.sharedInstance.dirPath.appendingPathComponent($0.source).absoluteString
                  }
        self.init(imageUrls:imageUrls,pageIndex:pageIndex)
    }
    
    
    convenience init(imageUrls:[String],pageIndex:Int = 0) {
        self.init()
        self.pageIndex = pageIndex
        self.imageUrls = imageUrls
        self.browserView.numberOfItems = {
            imageUrls.count
            
        }
        
        self.reloadCellAtIndex = { context in
            if let browserCell = context.cell as? JXPhotoBrowserImageCell {
                browserCell.imageView.setLocalImage(filePath: imageUrls[context.index]) {
                    browserCell.setNeedsLayout()
                }
            }
        }
        self.pageIndicator = JXPhotoBrowserNumberPageIndicator()

    }
}

struct UIImageArgu {
   let image:UIImage
   let view:UIView
}
