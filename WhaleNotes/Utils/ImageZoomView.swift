//
//  ImageBlockView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class ImageZoomView: UIScrollView, UIScrollViewDelegate {
    
    var imageView: UIImageView!
    var gestureRecognizer: UITapGestureRecognizer!
    
    convenience init(frame: CGRect, image: UIImage,imageSize:CGSize) {
        self.init(frame: frame)
        
        let imageToUse: UIImage = image
        
        // Creates the image view and adds it as a subview to the scroll view
        imageView = UIImageView(image: imageToUse)
//        imageView.frame  = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        imageView.frame  =  frame
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        setupScrollView(image: imageToUse)
        setupGestureRecognizer()
    }
    
    // Sets the scroll view delegate and zoom scale limits.
    // Change the `maximumZoomScale` to allow zooming more than 2x.
    func setupScrollView(image: UIImage) {
        delegate = self
        
        minimumZoomScale = 1.0
        maximumZoomScale = 2.0
        
        imageView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(self)
            // or:
            // make.centerX.equalTo(self.scrollView)
            // make.centerY.equalTo(self.scrollView)
        }
        self.clipsToBounds = true
    }
    
    // Sets up the gesture recognizer that receives double taps to auto-zoom
    func setupGestureRecognizer() {
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        gestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(gestureRecognizer)
    }

    // Handles a double tap by either resetting the zoom or zooming to where was tapped
    @objc func handleDoubleTap() {
        if zoomScale == 1 {
            zoom(to: zoomRectForScale(maximumZoomScale, center: gestureRecognizer.location(in: gestureRecognizer.view)), animated: true)
        } else {
            setZoomScale(1, animated: true)
        }
    }

    // Calculates the zoom rectangle for the scale
    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    // Tell the scroll view delegate which view to use for zooming and scrolling
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

//extension ViewController: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return imageView
//    }
//
//    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        if scrollView.zoomScale > 1 {
//            if let image = imageView.image {
//                let ratioW = imageView.frame.width / image.size.width
//                let ratioH = imageView.frame.height / image.size.height
//
//                let ratio = ratioW < ratioH ? ratioW : ratioH
//                let newWidth = image.size.width * ratio
//                let newHeight = image.size.height * ratio
//                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
//                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
//                let conditioTop = newHeight*scrollView.zoomScale > imageView.frame.height
//
//                let top = 0.5 * (conditioTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
//
//                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
//
//            }
//        } else {
//            scrollView.contentInset = .zero
//        }
//    }
//}
