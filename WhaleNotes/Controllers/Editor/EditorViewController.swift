//
//  NoteEditorViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit
import ContextMenu
import RealmSwift

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    static let cellSpace: CGFloat = 2
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    private var titleCell:TitleBlockCell?
    private var contentCell: TextBlockCell?
    private var todoBlockCell: TodoBlockCell?
    
    
    private var note: Note!
    
    var createMode: CreateMode?
    
    var sections:[SectionType] = []
    
    
    private var todoUnCheckedListNotifiToken: NotificationToken?
    private var todoCheckedListNotifiToken: NotificationToken?
    
    private var todosNotificationToken: NotificationToken?
    private var noteNotificationToken: NotificationToken?
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        
        $0.delegate = self
        $0.dataSource = self
        $0.register(TitleBlockCell.self, forCellReuseIdentifier: "title")
        $0.register(TextBlockCell.self, forCellReuseIdentifier:  "text")
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: "todo")
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomExtraSpace, right: 0)
    }
    
    private lazy var bottombar: BottomBarView = BottomBarView().then {[weak self] in
        guard let self = self else { return }
        $0.moreButton.addTarget(self, action: #selector(self.handleMoreButtonTapped), for: .touchUpInside)
        $0.addButton.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    private var keyboardIsHide = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
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
        self.setFirstResponder()
    }
    
    private func setFirstResponder() {
        guard let createMode = createMode else { return }
        if createMode == .text {
            contentCell?.textView.becomeFirstResponder()
            return
        }
        if createMode == .todo {
            self.todoBlockCell?.textView.becomeFirstResponder()
            return
        }
    }
    
    @objc func handleMoreButtonTapped() {
        self.tableView.endEditing(true)
    }
    
    
    @objc func handleAddButtonTapped() {
        let popMenuVC = PopBlocksViewController()
        //        popMenuVC.cellTapped = { [weak self] createMode in
        //
        //        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: bottombar.addButton
        )
    }
    
}

// 数据处理
extension EditorViewController {
    
    private func setupData() {
        guard let createMode = self.createMode else {
            return
        }
        let note = self.createNewNote(createMode: createMode)
        //        noteNotificationToken = note.observe { [weak self] change in
        //            switch change {
        //            case .change(let _):
        //                Logger.info("change")
        //            case .error(let error):
        //                print("An error occurred: \(error)")
        //            case .deleted:
        //                print("The object was deleted.")
        //            }
        //        }
        self.setupSectionsTypes(note: note)
        self.note = note
    }
    
    private func setupSectionsTypes(note: Note) {
        for block in note.blocks {
            switch block.blockType {
            case .title:
                self.sections.append(SectionType.title(title: block.title))
            case .text:
                self.sections.append(SectionType.text(text: block.text))
            case .todo:
                self.setupTodoSections(todoBlock: block)
            case .image:
                break
            }
        }
    }
    
    private func setupTodoSections(todoBlock: Block) {
        let section = self.sections.count
        self.todoUnCheckedListNotifiToken = observe2(todoBlock: todoBlock, isChecked: false,section:section)
        self.todoCheckedListNotifiToken = observe2(todoBlock: todoBlock, isChecked: true,section:section+1)
    }
    
