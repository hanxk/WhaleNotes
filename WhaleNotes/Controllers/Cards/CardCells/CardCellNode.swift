//
//  CardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit


protocol NoteCellNodeDelegate:AnyObject {
    func noteCellImageBlockTapped(imageView:ASImageNode,cardBlock:BlockInfo)
    func noteCellMenuTapped(sender:UIView,cardBlock:BlockInfo)
}

class CardCellNode: ASCellNode {


    weak var delegate:NoteCellNodeDelegate?

    var cellProvider:CellProvider!

    var cardBlock:BlockInfo!
    var board:BlockInfo!

    var cardbackground:ASDisplayNode!
    var callbackBoardButtonTapped:((BlockInfo,BlockInfo)->Void)?
    var boardButton:ASButtonNode?
    var itemSize:CGSize!
    
    
    var titleTextNote:ASTextNode?


    required init(cardBlock:BlockInfo,board:BlockInfo? = nil) {
        super.init()


        self.cardBlock = cardBlock
        self.board = board

        self.cellProvider = self.generateCellProvider(block: cardBlock)


        let cardbackground = ASDisplayNode().then {
            $0.backgroundColor = .white
            $0.borderWidth = 1
            $0.borderColor = UIColor.cardBorder.cgColor

//                $0.cornerRoundingType = .precomposited
            $0.cornerRadius = BoardViewConstants.cornerRadius
//                $0.cornerRadius = NoteCellConstants.cornerRadius
//                $0.clipsToBounds = true
            $0.style.flexShrink = 1
            
            $0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.03).cgColor
            $0.shadowOpacity = 1
            $0.shadowRadius = 8
            $0.shadowOffset = CGSize(width: 0, height: 0)
        }
        self.addSubnode(cardbackground)
        self.cardbackground = cardbackground

        self.cellProvider.attach(cell: self)


//        if let board = board,let properties = board.blockBoardProperties  {
//            let boardButton = ASButtonNode().then {
//                $0.style.height = ASDimensionMake(NoteCellConstants.boardHeight)
//                $0.style.width = ASDimensionMake(itemSize.width)
//                $0.contentHorizontalAlignment = .left
//                let horizontalPadding:CGFloat = 2
//                $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: horizontalPadding, bottom:0, right: horizontalPadding)
//
////                $0.setAttributedTitle(getBoardButtonAttributesText(text: properties.title), for: .normal)
////                $0.addTarget(self, action: #selector(boardButtonTapped), forControlEvents: .touchUpInside)
////                Logger.info("title:\(properties.title)   id:\(note.noteBlock.id)")
//            }
//            self.boardButton = boardButton
//            self.addSubnode(boardButton)
//        }
        
        if cardBlock.type != .note &&
            cardBlock.type != .todo && cardBlock.title.isNotEmpty {
            let titleTextNote = ASTextNode().then {
                $0.attributedText = getBoardButtonAttributesText(text: cardBlock.title)
                $0.maximumNumberOfLines = 2
            }
            self.addSubnode(titleTextNote)
            self.titleTextNote = titleTextNote
        }

    }

    private func generateCellProvider(block:BlockInfo) -> CellProvider {
        switch block.block.type {
        case .note:
            return NoteCellProvider(noteBlock: block)
        case .image:
            return ImageCellProvider(imageBlock: block)
        default:
            fatalError("Unexpected block type \(block.type.rawValue)")
        }
    }


    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let contentLayout =  cellProvider.layout(constrainedSize: constrainedSize)

        let contentLayoutSpec:ASLayoutSpec =  ASBackgroundLayoutSpec(child: contentLayout, background: cardbackground).then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
        
        let padding = BoardViewConstants.cellShadowSize
        let insets = UIEdgeInsets(top:padding, left: padding, bottom: padding, right: padding)

        if let titleTextNote = self.titleTextNote {
            let stackVLayout = ASStackLayoutSpec.vertical().then {
                $0.style.flexGrow = 1.0
                $0.style.flexShrink = 1.0
            }
            stackVLayout.spacing = 6
            stackVLayout.children =  [contentLayoutSpec,titleTextNote]
            return ASInsetLayoutSpec(insets: insets, child: stackVLayout)
        }
        return  ASInsetLayoutSpec(insets: insets, child: contentLayoutSpec)

    }

    @objc func boardButtonTapped() {
        if let board = self.board {
//            self.callbackBoardButtonTapped?(self.note,board)
        }
    }
}


extension CardCellNode {
    func getBoardButtonAttributesText(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor:  UIColor.init(hexString: "#666666"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
}
