//
//  NoteView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class NoteView: BaseCardEditorView {
    
    private var noteBlock:BlockInfo!
    private var properties:BlockNoteProperty {
        get { return noteBlock.noteProperties! }
        set { noteBlock.noteProperties = newValue }
    }
    private var viewModel:CardEditorViewModel!
    
    let textView = NoteEditorView(placeholder: "写点什么。。。")
    
    init(viewModel:CardEditorViewModel) {
        super.init(frame: .zero)
        self.viewModel = viewModel
        self.noteBlock = viewModel.blockInfo
        self.initializeUI()
        
        textView.text = properties.text
        textView.textEndEditing = { [weak self] text in
            guard let self = self else { return }
            if self.properties.text != text {
                self.properties.text = text
              self.updateBlock()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        addSubview(textView)
        textView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
    }
}

extension NoteView {
    func updateBlock() {
        self.viewModel.update(block:self.noteBlock.block)
    }
}
