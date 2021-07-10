//
//  ImageDownloader.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/10.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import Kingfisher

class ImageDownloader {
    
    static let shared = ImageDownloader()
    private init(){
       
    }
    
    func downloadImage(`with` url : URL,imageW:CGFloat,callback:@escaping ((UIImage?)->Void)){
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: imageW, height: imageW))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
                                               .processor(processor),
                                               .loadDiskFileSynchronously,
                                               .transition(.fade(0.25))
                                           ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                print("Image: \(value.image). Got from: \(value.cacheType)")
                callback(value.image)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    
}
