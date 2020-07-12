//
//  TrashHeaderNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/21.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import AsyncDisplayKit

class TrashHeaderNode: ASCellNode {
    
//    private var board:Board!
    private var topPadding:CGFloat!

    private let titleNode = ASTextNode()
    
//    required init(board:Board,topPadding:CGFloat) {
//        super.init()
//        self.board = board
//        self.topPadding = topPadding
//        
//        let attributedText = NSAttributedString(string: board.icon+" "+board.title, attributes: [
//            .font: UIFont.systemFont(ofSize: 14,weight: .medium),
//            .foregroundColor: UIColor(hexString: "#444444").withAlphaComponent(0.8),
//            ])
//        titleNode.attributedText = attributedText
//        addSubnode(titleNode)
//    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let insets =  UIEdgeInsets.init(top: self.topPadding , left: 0, bottom: 12, right:  0)
        
        let stackLayout =  ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [titleNode])
        
        return ASInsetLayoutSpec(insets: insets, child: stackLayout)
    }
}
