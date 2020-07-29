//
//  NoteCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit


protocol NoteCellNodeDelegate:AnyObject {
    func noteCellImageBlockTapped(imageView:ASImageNode,note:Note)
    func noteCellMenuTapped(sender:UIView,note:Note)
}


class NoteCellNode: ASCellNode {
    
    
    weak var delegate:NoteCellNodeDelegate?
    
    var cellProvider:CellProvider!
    
    var note:NoteInfo!
    var board:BlockInfo!
    var noteProperties:BlockNoteProperty {
        get {
            return note.noteBlock.blockNoteProperties!
        }
    }
    
    
    var cardbackground:ASDisplayNode? = nil
    var callbackBoardButtonTapped:((NoteInfo,BlockInfo)->Void)?
    var boardButton:ASButtonNode?
    var itemSize:CGSize!
    
    
    required init(note:NoteInfo,itemSize: CGSize,board:BlockInfo? = nil) {
        super.init()
        
        self.itemSize = itemSize
        
        self.note = note
        self.board = board
        
        self.cellProvider = self.generateCellProvider(noteInfo: note)
        
        
        if self.cellProvider is NoteCellProvider {
            let cardbackground = ASDisplayNode().then {
                $0.backgroundColor = noteProperties.background
                $0.borderWidth = 1
                $0.borderColor = UIColor.cardBorder.cgColor
                $0.cornerRadius = NoteCellConstants.cornerRadius
                $0.clipsToBounds = true
                $0.style.flexShrink = 1
            }
            self.addSubnode(cardbackground)
            self.cardbackground = cardbackground
        }
        
        self.cellProvider.attach(cell: self,contentSize: itemSize)
        
        
        if let board = board,let properties = board.blockBoardProperties  {
            let boardButton = ASButtonNode().then {
                $0.style.height = ASDimensionMake(NoteCellConstants.boardHeight)
                $0.style.width = ASDimensionMake(itemSize.width)
                $0.contentHorizontalAlignment = .left
                let horizontalPadding:CGFloat = 2
                $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: horizontalPadding, bottom:0, right: horizontalPadding)
                
                $0.setAttributedTitle(getBoardButtonAttributesText(text: properties.title), for: .normal)
                $0.addTarget(self, action: #selector(boardButtonTapped), forControlEvents: .touchUpInside)
                Logger.info("title:\(properties.title)   id:\(note.noteBlock.id)")
            }
            self.boardButton = boardButton
            self.addSubnode(boardButton)
        }
        
    }
    
    private func generateCellProvider(noteInfo:NoteInfo) -> CellProvider {
        
        let isTitleExists = note.properties.title.isNotEmpty
        let isTextExists =  note.textBlock?.blockTextProperties?.title.isNotEmpty ?? false
        let isTodoExists = note.todoGroupBlock?.contentBlocks.isNotEmpty ?? false
        let isAttachExists = note.attachmentGroupBlock?.contentBlocks.isNotEmpty ?? false
        
        if !isTitleExists && !isTextExists && !isTodoExists && isAttachExists { //附件
            let imageBlock = note.attachmentGroupBlock!.contentBlocks[0]
            return ImageCellProvider(noteInfo: noteInfo, imageBlock: imageBlock)
        }
        
        
        return NoteCellProvider(noteInfo: noteInfo)
    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let contentSize = CGSize(width: itemSize.width, height: itemSize.height)
        let contentSizeRange = ASSizeRange(min: contentSize, max: contentSize)
        
        // content
        let contentLayout =  cellProvider.layout(constrainedSize: contentSizeRange)
        
        let contentLayoutSpec:ASLayoutSpec!
        if let cardbackground = self.cardbackground {
            contentLayoutSpec =  ASBackgroundLayoutSpec(child: contentLayout, background: cardbackground).then {
                $0.style.flexGrow = 1.0
                $0.style.flexShrink = 1.0
            }
        }else {// 图片卡不需要背景
            contentLayoutSpec = contentLayout
            contentLayoutSpec.style.flexShrink = 1.0
            contentLayoutSpec.style.flexGrow = 1.0
        }
        
        
        if let boardButton = self.boardButton {
            let stackVLayout = ASStackLayoutSpec.vertical().then {
                $0.style.flexGrow = 1.0
                $0.style.flexShrink = 1.0
            }
            stackVLayout.children =  [contentLayoutSpec,boardButton]
            return stackVLayout
        }
        return contentLayoutSpec
        
    }
    
    @objc func boardButtonTapped() {
        if let board = self.board {
            self.callbackBoardButtonTapped?(self.note,board)
        }
    }
}


extension NoteCellNode {
    func getBoardButtonAttributesText(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor:  UIColor.init(hexString: "#666666"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
}
