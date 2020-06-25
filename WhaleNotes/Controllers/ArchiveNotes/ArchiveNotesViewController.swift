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
    
    var board:Board!
    var callbackNotesCountChanged:((Int64) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .bg
        self.setupBoardView(board: board)
    }
    
    func setupBoardView(board:Board) {
        let notesView = NotesView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height),board: board,noteStatus: NoteBlockStatus.archive)
        notesView.callbackNotesCountChanged = {
            self.callbackNotesCountChanged?($0)
        }
        self.view.addSubview(notesView)
        notesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if board.type == BoardType.user.rawValue {
//            titleButton.setTitle(board.title,emoji: board.icon)
            self.title = board.icon + board.title
        }
        
    }
}