    private func observe2(todoBlock: Block,  isChecked: Bool,section: Int) -> NotificationToken{
        let todoResults = todoBlock.todos.filter("isChecked = " + (isChecked  ? "true" : "false" ))
        self.sections.append(SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults),isChecked: isChecked))
        let notificationToken = todoResults.observe { [weak self] changes in
            guard let self = self else { return }
            let index = self.sections.firstIndex {
                switch $0 {
                case .todo(_, _, let isChecked2):
                    return isChecked == isChecked2
                default:
                    return false
                }
            }
            if index != nil {
               self.sections[index!] =  SectionType.todo(todoBlock: todoBlock, todos: Array(todoResults), isChecked: isChecked)
                self.handleTodoUpdate(changes: changes,section: section)
            }
            
        }
        return notificationToken
    }
    
    private func handleTodoUpdate(changes: RealmCollectionChange<Results<Todo>>,section: Int) {
        
        let tableView  = self.tableView
        switch changes {
        case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: let modIndices):
            print("Objects deleted from indices: \(deletionIndices)")
            print("Objects inserted to indices: \(insertionIndices)")
            print("Objects modified at indices: \(modIndices)")
            tableView.beginUpdates()
            tableView.deleteRows(at: deletionIndices.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            tableView.insertRows(at: insertionIndices.map({ IndexPath(row: $0, section: section) }),
                                 with: .automatic)
            //                             tableView.reloadRows(at: modIndices.map({ IndexPath(row: $0, section: section) }),
            //                                                  with: .automatic)
            
            tableView.endUpdates()
            if insertionIndices.count > 0 {
                let indices = insertionIndices[insertionIndices.count-1]
                let blockCell = self.tableView.cellForRow(at: IndexPath(row: indices, section: section)) as! TodoBlockCell
                blockCell.textView.becomeFirstResponder()
            }
        case .error(let error):
            print(error)
        case .initial(let type):
            tableView.reloadData()
            print(type)
        }
    }
    
    private func createNewNote(createMode: CreateMode) -> Note {
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
            note.blocks.append(Block.newTodoBlock(note: note))
            break
        }
        DBManager.sharedInstance.addNote(note)
        return note
    }
}

extension EditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo(_, let todos,_):
            return todos.count
        default:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: sectionObj.identifier, for: indexPath)
        switch sectionObj {
        case .title(let title):
            let titleCell = (cell as! TitleBlockCell).then {
                $0.textField.text = title
                $0.enterkeyTapped { [weak self] _ in
                    self?.contentCell?.textView.becomeFirstResponder()
                }
            }
            self.titleCell = titleCell
            break
        case .text(let text):
            let textCell = cell as! TextBlockCell
            textCell.textView.text = text
            textCell.textChanged {[weak tableView] newText in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
                let textView = textCell.textView
                if let cursorPosition = textView.selectedTextRange?.start {
                    let caretPositionRect = textView.caretRect(for: cursorPosition)
                    textView.scrollRectToVisible(caretPositionRect, animated: false)
                    if caretPositionRect.origin.y < 0 { // 按回车键
                        tableView?.scrollToBottom()
                    }
                }
            }
            self.contentCell = textCell
            break
        case .todo(let todoblock,let todos,_):
            let todoCell = cell as! TodoBlockCell
            self.setupTodoCell(todoCell: todoCell, todos: todos, todoBlock: todoblock, indexPath: indexPath)
            break
        }
        return cell
    }
    private func setupTodoCell(todoCell: TodoBlockCell,todos: [Todo],todoBlock: Block,indexPath: IndexPath) {
        let todo = todos[indexPath.row]
        todoCell.todo = todo
        todoCell.todoBlock = todoBlock
        todoCell.textChanged =  {[weak tableView] textView in
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    tableView?.beginUpdates()
                    tableView?.endUpdates()
                }
            }
        }
        self.todoBlockCell = todoCell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo(let todoBlock, _, let isChecked):
            if !isChecked {
                let todoHeaderView = TodoHeaderView()
                todoHeaderView.todoBlock = todoBlock
                return todoHeaderView
            }else {
                let todoCompleteHeaderView = TodoCompleteHeaderView()
                todoCompleteHeaderView.todoBlock = todoBlock
                return todoCompleteHeaderView
            }
        default:
            return nil
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //        let block = note.blocks[indexPath.section]
        //        if block.blockType == .image {
        //
        //            let itemSize = (UIScreen.main.bounds.size.width - EditorViewController.space*2 - EditorViewController.cellSpace)/2
        //            return itemSize
        //        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo(_, _,_):
            return 44
        default:
            return 0
        }
    }
}

// 键盘
extension EditorViewController {
    
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
}


enum SectionType {
    case title(title: String)
    case text(text: String)
    case todo(todoBlock: Block, todos: [Todo],isChecked: Bool)
    
    var identifier: String {
        switch self {
        case .title:
            return "title"
        case .text:
            return "text"
        case .todo:
            return "todo"
        }
    }
}


enum CreateMode {
    case text
    case todo
    case image
}
