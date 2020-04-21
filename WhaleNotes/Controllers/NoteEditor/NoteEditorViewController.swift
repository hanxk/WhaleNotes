//
//  NoteEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class NoteEditorViewController: UIViewController {
    
    static let space = 14
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    private var noteBlocks: [NoteBlock] = []
    private var titleCell:TitleTableViewCell?
    private var contentCell: NoteContentViewCell?
    
    private var tableView = UITableView().then {
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 20
        $0.separatorStyle = .none
    }
    private var bottombar: BottomBarView = BottomBarView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteBlocks.append(NoteBlock(id: 1, type: .title, data: nil, sort: 1, noteId: 1))
        noteBlocks.append(NoteBlock(id: 2, type: .content, data: nil, sort: 2, noteId: 1))
        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    
    @objc func handleKeyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            let rect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]  as! NSValue).cgRectValue
            keyboardIsHide = false
            keyboardHeight = rect.height
            keyboardHeight2 += bottombarHeight
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            self.bottombar.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset( -(rect.height - view.safeAreaInsets.bottom))
            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
            
            var contentInset = self.tableView.contentInset
            contentInset.bottom = rect.height + bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
            
        }
    }
    
    var keyboardIsHide = true
    
    @objc func handleKeyboardHideNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            guard let view = self.view else{
                return
            }
            if keyboardIsHide {
                return
            }
            keyboardHeight = 0
            keyboardIsHide = true
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            self.bottombar.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(0)
            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
            var contentInset = self.tableView.contentInset
            contentInset.bottom = bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
        }
    }
    
    private func setup() {
        self.view.backgroundColor = .white
        self.setupTableView()
        self.setupBottomBar()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: CellType.title.rawValue)
        tableView.register(NoteContentViewCell.self, forCellReuseIdentifier: CellType.content.rawValue)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomExtraSpace, right: 0)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    private func setupBottomBar() {
        self.view.addSubview(bottombar)
        bottombar.snp.makeConstraints { (make) in
            make.height.equalTo(bottombarHeight)
            make.width.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalTo(0)
        }
        bottombar.moreButton.addTarget(self, action: #selector(handleMoreButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentCell?.textView.becomeFirstResponder()
    }
    
    @objc func handleMoreButtonTapped() {
        contentCell?.textView.resignFirstResponder()
    }
}

extension NoteEditorViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
                let textView = cell.textView
                if let cursorPosition = textView.selectedTextRange?.start {
                    let caretPositionRect = textView.caretRect(for: cursorPosition)
                    textView.scrollRectToVisible(caretPositionRect, animated: false)
                    if caretPositionRect.origin.y < 0 { // 按回车键
                        tableView?.scrollToBottom()
                    }
                }
            }
            self.contentCell = cell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
}

enum CellType: String {
    case title = "TitleTableViewCell"
    case content = "NoteContentViewCell"
}
