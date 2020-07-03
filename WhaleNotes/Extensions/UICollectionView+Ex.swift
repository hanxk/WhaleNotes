//
//  UICollectionView+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

extension UICollectionView {

    func setEmptyMessage(_ message: String,y:CGFloat = 0) {
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        let messageLabel = UILabel().then {
            $0.text = message
            $0.textColor = UIColor(hexString: "#999999")
            $0.numberOfLines = 0;
            $0.textAlignment = .center;
            $0.font = UIFont.systemFont(ofSize: 16)
        }
        
        emptyView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            if y > 0 {
                $0.top.equalToSuperview().offset(y)
            }else {
                $0.centerY.equalToSuperview()
            }
        }
        self.backgroundView = emptyView
    }

    func clearEmptyMessage() {
        self.backgroundView = nil
    }
}

extension ASCollectionNode {
    func setEmptyMessage(_ message: String,y:CGFloat = 0) {
        self.view.setEmptyMessage(message,y: y)
    }
    func clearEmptyMessage() {
        self.view.clearEmptyMessage()
    }
}
