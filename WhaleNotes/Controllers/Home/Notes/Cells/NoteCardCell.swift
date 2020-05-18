//
//  NoteCardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit


class NoteCardCell: UICollectionViewCell {
    
    enum CardUIConstants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 8
        static let verticalSpace: CGFloat = 8
    }
    
    private(set) lazy var titleLabel =  UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15)
//        $0.backgroundColor = .red
    }
    
    private(set) lazy var textLabel =  UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15)
        $0.attributedText = NoteCardCell.getTextLabelAttributes(text: "")
        $0.lineBreakMode = .byWordWrapping
        $0.numberOfLines = 0
    }
    
    var note:NoteClone! {
        didSet {
            self.setupUI()
        }
    }
    
    private func setupUI() {
//        if let titleBlock = note.titleBlock {
//            self.contentView.addSubview(titleLabel)
//            titleLabel.snp.makeConstraints { make in
//                make.leading.equalToSuperview().offset(CardUIConstants.horizontalPadding)
//                make.trailing.equalToSuperview().offset(-CardUIConstants.horizontalPadding)
//                make.top.equalToSuperview().offset(CardUIConstants.verticalPadding)
//            }
//            titleLabel.text = titleBlock.text
//        }
//        if let textBlock = note.textBlock {
//            self.contentView.addSubview(textLabel)
//            textLabel.snp.makeConstraints { make in
//                make.leading.equalToSuperview().offset(CardUIConstants.horizontalPadding)
//                make.trailing.equalToSuperview().offset(-CardUIConstants.horizontalPadding)
//                make.top.equalTo(titleLabel.snp.bottom).offset(CardUIConstants.verticalPadding)
//            }
//            textLabel.text = textBlock.text
//        }
//        
//        self.contentView.backgroundColor = .white
//        _ = self.contentView.layer.then {
//            $0.cornerRadius = 6
//            $0.borderWidth = 1
//            $0.borderColor = UIColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1).cgColor
//        }
    }
    
    static func calculateHeight(cardWidth: CGFloat,note: NoteClone) -> CGFloat {
        let contentWidth = cardWidth - CardUIConstants.horizontalPadding*2
        var height:CGFloat = 0
        height +=  note.title.height(withWidth: contentWidth, font: UIFont.systemFont(ofSize: 15))
   
        
        let attrStr  = getTextLabelAttributes(text: note.text)
        height += CardUIConstants.verticalSpace
             height += attrStr.height(withConstrainedWidth: cardWidth)
        height += CardUIConstants.verticalPadding*2
        return height
    }
    
    static func calculateCellHeight(width:CGFloat,label:UILabel) -> CGFloat {
        let height = label.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        return height
    }
    
    
    static func getTextLabelAttributes(text: String) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.lineHeightMultiple = 0.7
        let attrString = NSMutableAttributedString()
        attrString.append(NSMutableAttributedString(string:text))
        attrString.addAttribute(NSAttributedString.Key.font, value:font, range: NSMakeRange(0, attrString.length))
        return attrString
    }
    
    func setLineHeight(lbl:UILabel,lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.lineHeightMultiple = lineHeight
        paragraphStyle.alignment = lbl.textAlignment
        
        let attrString = NSMutableAttributedString()
        if (lbl.attributedText != nil) {
            attrString.append( lbl.attributedText!)
        } else {
        }
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        lbl.attributedText = attrString
    }
}
