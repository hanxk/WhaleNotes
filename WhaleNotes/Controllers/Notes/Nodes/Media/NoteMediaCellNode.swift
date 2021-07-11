//
//  NoteMediaCellNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Kingfisher
import DeepDiff

enum NoteMediaCellConstants {
    static let cellSpacing:CGFloat = 4
    static let cellCount:CGFloat = 3
}

protocol NoteMediaCellNodeDelegate: AnyObject {
    func imageChanged(_ cellNode:NoteMediaCellNode)
    func imageTapped(_ cellNode:NoteMediaCellNode,index:Int)
}
class NoteMediaCellNode:ASCellNode {
    
    
    var gridItemW:CGFloat {
        return (UIScreen.main.bounds.size.width - MDEditorConfig.paddingH*2) / NoteMediaCellConstants.cellCount
    }
    var delegate:NoteMediaCellNodeDelegate? = nil
    
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
    
    var noteFiles:[NoteFile] = []
    
    init(noteFiles:[NoteFile]) {
        super.init()
        self.noteFiles = noteFiles
        self.addSubnode(collectionNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let insets = UIEdgeInsets(top:0, left: MDEditorConfig.paddingH, bottom: 0, right: MDEditorConfig.paddingH)
        return  ASInsetLayoutSpec(insets: insets, child: self.collectionNode)
    }
    
    
    func reload(newNoteFiles:[NoteFile],callback:(()->Void)? = nil) {
        let changes = diff(old:self.noteFiles, new:newNoteFiles)
        self.noteFiles = newNoteFiles
        if changes.isEmpty { return }
        self.collectionNode.reload(changes: changes) { _ in
            callback?()
        }
    }
}

extension NoteMediaCellNode: ASCollectionDataSource {
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let noteFile = self.noteFiles[indexPath.row]
        return MediaItemCellNode(noteFile: noteFile,imageW: self.gridItemW)
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.noteFiles.count
    }
}

extension NoteMediaCellNode: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        let itemWidth = (collectionNode.frame.width - (NoteMediaCellConstants.cellCount - 1)*NoteMediaCellConstants.cellSpacing) / NoteMediaCellConstants.cellCount
        return ASSizeRange(min: .zero, max: .init(width: itemWidth, height: itemWidth))
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.imageTapped(self, index: indexPath.row)
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
