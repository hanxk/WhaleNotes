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
import MobileCoreServices
import TLPhotoPicker
import RxSwift
import MBProgressHUD
import DeepDiff

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    static let cellSpace: CGFloat = 2
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    private var titleCell:TitleBlockCell?
    private var contentCell: TextBlockCell?
    private var todoBlockCell: TodoBlockCell?
    
    
    private var attachmentsCell: AttachmentsBlockCell?
    
    
    var createMode: CreateMode?
    
    private var note: Note! {
        didSet {
            self.setupSectionsTypes(note: note)
            self.tableView.reloadData()
        }
    }
    // todoindex:(checkoruncheckindex:sectionindex)
    var todoRowIndexMap:[Int:(Int,Int)] = [:]
    
    var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private var todoBlocksNotifiToken: NotificationToken?
    
    private var noteNotificationToken: NotificationToken?
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TitleBlockCell.self, forCellReuseIdentifier: "title")
        $0.register(TextBlockCell.self, forCellReuseIdentifier:  "text")
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: "todo")
        $0.register(AttachmentsBlockCell.self, forCellReuseIdentifier: "image")
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomExtraSpace, right: 0)
        
        
        $0.delegate = self
        $0.dataSource = self
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        $0.dropDelegate = self
        
    }
    
    private lazy var bottombar: BottomBarView = BottomBarView().then {[weak self] in
        guard let self = self else { return }
        $0.moreButton.addTarget(self, action: #selector(self.handleMoreButtonTapped), for: .touchUpInside)
        $0.addButton.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
    }
    
    
    deinit {
        noteNotificationToken?.invalidate()
        todoBlocksNotifiToken?.invalidate()
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
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    @objc func rotated() {
        self.attachmentsCell?.collectionView.reloadData()
        self.attachmentsCell?.collectionView.collectionViewLayout.invalidateLayout()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        tableView.endEditing(true)
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
        switch createMode {
        case .text: 
            contentCell?.textView.becomeFirstResponder()
        case .todo:
            break
            self.todoBlockCell?.textView.becomeFirstResponder()
        default:
            break
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
    
    
    
    func generateNote(createMode: CreateMode) -> Note {
        let note: Note = Note()
        note.titleBlock = Block.newTitleBlock()
        switch createMode {
        case .text:
            note.textBlock = Block.newTextBlock()
            break
        case .todo:
            note.isTodoExists = true
            note.todoBlocks.append(Block.newTodoBlock())
            break
        case .attachment(let blocks):
            note.attachBlocks.append(objectsIn: blocks)
            break
        }
        return note
    }
    
    private func setupData() {
        guard let createMode = self.createMode else {
            return
        }
        var workScheduler: ImmediateSchedulerType = MainScheduler.instance
        if case .attachment = createMode {  // 耗时任务在子线程中
            workScheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)
            self.showHud()
        }
        Observable<CreateMode>.just(createMode)
            .observeOn(workScheduler)
            .map({(createMode)  -> Note in
                return self.generateNote(createMode: createMode)
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                if let note = $0.element {
                    DBManager.sharedInstance.addNote(note)
                    self.note = note
                }
                self.hideHUD()
        }
        .disposed(by: disposeBag)
        
    }
    
    private func setupSectionsTypes(note: Note) {
        if let titleBlock = note.titleBlock {
            self.sections.append(SectionType.title(titleBlock: titleBlock))
        }
        if let textBlock = note.textBlock {
            self.sections.append(SectionType.text(textBlock: textBlock))
        }
        if note.isTodoExists {
            self.setupTodoSections2(todoBlocks: note.todoBlocks)
        }
    }
    
}

// 数据处理-todo
extension EditorViewController {
    

    func getRightUnCheckedSectionIndex() -> Int {
        var index = 0
        self.sections.forEach {
            switch $0 {
            case .title:
                index += 1
                break
            case .text:
                index += 1
                break
            default:
                break
            }
        }
        return index
    }
    
    private func getTodoSectionIndex(todoMode: TodoMode) -> Int  {
        return  self.sections.firstIndex {
            switch $0 {
            case .todo(_, let mode):
                return mode == todoMode
            default:
                return false
            }
        } ?? -1
    }
    
    private func getUncheckedAndCheckedTodos(todoBlocks: List<Block>,unCheckedSectionIndex:Int,checkedSectionIndex:Int) -> ([Block],[Block]) {

        var unCheckedBlocks:[Block] = []
        var checkedBlocks:[Block] = []
        
        self.todoRowIndexMap.removeAll()
        
        for (index, block) in Array(todoBlocks).enumerated() {
            if block.isChecked {
                self.todoRowIndexMap[index] = (checkedBlocks.count,checkedSectionIndex)
                checkedBlocks.append(block)
            }else {
                self.todoRowIndexMap[index] = (unCheckedBlocks.count,unCheckedSectionIndex)
                unCheckedBlocks.append(block)
            }
        }
        return (unCheckedBlocks,checkedBlocks)
    }
    
    private func setupTodoSections2(todoBlocks: List<Block>) {
        let notificationToken = todoBlocks.observe { [weak self] changes in
            guard let self = self else { return }
            let tableView = self.tableView
            
            var unCheckedSectionIndex =  self.getTodoSectionIndex(todoMode: .unchecked)
            var checkedSectionIndex = unCheckedSectionIndex + 1
            
            let unChckedSection: SectionType
            let chckedSection: SectionType
            if unCheckedSectionIndex < 0 {
                
                unCheckedSectionIndex  = self.getRightUnCheckedSectionIndex()
                checkedSectionIndex = unCheckedSectionIndex + 1
                
                let uncheckedAndCheckedTodos = self.getUncheckedAndCheckedTodos(todoBlocks: todoBlocks, unCheckedSectionIndex: unCheckedSectionIndex, checkedSectionIndex: checkedSectionIndex)
                let unCheckedBlocks = uncheckedAndCheckedTodos.0
                let checkedBlocks = uncheckedAndCheckedTodos.1
                
                unChckedSection = SectionType.todo(todoBlocks: unCheckedBlocks, mode: .unchecked)
                chckedSection = SectionType.todo(todoBlocks: checkedBlocks, mode: .checked)
                self.sections.insert(unChckedSection, at: unCheckedSectionIndex)
                self.sections.insert(chckedSection, at: checkedSectionIndex)
                
                tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    // your code here
                    self?.tryGetFocus(unCheckedSectionIndex: unCheckedSectionIndex)
                }
                
            }else {
                
                let oldTodoRowIndexMap = self.todoRowIndexMap
                
                let uncheckedAndCheckedTodos = self.getUncheckedAndCheckedTodos(todoBlocks: todoBlocks, unCheckedSectionIndex: unCheckedSectionIndex, checkedSectionIndex: checkedSectionIndex)
                
                // 新的 todos
                let unCheckedBlocks = uncheckedAndCheckedTodos.0
                let checkedBlocks = uncheckedAndCheckedTodos.1
                
                // 更新数据源
                self.sections[unCheckedSectionIndex] =  SectionType.todo(todoBlocks: unCheckedBlocks, mode: .unchecked)
                self.sections[checkedSectionIndex] =  SectionType.todo(todoBlocks: checkedBlocks, mode: .checked)
                
                switch changes {
                case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: let modIndices):
                    tableView.beginUpdates()
                    // 删除
                    let deleteRowsIndex: [IndexPath] = deletionIndices.map {
                        let todoInfo = oldTodoRowIndexMap[$0]!
                        return IndexPath(row: todoInfo.0, section: todoInfo.1)
                    }
                    tableView.deleteRows(at: deleteRowsIndex, with: .automatic)
                    
                    // 新增
                    let insertRowsIndex: [IndexPath] = insertionIndices.map {
                        let todoInfo = self.todoRowIndexMap[$0]!
                        return IndexPath(row: todoInfo.0, section: todoInfo.1)
                    }
                    tableView.insertRows(at: insertRowsIndex, with: .automatic)
                    
                    
                    if modIndices.count > 0 { // 有可能是删除了,section 发生改变

                        var deleteIndexPaths:[IndexPath] = []
                        var insertIndexPaths:[IndexPath] = []
                        var modifyIndexPaths:[IndexPath] = []
                        modIndices.forEach {
                            let todoInfo = self.todoRowIndexMap[$0]!
                            let oldTodoInfo = oldTodoRowIndexMap[$0]!
                            
                            if oldTodoInfo.1 != todoInfo.1 { // check 状态发生改变
                                let sectionIndex = todoInfo.1
                                if case .todo(_,let mode) = self.sections[sectionIndex] {
                                    if mode == .unchecked || (mode == .checked && self.isTodoExpand) {
                                        insertIndexPaths.append(IndexPath(row: todoInfo.0, section: todoInfo.1))
                                    }
                                }
                                deleteIndexPaths.append(IndexPath(row: oldTodoInfo.0, section: oldTodoInfo.1))
                            }else {
                                modifyIndexPaths.append(IndexPath(row: todoInfo.0, section: todoInfo.1))
                            }
                            
                        }
                        tableView.deleteRows(at: deleteIndexPaths, with: .automatic)
                        tableView.insertRows(at: insertIndexPaths, with: .automatic)
                        tableView.reloadRows(at: modifyIndexPaths, with: .automatic)
                    }
                    
                    tableView.endUpdates()
                    self.tryGetFocus(unCheckedSectionIndex: unCheckedSectionIndex)
                    break
                case .error(let error):
                    print(error)
                case .initial(let type):
                    print(type)
                }
                
            }
        }
        self.todoBlocksNotifiToken = notificationToken
    }
    
    private func tryGetFocus(unCheckedSectionIndex: Int) {
        if let  emptyBlockIndex = self.sections[unCheckedSectionIndex].getTodos(todoMode: .unchecked).firstIndex(where: { $0.text.isEmpty }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: emptyBlockIndex, section: unCheckedSectionIndex)) as? TodoBlockCell {
                cell.textView.becomeFirstResponder()
            }
        }
    }
    
    private func insertSectionReload(sectionIndex: Int) {
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .bottom)
        }, completion: nil)
    }
    
    private func deleteSectionReload(sectionIndex: Int) {
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .top)
        }, completion: nil)
    }
    
}

