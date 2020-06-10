//
//  MessageAlertViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/9.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


class MessageAlertViewController: BaseAlertViewController {
    
    var msg:String = "" {
        didSet {
            msgLabel.text = msg
        }
    }
    
    override var alertHeight: CGFloat {
        return 120
    }
    
    var callbackPositive:(()->Void)?
    
    private lazy var msgLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .primaryText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.addSubview(msgLabel)
        msgLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    override func positiveBtnTapped() {
        super.positiveBtnTapped()
        callbackPositive?()
    }
}
