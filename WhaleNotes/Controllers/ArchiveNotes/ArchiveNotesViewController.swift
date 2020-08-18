//
//  ArchiveNotesViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import RxSwift
import JXPhotoBrowser

class ArchiveNotesViewController: UIViewController, UINavigationControllerDelegate {
    
    var board:BlockInfo!
    var callbackNotesCountChanged:((Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .bg
        self.setupBoardView(board: board)
    }
    
    func setupBoardView(board:BlockInfo) {
//        let notesView = NotesView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height),board: board,noteStatus: NoteBlockStatus.archive)
//        notesView.callbackNotesCountChanged = {
//            self.callbackNotesCountChanged?($0)
//        }
//        self.view.addSubview(notesView)
//        notesView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        self.title = "已归档的便签"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = .bg
    }
}