extension EditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo(let todoBlocks, let mode):
            switch mode {
            case .unchecked:
                return todoBlocks.count
            case .checked:
                return self.isTodoExpand ? todoBlocks.count : 0
            }
            
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
        case .title(let titleBlock):
            let titleCell = (cell as! TitleBlockCell).then {
                $0.titleBlock = titleBlock
                $0.enterkeyTapped { [weak self] _ in
                    self?.contentCell?.textView.becomeFirstResponder()
                }
            }
            self.titleCell = titleCell
            break
        case .text(let textBlock):
            let textCell = cell as! TextBlockCell
            textCell.textBlock = textBlock
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
        case .todo(let todoBlocks, _):
            let todoCell = cell as! TodoBlockCell
            todoCell.note = self.note
            todoCell.todoBlock = todoBlocks[indexPath.row]
            todoCell.textChanged =  {[weak tableView] textView in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            todoCell.textShouldBeginChange = {[weak self] in
                self?.todoBlockCell = todoCell
            }
            todoCell.textViewShouldEndEditing = {[weak self] in
                self?.todoBlockCell = nil
            }
            break
        case .attachments(let attachmentBlocks):
            let imagesCell = cell as! AttachmentsBlockCell
//            imagesCell.imageBlock = imageBlock
            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
   
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo(_, let mode):
            switch mode {
            case .unchecked:
                let todoHeaderView = TodoHeaderView()
                todoHeaderView.note = self.note
                todoHeaderView.addButtonTapped = {
                    if let todoBlockCell = self.todoBlockCell,!todoBlockCell.isEmpty {
                        todoBlockCell.textView.endEditing(true)
                    }
                }
                return todoHeaderView
            case .checked:
                let todoCompleteHeaderView = TodoCompleteHeaderView()
                todoCompleteHeaderView.isExpand = self.isTodoExpand
                todoCompleteHeaderView.note = self.note
                todoCompleteHeaderView.expandStateChanged = {[weak self] isExpand in
                    // 刷新 complete section
                    guard let self = self else { return }
                    let sectionIndex = self.sections.firstIndex { sectionType -> Bool in
                        switch sectionType {
                        case .todo(_, let mode):
                            return mode == .checked
                        default:
                            return false
                        }
                    }
                    self.isTodoExpand = isExpand
                    if sectionIndex != nil {
                        self.tableView.reloadSections(IndexSet(integer: sectionIndex!), with: .automatic)
                    }
                }
                return todoCompleteHeaderView
            }
        default:
            return nil
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .attachments(let attachmentBlocks):
            return AttachmentsBlockCell.calculateCellHeight(blocks: attachmentBlocks)
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo:
            return 44
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo(let todoBlocks, let mode):
            switch mode {
            case .unchecked:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let unCheckedTodos = self.sections[sourceIndexPath.section].getTodos(todoMode: .unchecked)
        let allTodos = self.note.todoBlocks
        
        guard let from = allTodos.index(of: unCheckedTodos[sourceIndexPath.row]),
            let to = allTodos.index(of: unCheckedTodos[destinationIndexPath.row]) else { return }
        DBManager.sharedInstance.update(withoutNotifying: [self.todoBlocksNotifiToken!]) {
            allTodos.move(from: from, to: to)
        }
        
        // 交换顺序
        var newUnCheckedTodos = unCheckedTodos
        let todo = newUnCheckedTodos.remove(at: sourceIndexPath.row)
        newUnCheckedTodos.insert(todo, at: destinationIndexPath.row)
        
        self.sections[sourceIndexPath.section] =  SectionType.todo(todoBlocks: newUnCheckedTodos, mode: .unchecked)
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        if destSection < sourceSection {
            return IndexPath(row: 0, section: sourceSection)
        } else if destSection > sourceSection {
            return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
        }
        return proposedDestinationIndexPath
    }
}

// drag and drop
extension EditorViewController: UITableViewDragDelegate, UITableViewDropDelegate  {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
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
    case title(titleBlock: Block)
    case text(textBlock: Block)
    case todo(todoBlocks: [Block],mode: TodoMode)
    case attachments(attachmentBlocks: [Block])
    
    var identifier: String {
        switch self {
        case .title:
            return "title"
        case .text:
            return "text"
        case .todo:
            return "todo"
        case .attachments:
            return "attachments"
        }
    }
    
    
    func getTodos(todoMode: TodoMode) -> [Block] {
        switch self {
        case .todo(let todoBlocks, let mode):
            if mode == todoMode {
                return todoBlocks
            }
            return []
        default:
            return []
        }
    }
}

enum TodoMode {
    case unchecked
    case checked
}


enum CreateMode {
    case text
    case todo
    case attachment(blocks:[Block])
}
