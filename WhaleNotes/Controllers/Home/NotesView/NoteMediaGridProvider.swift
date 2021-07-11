//
//  NoteMediaGridProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/10.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class NoteMediaGridProvider: NSObject, NoteCardContentProvider  {
    
    let cellSpacing:CGFloat = 4
    var cellCount:Int {
//        return self.noteFiles.count == 4 ? 2 : 3
        return 3
    }
    
    var gridItemW:CGFloat {
        return (UIScreen.main.bounds.size.width - MDEditorConfig.paddingH*2) / cellCount.cgFloat
    }
    var delegate:NoteMediaCellNodeDelegate? = nil
    var noteFiles:[NoteFile] = []
    var callbackImageTapped:((Int) -> Void)?
    
    lazy var collectionNode:ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = NoteMediaCellConstants.cellSpacing
        layout.minimumLineSpacing = NoteMediaCellConstants.cellSpacing
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)
        collectionNode.dataSource = self
        collectionNode.delegate = self
        return collectionNode
    }()
    
    init(noteFiles:[NoteFile]) {
        super.init()
        self.noteFiles = noteFiles
    }
    
    
    func attach(cell: ASCellNode)  {
        cell.addSubnode(self.collectionNode)
    }
    
    func element(constrainedSize: ASSizeRange) -> ASLayoutElement {
        
        self.collectionNode.style.minHeight = ASDimension(unit: .points, value: self.calcMediaCollectionHeight(constrainedSize:constrainedSize))
        return self.collectionNode
    }
    
    private func calcMediaCollectionHeight(constrainedSize: ASSizeRange) -> CGFloat {
        let noteFiles = self.noteFiles
        
        var rowCount = noteFiles.count / self.cellCount
        if noteFiles.count % Int(self.cellCount) > 0 {
            rowCount += 1
        }
        
        let itemWidth = (constrainedSize.max.width  - (self.cellCount.cgFloat - 1)*self.cellSpacing) / self.cellCount.cgFloat
        
        let cellHeight = itemWidth*CGFloat(rowCount) + (CGFloat(rowCount)-1) * self.cellSpacing
        return cellHeight
    }
}

extension NoteMediaGridProvider: ASCollectionDataSource {
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let noteFile = self.noteFiles[indexPath.row]
        return MediaItemCellNode(noteFile: noteFile,imageW: self.gridItemW)
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.noteFiles.count
    }
}

extension NoteMediaGridProvider: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        let itemWidth = (collectionNode.frame.width - (self.cellCount.cgFloat - 1)*cellSpacing) / self.cellCount.cgFloat
        return ASSizeRange(min: .zero, max: .init(width: itemWidth, height: itemWidth))
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        self.callbackImageTapped?(indexPath.row)
    }
}

fileprivate class MediaItemCellNode:ASCellNode {
    var noteFile:NoteFile!
    
    lazy var imageNode = ASDisplayNode(viewBlock: {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        return imageView
    })
    var imageW:CGFloat!
    
    init(noteFile:NoteFile,imageW:CGFloat) {
        super.init()
        self.noteFile = noteFile
        self.imageW = imageW
        self.addSubnode(imageNode)
        self.backgroundColor = .lightGray
        
        if let imageView = imageNode.view as? UIImageView {
            imageView.setLocalImage(fileURL: noteFile.localURL,imageW: imageW)
        }
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
        self.imageNode.style.minSize = constrainedSize.max
        return  ASInsetLayoutSpec(insets: insets, child: self.imageNode)
    }
    
}
