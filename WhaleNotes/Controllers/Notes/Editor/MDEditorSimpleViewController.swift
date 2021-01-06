//
//  MDEditorSimpleView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/28.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class MDEditorSimpleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textView = MDTextView(frame: .zero)
        self.view.addSubview(textView)
        textView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
    }
}
