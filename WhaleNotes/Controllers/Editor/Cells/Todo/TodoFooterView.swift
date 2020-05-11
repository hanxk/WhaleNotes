//
//  TodoFooterView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/4.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoFooterView: UIView {
    
    private lazy var addButton: UIButton = UIButton().then {
        $0.setTitle("添加清单项", for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
    
    var note:Note!
    var addButtonTapped:(() ->Void)?
    var todoGroupBlock:Block! {
        didSet {
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
        self.backgroundColor = .white
    }
    
    private func setup() {
        self.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(EditorViewController.space)
        }
        
    }
    @objc private func handleAddButtonTapped() {
        self.addButtonTapped?() // 防止还有未保存的 todo
        if note.todoBlocks.firstIndex(where: { $0.text.isEmpty && !$0.isChecked }) != nil {
            return
        }
        DBManager.sharedInstance.update { [weak self] in
            if let self = self {
                self.note.todoBlocks.insert(Block.newTodoBlock(),at: 0)
            }
        }
    }
}
