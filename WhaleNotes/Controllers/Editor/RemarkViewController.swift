//
//  RemarkViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class RemarkViewController:UIViewController {
    
    var viewModel:CardEditorViewModel!
    let editor = MDEditorView(placeholder: "写点什么")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        self.view.addSubview(editor)
        self.editor.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        
        self.title =  "记笔记"
        self.editor.text = viewModel.blockInfo.remark
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消 ", style: .plain, target: self, action: #selector(cancelButtonTapped))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(doneButtonTapped))
    }
    
    @objc func doneButtonTapped() {
        viewModel.updateRemark(editor.text)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
