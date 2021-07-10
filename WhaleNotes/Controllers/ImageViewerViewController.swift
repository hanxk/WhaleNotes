//
//  ImageViewerViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/10.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import ImageViewer

//class ImageViewerViewController: UIViewController {
//    var imageUrls:[URL] = []
//    var itemMap:[String:GalleryItem] = [:]
//    var dd:GalleryItemsDataSource!
//
//
//
//}
//
//
//extension ImageViewerViewController: GalleryItemsDataSource {
//
//    func itemCount() -> Int {
//        return imageUrls.count
//    }
//
//    func provideGalleryItem(_ index: Int) -> GalleryItem {
//        let url = self.imageUrls[index]
//        if let item = itemMap[url.absoluteString] {
//            return item
//        }
//        let item = GalleryItem.image { callback in
//            ImageDownloader.shared.downloadImage(with:url, imageW: 0) { image in
//                callback(image)
//            }
//        }
//        return item
//    }
//
//}
//
//extension ImageViewerViewController: GalleryItemsDelegate {
//
//    func removeGalleryItem(at index: Int) {
//
//        print("remove item at \(index)")
//
////        let imageView = items[index].imageView
////        imageView.removeFromSuperview()
////        items.remove(at: index)
//    }
//}

class ImageViewerUtil {
    static func present(vc:UIViewController,imageUrls:[URL],startIndex:Int = 0) {
        let dataSource = ImageViewerDataSource(imageUrls: imageUrls)
        let configs:[GalleryConfigurationItem] = [
            .deleteButtonMode(.none),
            .seeAllCloseButtonMode(.none),
            .thumbnailsButtonMode(.none),
            .pagingMode(.standard),
            .swipeToDismissMode(.vertical),
            .presentationStyle(.displacement),
            .overlayBlurStyle(.dark)
        ]
        vc.presentImageGallery(GalleryViewController(startIndex: startIndex,itemsDataSource: dataSource,configuration: configs))
    }
}


class ImageViewerDataSource {
    
//    private var imageUrls:[URL] = []
    private var items:[GalleryItem] = []
//    private var itemMap:[String:GalleryItem] = [:]
    
    init(imageUrls:[URL]) {
//        self.imageUrls = imageUrls
        self.items = imageUrls.map { imageUrl in
            GalleryItem.image { callback in
               ImageDownloader.shared.downloadImage(with:imageUrl, imageW: 0) { image in
                   callback(image)
               }
           }
        }
    }
    
    //extension ImageViewerViewController: GalleryItemsDataSource {
    //
    //    func itemCount() -> Int {
    //        return imageUrls.count
    //    }
    //
    //    func provideGalleryItem(_ index: Int) -> GalleryItem {
    //        let url = self.imageUrls[index]
    //        if let item = itemMap[url.absoluteString] {
    //            return item
    //        }
    //        let item = GalleryItem.image { callback in
    //            ImageDownloader.shared.downloadImage(with:url, imageW: 0) { image in
    //                callback(image)
    //            }
    //        }
    //        return item
    //    }
    //
    //}
    //
    //extension ImageViewerViewController: GalleryItemsDelegate {
    //
    //    func removeGalleryItem(at index: Int) {
    //
    //        print("remove item at \(index)")
    //
    ////        let imageView = items[index].imageView
    ////        imageView.removeFromSuperview()
    ////        items.remove(at: index)
    //    }
    //}
}


    extension ImageViewerDataSource: GalleryItemsDataSource {
    
        func itemCount() -> Int {
            return items.count
        }
    
        func provideGalleryItem(_ index: Int) -> GalleryItem {
//            let url = self.imageUrls[index]
//            if let item = itemMap[url.absoluteString] {
//                return item
//            }
//            let item = GalleryItem.image { callback in
//                ImageDownloader.shared.downloadImage(with:url, imageW: 0) { image in
//                    callback(image)
//                }
//            }
            return self.items[index]
        }
    
    }
    
    extension ImageViewerDataSource: GalleryItemsDelegate {
    
        func removeGalleryItem(at index: Int) {
    
            print("remove item at \(index)")
    
    //        let imageView = items[index].imageView
    //        imageView.removeFromSuperview()
    //        items.remove(at: index)
        }
    }
