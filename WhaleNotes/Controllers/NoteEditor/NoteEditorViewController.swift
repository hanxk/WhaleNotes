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
    
    static let space: CGFloat = 14
    static let cellSpace: CGFloat = 2
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    private var titleCell:TitleTableViewCell?
    private var contentCell: NoteContentViewCell?
    
    private var activeTextView: UITextView?
    
    private var note: Note!
    
    var createMode: CreateMode?
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        
        $0.delegate = self
        $0.dataSource = self
        $0.register(TitleTableViewCell.self, forCellReuseIdentifier: BlockType.title.rawValue)
        $0.register(NoteContentViewCell.self, forCellReuseIdentifier: BlockType.text.rawValue)
        $0.register(TODOItemCell.self, forCellReuseIdentifier: BlockType.todo.rawValue)
        $0.register(BlockImageCell.self, forCellReuseIdentifier:BlockType.image.rawValue)
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomExtraSpace, right: 0)
    }
    private lazy var bottombar: BottomBarView = BottomBarView().then {[weak self] in
        guard let self = self else { return }
        $0.moreButton.addTarget(self, action: #selector(self.handleMoreButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData()
        self.setupUI()
    }
    
    private func setupData() {
        guard let createMode = self.createMode else {
            return
        }
        self.createNewNote(createMode: createMode)
    }
    
    private func createNewNote(createMode: CreateMode) {
        let note: Note = Note()
        note.blocks.append(Block.newTitleBlock())
        switch createMode {
        case .text:
            note.blocks.append(Block.newTextBlock())
            break
        case .image:
            note.blocks.append(Block.newImageBlock())
            break
        case .todo:
            note.blocks.append(Block.newTodoBlock())
            break
        }
        DBManager.sharedInstance.addNote(note)
        self.note = note
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
    
    private var keyboardIsHide = true
    
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
    
    private func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        
        self.view.addSubview(bottombar)
        bottombar.snp.makeConstraints { (make) in
            make.height.equalTo(bottombarHeight)
            make.width.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalTo(0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentCell?.textView.becomeFirstResponder()
    }
    
    @objc func handleMoreButtonTapped() {
        self.activeTextView?.resignFirstResponder()
        titleCell?.textField.resignFirstResponder()
    }
}

extension NoteEditorViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return note.blocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = note.blocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: block.type, for: indexPath)
        switch block.blockType {
        case .title:
            let titleCell = cell as! TitleTableViewCell
            titleCell.enterkeyTapped { [weak self] _ in
                self?.contentCell?.textView.becomeFirstResponder()
            }
            self.titleCell = titleCell
            break
        case .text:
            let textCell = cell as! NoteContentViewCell
            textCell.textChanged {[weak tableView] newText in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
                let textView = textCell.textView
                self.activeTextView =  textView
                if let cursorPosition = textView.selectedTextRange?.start {
                    let caretPositionRect = textView.caretRect(for: cursorPosition)
                    textView.scrollRectToVisible(caretPositionRect, animated: false)
                    if caretPositionRect.origin.y < 0 { // 按回车键
                        tableView?.scrollToBottom()
                    }
                }
            }
            textCell.textShouldBeginChange =  { [weak self] textView in
                self?.activeTextView = textView
            }
            self.contentCell = textCell
            break
        case .todo:
            let todoCell = cell as! TODOItemCell
            todoCell.textChanged =  {[weak tableView] textView in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            todoCell.textShouldBeginChange =  { [weak self] textView in
                self?.activeTextView = textView
            }
            break
        case .image:
            //            let imageCell =  cell as! BlockImageCell
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let block = note.blocks[indexPath.row]
        if block.blockType == .image {
            
            let itemSize = (UIScreen.main.bounds.size.width - NoteEditorViewController.space*2 - NoteEditorViewController.cellSpace)/2
            return itemSize
        }
        return UITableView.automaticDimension
    }
    
}

enum CreateMode {
    case text
    case todo
    case image
}
