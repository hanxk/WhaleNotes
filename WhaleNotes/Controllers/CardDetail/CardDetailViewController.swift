//
//  CardDetailViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

protocol CardEditorView:Any {
    
}
class CardEditorViewController: UIViewController {
    var cardBlock:BlockInfo!
    
    override func loadView() {
        view = generateContentView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension CardEditorViewController {
    private func generateContentView() -> UIView {
        let noteView = NoteView()
        return noteView
    }
}
