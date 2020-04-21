//
//  NoteEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class NoteEditorViewController: UITableViewController {
    
    static let space = 14
    var noteBlocks: [NoteBlock] = []
    var titleCell:TitleTableViewCell?
    var contentCell: NoteContentViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteBlocks.append(NoteBlock(id: 1, type: .title, data: nil, sort: 1, noteId: 1))
        noteBlocks.append(NoteBlock(id: 2, type: .content, data: nil, sort: 2, noteId: 1))
        self.setup()
    }
    
    private func setup() {
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: CellType.title.rawValue)
        tableView.register(NoteContentViewCell.self, forCellReuseIdentifier: CellType.content.rawValue)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 20
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentCell?.textView.becomeFirstResponder()
    }
}

extension NoteEditorViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteBlocks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let noteBlock = noteBlocks[indexPath.row]
        switch noteBlock.type {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellType.title.rawValue, for: indexPath) as! TitleTableViewCell
            cell.enterkeyTapped { [weak self] _ in
                self?.contentCell?.textView.becomeFirstResponder()
            }
            self.titleCell = cell
            return cell
        case .content:
            let cell =  (tableView.dequeueReusableCell(withIdentifier: CellType.content.rawValue, for: indexPath) as! NoteContentViewCell)
            cell.textChanged {[weak tableView] newText in
                cell.textView.text = newText
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            self.contentCell = cell
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

enum CellType: String {
    case title = "TitleTableViewCell"
    case content = "NoteContentViewCell"
}
