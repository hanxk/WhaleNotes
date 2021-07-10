//
//  ASImageManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/4.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Kingfisher


extension ASNetworkImageNode {
    static func imageNode() -> ASNetworkImageNode {
        let imageNode = ASNetworkImageNode(cache: ASImageManager.shared,
                                           downloader: ASImageManager.shared)
        return imageNode
    }
}


class ASImageManager: NSObject, ASImageDownloaderProtocol, ASImageCacheProtocol {
    func downloadImage(with URL: URL, callbackQueue: DispatchQueue, downloadProgress: ASImageDownloaderProgress?, completion: @escaping ASImageDownloaderCompletion) -> Any? {
        return nil
    }
    
    func cancelImageDownload(forIdentifier downloadIdentifier: Any) {
        
    }
    
    func cachedImage(with URL: URL, callbackQueue: DispatchQueue, completion: @escaping ASImageCacherCompletion) {
        
    }
    static let shared = ASImageManager.init()
    private override init(){}
    
}

// MARK: - ASImageContainerProtocol
class KingfisherContainer: NSObject, ASImageContainerProtocol {
    
    var image: UIImage?
    
    init(url: URL) {
        super.init()
        self.image =  ImageCache.default.retrieveImageInMemoryCache(forKey: url.cacheKey)
    }

    func asdk_image() -> UIImage? {
        return image
    }
    
    func asdk_animatedImageData() -> Data? {
        return nil
    }
    
    
}
