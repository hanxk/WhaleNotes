//
//  TodoCompleteHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class TodoCompleteHeaderView: UIView {
    
    private lazy var expandButton: UIButton = UIButton().then {
        $0.setTitleColor(.thirdColor, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.setTitle("安妮", for: .normal)
        $0.addTarget(self, action: #selector(self.handleExpandButtonTapped), for: .touchUpInside)
    }
    var notificationToken: NotificationToken?
    var isExpand = true
    var todoBlock: Block! {
        didSet {
            let todoResults = todoBlock.todos.filter("isChecked = true")
            let notificationToken = todoResults.observe { [weak self] (changes) in
                guard let self  = self else { return }
                let expandStr = self.isExpand ? "隐藏" : "显示"
                let title = String(format:"%@已完成的项目(%d)",arguments:[expandStr,todoResults.count])
                self.expandButton.setTitle(title, for: .normal)
            }
            self.notificationToken = notificationToken

        }
    }
    var expandStateChanged:((Bool)->Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    private func setup() {
        self.addSubview(expandButton)
        expandButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(EditorViewController.space)
//            make.trailing.equalToSuperview().offset(-EditorViewController.space)
        }
    }
    
    @objc private func handleExpandButtonTapped() {
        self.isExpand = !self.isExpand
        expandStateChanged?(self.isExpand)
    }
}
