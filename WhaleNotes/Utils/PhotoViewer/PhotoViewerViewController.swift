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
    
    static func show(blocks:[Block],pageIndex:Int = 0,srcImageView:UIImageArgu? = nil) {
        let imageUrls:[String] = blocks.map {
                      ImageUtil.sharedInstance.dirPath.appendingPathComponent($0.source).absoluteString
                  }
       show(imageUrls: imageUrls, pageIndex: pageIndex, srcImageView: srcImageView)
    }
    
    static func show(imageUrls:[String],pageIndex:Int = 0,srcImageView:UIImageArgu? = nil) {
        let browser = PhotoViewerViewController(imageUrls: imageUrls,pageIndex: pageIndex,srcImageView:srcImageView)
        browser.pageIndex = pageIndex
        browser.show()
    }
    
    convenience init(imageUrls:[String],pageIndex:Int,srcImageView:UIImageArgu? = nil) {
        self.init()
        self.imageUrls = imageUrls
        self.browserView.numberOfItems = {
            imageUrls.count
            
        }
        self.srcImageView = srcImageView
        self.reloadCellAtIndex = { context in
            if let browserCell = context.cell as? JXPhotoBrowserImageCell {
                print(browserCell.index)
                print(self.pageIndex)
                
                browserCell.imageView.setLocalImage(filePath: imageUrls[self.pageIndex]) {
                    browserCell.setNeedsLayout()
                }
            }
        }
        self.pageIndicator = JXPhotoBrowserNumberPageIndicator()
        self.pageIndex = pageIndex
        
        self.transitionAnimator = JXPhotoBrowserSmoothZoomAnimator(transitionViewAndFrame: { (index, destinationView) -> JXPhotoBrowserSmoothZoomAnimator.TransitionViewAndFrame? in
            if let srcImageView = self.srcImageView {
                let transitionView = UIImageView(image: srcImageView.image)
                transitionView.contentMode = srcImageView.view.contentMode
                transitionView.clipsToBounds = true
                let thumbnailFrame = srcImageView.view.convert(srcImageView.view.bounds, to: destinationView)
                return (transitionView, thumbnailFrame)
            }
            return nil
        })

    }
    
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
    
}

struct UIImageArgu {
   let image:UIImage
   let view:UIView
}
