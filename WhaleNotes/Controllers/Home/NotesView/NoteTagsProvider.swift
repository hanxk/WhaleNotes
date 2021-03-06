//
//  NoteTagsProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

enum TagConfig   {
    static let insets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    
    static let spacingH:CGFloat = 6
    static let spacingV:CGFloat = 6
    
    static let tagButtonPaddingH:CGFloat = 8
    static let tagHeight:CGFloat = 22
    
    
    static let tagFont:UIFont = UIFont.systemFont(ofSize: 13)
    
}

class NoteTagsProvider: NSObject, NoteCardProvider {
    
    var cardActionEmit: ((NoteCardAction) -> Void)?
    var noteInfo:NoteInfo!
    var tags:[Tag] {
        return noteInfo.tags
    }
    var tagsSize:[CGFloat] = []
    
    
    
    private lazy var  layoutDelegate = FlowCollectionLayoutDelegate().then {
        $0.layoutInfo = FlowCollectionLayoutInfo(insets: TagConfig.insets, spacing: TagConfig.spacingH, itemHeight: TagConfig.tagHeight)
    }
    
    
    private lazy var tagsCollectionNode = ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
        guard let self = self else {return}
        $0.view.isScrollEnabled = false
        let _layoutInspector = layoutDelegate
        $0.dataSource = self
        $0.delegate = self
        $0.layoutInspector = _layoutInspector
    }
    
    init(noteInfo:NoteInfo,tagsSize:[CGFloat]) {
        self.noteInfo = noteInfo
        self.tagsSize = tagsSize
    }
}

extension NoteTagsProvider {
    
    func attach(cell: ASCellNode) {
        cell.addSubnode(tagsCollectionNode)
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        tagsCollectionNode.style.preferredSize = CGSize(width: constrainedSize.max.width, height: calcHeight(constrainedSize: constrainedSize))
        let vLayout =  ASStackLayoutSpec.vertical().then {
            $0.direction = .vertical
        }
        vLayout.children = [tagsCollectionNode]
        return  vLayout
    }
    
    func calcHeight(constrainedSize: ASSizeRange) -> CGFloat {
        
        if self.tagsSize.count  ==  0  {  return 0}
        
        let insets = TagConfig.insets
        let rowValidWidth = constrainedSize.max.width  - insets.left - insets.right
        
        var  tagsHeight:CGFloat = TagConfig.tagHeight
        
        var rowWidth:CGFloat = 0
        for tagTitleWith in self.tagsSize {
            
            let tw = tagTitleWith > rowValidWidth   ?  rowValidWidth - TagConfig.tagButtonPaddingH*2 : tagTitleWith
            
            var tagNeedWidth = tw + TagConfig.tagButtonPaddingH
            if  rowWidth != 0  {
                tagNeedWidth  += TagConfig.spacingH
            }
            let rowRemainWidth = rowValidWidth - rowWidth
            
            if tagNeedWidth > rowRemainWidth {
                rowWidth =  0
                tagsHeight = tagsHeight + TagConfig.spacingV  +  TagConfig.tagHeight
            }else {
                rowWidth += tagNeedWidth
            }
        }
        
        return insets.top + tagsHeight + insets.bottom
    }
}


extension NoteTagsProvider: ASCollectionDelegate {
    
}

extension NoteTagsProvider: ASCollectionDataSource {
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let tag = self.tags[indexPath.row]
        return {
            let node =  TagCellNode(tag: tag)
            return node
        }
    }
}



class TagCellNode: ASCellNode  {
    
    var tag:Tag!
    
    private lazy var tagButtonNode :ASButtonNode  = ASButtonNode().then {
        $0.backgroundColor = UIColor(r: 206, g: 205, b: 202, a: 0.5)
        $0.cornerRadius = TagConfig.tagHeight/2
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        $0.style.height = ASDimensionMakeWithPoints(TagConfig.tagHeight)
        $0.clipsToBounds  = true
    }
    
    init(tag:Tag) {
        super.init()
        self.tag = tag
        var title = tag.title  //"22/636:7:76373727727272662626626266272772727627266262"
        tagButtonNode.setAttributedTitle(NSMutableAttributedString(string: title, attributes: getTagTitleAttributes()), for: .normal)
        self.addSubnode(tagButtonNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let footerLayout = ASStackLayoutSpec.horizontal().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
//        tagButtonNode.style.width =  ASDimensionMakeWithPoints(constrainedSize.max.width)
//        tagButtonNode.style.maxWidth =  ASDimensionMakeWithPoints(constrainedSize.max.width)
        footerLayout.child  = tagButtonNode
        return  footerLayout
    }
    
    func getTagTitleAttributes() -> [NSAttributedString.Key: Any] {
        let font =  TagConfig.tagFont
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingMiddle;
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor:UIColor(hexString: "#37352f")
        ]
        return attributes
    }
    
}
