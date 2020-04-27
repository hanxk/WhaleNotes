//
//  TodoCompleteHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import UIKit

class TodoCompleteHeaderView: UIView {
    
    private lazy var expandButton: UIButton = UIButton().then {
        $0.setTitle("展开清单项目", for: .normal)
        $0.setTitleColor(.thirdColor, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.addTarget(self, action: #selector(self.handleExpandButtonTapped), for: .touchUpInside)
    }
    
    var todoBlock: Block!  {
        didSet {
            expandButton.setTitle(String(format:"显示已完成的项目(%d)",todoBlock.todos.count), for: .normal)
        }
    }
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
        }
    }
    
    @objc private func handleExpandButtonTapped() {
        
    }
}
