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


enum EditorUpdateMode {
    case insert(note:Note)
    case update(note:Note)
    case delete(note:Note)
}

enum EditorMode {
    case browser(note:Note)
    case create(note:Note)
    case delete(note:Note)
}

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    private var todoBlockCell: TodoBlockCell?
    
    private var attachmentsCell: AttachmentsBlockCell?
    
    
    var callbackNoteUpdate : ((EditorUpdateMode) -> Void)?
    
    // 索引
    private var note: Note!
    var mode: EditorMode! {
        didSet {
            switch mode {
            case .browser(let note):
                self.note = note
            case .create(let note):
                self.note = note
            default:
                break
            }
        }
    }
    var isNew = false
    
    var isNoteUpdated:Bool = false
    
    
    var todoRowIndexMap:[Int:(Int,Int)] = [:]
    
    var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private var todoGroupBlocksNotifiToken: NotificationToken?
    private var attachmentBlocksNotifiToken: NotificationToken?
    
    
    private var todoBlocksNotifiToken: [NotificationToken] = []
    
    private var noteNotificationToken: NotificationToken?
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then { [weak self] in
        
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TitleBlockCell.self, forCellReuseIdentifier:CellReuseIdentifier.title.rawValue)
        $0.register(TextBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.text.rawValue)
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.todo.rawValue)
        $0.register(TodoGroupCell.self, forCellReuseIdentifier: CellReuseIdentifier.todo_group.rawValue)
        $0.register(AttachmentsBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.attachments.rawValue)
        $0.contentInset = UIEdgeInsets(top: -1.0, left: 0, bottom: bottomExtraSpace, right: 0)
        
        $0.backgroundColor = .clear
        $0.delegate = self
        $0.dataSource = self
        
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        
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
        todoGroupBlocksNotifiToken?.invalidate()
    }
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    //    var isNew = false
    private var keyboardIsHide = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupData()
        
        //        let search =  UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: nil)
        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(handleMenuTapped))
        navigationItem.rightBarButtonItems = [more]
        
    }
    
    
    @objc func handleMenuTapped(sender:UIBarButtonItem) {
        //        self.attachmentsCell?.handleScreenRotation()
        let items = [
            ContextMenuItem(label: "移动到废纸篓", icon: "trash")
        ]
        ContextMenuViewController.show(sourceView:sender.view!, sourceVC: self, items: items) { [weak self] menuItem in
            guard let self = self else { return }
            self.moveNote2Trash()
        }
    }
    
    var updateAt:Date!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        updateAt = self.note.updateAt
    }
    @objc func rotated() {
        self.attachmentsCell?.handleScreenRotation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        tableView.endEditing(true)
        
        tryNotifiNoteUpdated()
    }
    
    
    private func tryNotifiNoteUpdated() {
        
        switch mode {
        case .browser:
            if self.updateAt != note.updateAt{
                if note.isEmpty {
                    DBManager.sharedInstance.deleteNote(note)
                    self.callbackNoteUpdate?(EditorUpdateMode.delete(note: self.note))
                    return
                }
                // 如果数据更新过，通知列表页刷新
                self.callbackNoteUpdate?(EditorUpdateMode.update(note: self.note))
            }
        case .create:
            if note.isEmpty {
                DBManager.sharedInstance.deleteNote(note)
                return
            }
            self.callbackNoteUpdate?(EditorUpdateMode.insert(note: self.note))
        case .delete:
            self.callbackNoteUpdate?(EditorUpdateMode.delete(note: self.note))
        case .none:
            break
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
        self.setFirstResponder()
        
    }
    
    private func setFirstResponder() {
        switch mode {
        case .create:
            if let textCell = textCell {
                textCell.textView.becomeFirstResponder()
            } else if let todoBlockCell = todoBlockCell {
                todoBlockCell.textView.becomeFirstResponder()
            }
        default:
            break
            
        }
    }
}

// context menu
extension EditorViewController {
    
    @objc func handleMoreButtonTapped(sender: UIButton) {
        self.view.endEditing(true)
    }
    
    private func moveNote2Trash() {
        guard let noteNotificationToken = self.noteNotificationToken else { return }
        DBManager.sharedInstance.moveNote2Trash(self.note, withoutNotifying: [noteNotificationToken]) {
            self.mode = EditorMode.delete(note: self.note)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    @objc func handleAddButtonTapped(sender: UIButton) {
        
        self.view.endEditing(true)
        
        let popMenuVC = PopBlocksViewController()
        popMenuVC.cellTapped = { [weak self] type in
            popMenuVC.dismiss(animated: true, completion: {
                self?.handleCreateModeMenu(type: type)
            })
        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: sender
        )
    }
    
    fileprivate func handleCreateModeMenu(type: MenuType) {
        self.tableView.resignFirstResponder()
        switch type {
        case .text:
            self.handleText()
        case .todo:
            self.handleTodoBlock()
            break
        case .image:
            let photoVC = TLPhotosPickerViewController()
            photoVC.delegate = self
            var configure = TLPhotosPickerConfigure()
            configure.allowedVideo = false
            configure.doneTitle = "完成"
            configure.cancelTitle="取消"
            configure.allowedLivePhotos = false
            configure.allowedVideoRecording = false
            photoVC.configure = configure
            self.present(photoVC, animated: true, completion: nil)
        case .camera:
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.image"]
            present(vc, animated: true)
        }
    }
    
    fileprivate func handleText() {
        if let textCell = textCell {
            textCell.textView.becomeFirstResponder()
            return
        }
        // 新增 textblock
        DBManager.sharedInstance.update(note: note) {
            isNoteUpdated = true
            note.textBlock = Block.newTextBlock()
        }
    }
    
    fileprivate func handleTodoBlock() {
        // 新增 todo block
        DBManager.sharedInstance.update(note: note) {
            isNoteUpdated = true
            note.todoBlocks.append(Block.newTodoGroupBlock())
        }
        
    }
}


// 数据处理
extension EditorViewController {
    
    private func showData() {
        self.setupSectionsTypes(note: note)
        self.tableView.reloadData()
        
    }
    
    fileprivate func setupData() {
        self.showData()
        self.noteNotificationToken = note.observe { change in
            switch change {
            case .change(let properties):
                for property in properties {
                    self.handlePropertyChange(propertyChange: property)
                }
                self.isNoteUpdated = true
            case .error(let error):
                print("An error occurred: \(error)")
            case .deleted:
                print("The object was deleted.")
            }
        }
    }
    fileprivate func handlePropertyChange(propertyChange: PropertyChange) {
        switch propertyChange.name {
        case  "textBlock":
            self.handleTextBlockUpdate(change: propertyChange)
        case "attachBlocks":
            self.handleAttachBlockUpdate(change:propertyChange)
        default:
            break
        }
    }
    
    fileprivate func handleTextBlockUpdate(change: PropertyChange) {
        if let textBlock = (change.newValue as? Block), change.oldValue == nil { // 新增 text
            let sectionIndex = 1
            self.sections.insert(SectionType.text(textBlock: textBlock), at: sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .bottom)
            }) { _ in
                self.textCell?.textView.becomeFirstResponder()
            }
        }
    }
    
    
    fileprivate func handleAttachBlockUpdate(change: PropertyChange) {
        let attachBlocks = change.newValue as! List<Block>
        if attachmentsCell == nil && attachBlocks.count > 0 { // 新增
            let sectionIndex = self.sections.count
            self.sections.append(SectionType.attachments(attachmentBlocks: Array(attachBlocks)))
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .automatic)
            }) { _ in
            }
        }
    }
    
    
    
    
    fileprivate func setupSectionsTypes(note: Note) {
        if let titleBlock = note.titleBlock {
            self.sections.append(SectionType.title(titleBlock: titleBlock))
        }
        if let textBlock = note.textBlock {
            self.sections.append(SectionType.text(textBlock: textBlock))
        }
        
        self.todoGroupBlocksNotifiToken =  self.setupTodoSections(todoBlocks: note.todoBlocks)
        
        if !note.attachBlocks.isEmpty {
            self.sections.append(SectionType.attachments(attachmentBlocks: Array(note.attachBlocks)))
        }
    }
    
    fileprivate func setupTodoSections(todoBlocks: List<Block>) -> NotificationToken {
        let notificationToken = todoBlocks.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, modifications: _):
                if deletionIndices.count > 0 || insertionIndices.count > 0 {
                    self.handleTodoSectionUpdate(insertionIndices: insertionIndices, deletionIndices: deletionIndices)
                }
                break
            case .error(let error):
                print(error)
            case .initial:
                self.observeSectionTodos()
                self.tableView.reloadData()
            }
            
        }
        return notificationToken
    }
    
    fileprivate func handleTodoSectionUpdate(insertionIndices: [Int],deletionIndices:[Int] ) {
        
        let firstSectionIndex = self.firstTodoSectionIndex
        
        // 更新数据源-observer
        updateObserver(insertionIndices:insertionIndices,deletionIndices:deletionIndices)
        
        tableView.performBatchUpdates({
            tableView.deleteSections(IndexSet(deletionIndices.map{ $0 + firstSectionIndex }), with: .bottom)
            tableView.insertSections(IndexSet(insertionIndices.map{ $0 + firstSectionIndex }), with: .top)
        }) { _ in
            if insertionIndices.count > 0 {
                if let lastTodoSection = insertionIndices.max() {
                    self.tryGetFocus(sectionIndex:(lastTodoSection + firstSectionIndex))
                }
            }
        }
    }
    
    // 只会“删除” 或 “添加” 一次的场景
    fileprivate func updateObserver(insertionIndices:[Int],deletionIndices:[Int]) {
        
        deletionIndices.forEach {
            self.todoBlocksNotifiToken[$0].invalidate()
            self.todoBlocksNotifiToken.remove(at: $0)
            self.sections.remove(at: $0+firstTodoSectionIndex)
        }
        
        let firstSectionIndex = self.firstTodoSectionIndex
        insertionIndices.forEach { sectionIndex in
            
            let sIndex = sectionIndex + firstSectionIndex
            let todoGroupBlocks = self.note.todoBlocks
            let todoGroupBlock = todoGroupBlocks[sectionIndex]
            
            // 修改数据源
            var todoBlocks = Array(todoGroupBlock.blocks)
            todoBlocks.insert(todoGroupBlock, at: 0)
            self.sections.insert(SectionType.todo(todoBlocks: todoBlocks), at: sIndex)
            
            let notificationToken =  todoGroupBlock.blocks.observe { changes in
                self.handleTodoChanges(todoGroupBlock:todoGroupBlock, changes: changes)
            }
            self.todoBlocksNotifiToken.insert(notificationToken, at: sectionIndex)
        }
    }
    
    fileprivate func observeSectionTodos() {
        
        let todoGroupBlocks = self.note.todoBlocks
        let sectionIndex = self.firstTodoSectionIndex
        
        // 生成sections
        let sections:[SectionType] = todoGroupBlocks.map {
            var todoBlocks = Array($0.blocks)
            todoBlocks.insert($0, at: 0)
            return  SectionType.todo(todoBlocks:todoBlocks )
        }
        self.sections.insert(contentsOf: sections, at: sectionIndex)
        
        self.todoBlocksNotifiToken = todoGroupBlocks.map { todoGroupBlock in
            todoGroupBlock.blocks.observe { changes in
                self.handleTodoChanges(todoGroupBlock:todoGroupBlock, changes: changes)
            }
        }
    }
    
    fileprivate func handleTodoChanges(todoGroupBlock: Block,changes: RealmCollectionChange<List<Block>>) {
        switch changes {
        case .update(_, deletions: let deletionIndices, insertions: let insertionIndices, _):
            guard let sectionIndex = self.note.todoBlocks.index(of: todoGroupBlock)  else { return }
            let sIndex = sectionIndex + self.firstTodoSectionIndex
            
            // 更新 section 数据源
            if insertionIndices.count > 0 || deletionIndices.count>0 {
                var todoBlocks = Array(note.todoBlocks[sectionIndex].blocks)
                todoBlocks.insert(todoGroupBlock, at: 0)
                self.sections[sIndex] = SectionType.todo(todoBlocks: todoBlocks)
                
                if(!todoGroupBlock.isExpand) { // 已经折叠，不需要再更新 ui 了
                    return
                }
            }
            // 防止 ui 出错
            tableView.performBatchUpdates({
                tableView.deleteRows(at: deletionIndices.map{ IndexPath(row: $0+1, section: sIndex)}, with: .automatic)
                tableView.insertRows(at: insertionIndices.map{ IndexPath(row: $0+1, section: sIndex)}, with: .automatic)
            }) { _ in
                if !insertionIndices.isEmpty { // 弹出键盘
                    self.tryGetFocus(sectionIndex: sIndex)
                }
            }
            break
        case .error(let error):
            print(error)
        case .initial(let type):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tryGetFocus(sectionIndex: self.firstTodoSectionIndex)
            }
            print(type)
        }
    }
    
}

// 数据处理-todo
extension EditorViewController {
    
    //    func getFirstTodoBlockSectionIndex() -> Int {
    //        var index = 0
    //        self.sections.forEach {
    //            switch $0 {
    //            case .title:
    //                index += 1
    //                break
    //            case .text:
    //                index += 1
    //                break
    //            default:
    //                break
    //            }
    //        }
    //        return index
    //    }
    
    var firstTodoSectionIndex: Int {
        var index = 0
        if titleCell != nil {
            index += 1
        }
        
        if textCell != nil {
            index += 1
        }
        
        return index
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
    
    
    private func tryGetFocus(sectionIndex: Int) {
        let sectionType = self.sections[sectionIndex]
        if  case .todo(let todoBlocks) = sectionType {
            if let rowIndex = todoBlocks.lastIndex(where: { $0.text.isEmpty }) {
                let indexPath =  IndexPath(row: rowIndex, section: sectionIndex)
                let cell = tableView.cellForRow(at:indexPath)
                if cell == nil {
                    tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                        guard let self = self else { return }
                        if  let newCell = self.tableView.cellForRow(at:indexPath) as? TodoBlockCell{
                            newCell.textView.becomeFirstResponder()
                        }
                    }
                    return
                }
                if let todoCell = cell as? TodoBlockCell {
                    todoCell.textView.becomeFirstResponder()
                }
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
        case .todo(let todoBlocks):
            if todoBlocks[0].isExpand {
                return todoBlocks.count
            }
            return 1
        default:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func getCellIdentifier(sectionObj:SectionType,indexPath:IndexPath) -> String{
        switch sectionObj {
        case .todo:
            return indexPath.row == 0 ? CellReuseIdentifier.todo_group.rawValue : CellReuseIdentifier.todo.rawValue
        case .text:
            return CellReuseIdentifier.text.rawValue
        case .title:
            return CellReuseIdentifier.title.rawValue
        case .attachments:
            return CellReuseIdentifier.attachments.rawValue
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier:getCellIdentifier(sectionObj: sectionObj, indexPath: indexPath), for: indexPath)
        switch sectionObj {
        case .title:
            let titleCell = (cell as! TitleBlockCell).then {
                $0.note = note
                $0.enterkeyTapped { [weak self] _ in
                    self?.textCell?.textView.becomeFirstResponder()
                }
            }
            self.titleCell = titleCell
            break
        case .text:
            let textCell = cell as! TextBlockCell
            textCell.note = note
            textCell.textChanged {[weak tableView] newText in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            self.textCell = textCell
            break
        case .todo(let todoBlocks):
            let todoBlock = todoBlocks[indexPath.row]
            if indexPath.row == 0 { // group cell
                let todoGroupCell = cell as! TodoGroupCell
                todoGroupCell.note = note
                todoGroupCell.todoGroupBlock = todoBlock
                setupTodoGroupCell(todoGroupCell: todoGroupCell)
            }else {
                let todoCell = cell as! TodoBlockCell
                todoCell.todoGroupBlock = todoBlocks[0]
                todoCell.todoBlock = todoBlock
                todoCell.note = note
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
            }
            break
        case .attachments:
            let imagesCell = cell as! AttachmentsBlockCell
            imagesCell.heightChanged = { [weak tableView]  in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            imagesCell.note = self.note
            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
    
    fileprivate func setupTodoGroupCell(todoGroupCell: TodoGroupCell) {
        todoGroupCell.arrowButtonTapped = { todoGroupBlock in
            DBManager.sharedInstance.update(note:self.note,withoutNotifying: self.todoBlocksNotifiToken) {
                todoGroupBlock.isExpand = !todoGroupBlock.isExpand
            }
            if let sectionIndex = self.note.todoBlocks.index(of: todoGroupBlock) {
                self.tableView.reloadSections(IndexSet(integer: sectionIndex+self.firstTodoSectionIndex), with: .automatic)
            }
        }
        todoGroupCell.menuButtonTapped = { btn,todoGroupBlock in
            let items = [
                ContextMenuItem(label: "删除", icon: "trash")
            ]
            guard let todoSectionIndex = self.note.todoBlocks.index(of: todoGroupBlock) else { return }
            ContextMenuViewController.show(sourceView: btn, sourceVC: self, items: items) { [weak self] menuItem in
                self?.deleteBlockByIndex(sectionIndex: todoSectionIndex)
            }
        }
    }
    
    fileprivate func deleteBlockByIndex(sectionIndex: Int) {
        DBManager.sharedInstance.update(note: note){
            self.isNoteUpdated = true
            self.note.todoBlocks.remove(at: sectionIndex)
        }
    }
    
    fileprivate func handleTextViewEnterKey(textView: UITextView){
        let tableView = self.tableView
        if let cursorPosition = textView.selectedTextRange?.start {
            let caretPositionRect = textView.caretRect(for: cursorPosition)
            
            let inWindowRect = textView.convert(caretPositionRect, to: nil)
            let visibleHeight = UIScreen.main.bounds.height - (self.keyboardHeight+self.bottombarHeight)
            
            let cursorY = inWindowRect.origin.y +  caretPositionRect.height
            
            Logger.info("cursorY", cursorY)
            Logger.info("visibleHeight", visibleHeight)
            if cursorY > visibleHeight { // 光标隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let newOffsetY =  tableView.contentOffset.y +  (cursorY - self.keyboardHeight2)
                    Logger.info("tableView.contentOffset.y", tableView.contentOffset.y)
                    Logger.info("newOffsetYy", newOffsetY)
                    // your code here
                    tableView.contentOffset.y = newOffsetY
                    //                    tableView.scrollRectToVisible(CGRect.init(x: 0, y: cursorY, width: 0, height: 0), animated: false)
                    //                    tableView.scroll
                    //                    tableView.scrollToBottom()
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo(let todoBlocks):
            let todoFooterView = TodoFooterView()
            todoFooterView.todoGroupBlock = todoBlocks[0]
            todoFooterView.addButtonTapped = { todoGroupBlock in
                if let index = todoGroupBlock.blocks.lastIndex(where: { $0.text.isEmpty && !$0.isChecked }) {
                    let sectionIndex = self.firstTodoSectionIndex + (self.note.todoBlocks.index(of: todoGroupBlock) ?? 0)
                    let cell = tableView.cellForRow(at: IndexPath(row: index+1, section: sectionIndex)) as! TodoBlockCell
                    if cell.textView.text.isEmpty {
                        cell.textView.becomeFirstResponder()
                        return
                    }
                    cell.updateTodo()
                }
                DBManager.sharedInstance.update(note: self.note) {
                    todoGroupBlock.blocks.insert(Block.newTodoBlock(),at: todoGroupBlock.blocks.count)
                }
            }
            return todoFooterView
        default:
            return nil
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .attachments(_):
            return attachmentsCell?.totalHeight ?? 0
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .title:
            return 13
        case .text:
            return 10
        case .todo:
            let sectionPreIndex = section - 1
            let preSectionType =  self.sections[sectionPreIndex]
            switch preSectionType {
            case .title:
                return 2
            case .todo(let todoBlocks):
                return todoBlocks[0].isExpand ? 8 : 0
            default:
                return 10
            }
        case .attachments:
            //            let sectionPreIndex = section - 1
            //            if self.sections[sectionPreIndex].identifier == "todo" {
            //                return 16
            //            }
            return 18
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo(let todoBlocks):
            return todoBlocks[0].isExpand ? 30 : CGFloat.leastNormalMagnitude
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo:
            return indexPath.row > 0 //第一行是 group title
        default:
            return false
        }
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromSection = sourceIndexPath.section
        let toSection = destinationIndexPath.section
        
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        
        if fromSection != toSection {
            swapRowCrossSection(fromSection: fromSection, toSection: toSection, fromRow: fromRow, toRow: toRow)
        }else {
            swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
        }
    }
    
    func swapRowInSameSection(section:Int,fromRow:Int,toRow:Int) {
        if case .todo(var todoBlocks) =  self.sections[section] {
            todoBlocks.swapAt(fromRow, toRow)
            self.sections[section] = SectionType.todo(todoBlocks: todoBlocks)
        }
        
        let todoBlocks = self.note.todoBlocks[section -  self.firstTodoSectionIndex].blocks
        DBManager.sharedInstance.update(note:note,withoutNotifying: self.todoBlocksNotifiToken) {
            todoBlocks.move(from: fromRow-1, to: toRow-1)
        }
    }
    
    func swapRowCrossSection(fromSection:Int,toSection:Int,fromRow:Int,toRow:Int) {
        var fromTodoBlock:Block?
        
        // from : remove
        if case .todo(var todoBlocks) =  self.sections[fromSection] {
            fromTodoBlock = todoBlocks[fromRow]
            todoBlocks.remove(at: fromRow)
            self.sections[fromSection] = SectionType.todo(todoBlocks: todoBlocks)
        }
        
        // to : insert
        if case .todo(var todoBlocks) =  self.sections[toSection] {
            if let fromTodoBlock = fromTodoBlock {
                todoBlocks.insert(fromTodoBlock, at: toRow)
            }
            self.sections[toSection] = SectionType.todo(todoBlocks: todoBlocks)
        }
        
        // 更新数据库
        let fromBlocks = self.note.todoBlocks[fromSection -  self.firstTodoSectionIndex].blocks
        let toBlocks = self.note.todoBlocks[toSection -  self.firstTodoSectionIndex].blocks
        DBManager.sharedInstance.update(note:self.note,withoutNotifying: self.todoBlocksNotifiToken) {
            let todoBlock = fromBlocks[fromRow-1]
            fromBlocks.remove(at: fromRow-1)
            toBlocks.insert(todoBlock, at: toRow-1)
        }
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        if case .todo = self.sections[destSection]  {
            return proposedDestinationIndexPath
        }
        
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
            keyboardHeight2 =  keyboardHeight + bottombarHeight
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            self.bottombar.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset( -(rect.height - view.safeAreaInsets.bottom))
            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
                self?.bottombar.keyboardShow = true
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
                self?.bottombar.keyboardShow = false
            }
            var contentInset = self.tableView.contentInset
            contentInset.bottom = bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
        }
    }
}

// 相册
extension EditorViewController: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    func handlePicker(images: [TLPHAsset]) {
        self.showHud()
        Observable<[TLPHAsset]>.just(images)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(images)  -> [Block] in
                var imageBlocks:[Block] = []
                images.forEach {
                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
                        let imageName =  $0.uuidName
                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                        if success {
                            imageBlocks.append(Block.newImageBlock(imageUrl: imageName))
                        }
                    }
                }
                return imageBlocks
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    DBManager.sharedInstance.update(note: self.note) {
                        self.note.attachBlocks.append(objectsIn: blocks)
                    }
                }
        }
        .disposed(by: disposeBag)
    }
}

// camera 选择
extension EditorViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {  return}
        self.handlePicker(image: image)
    }
    
    func handlePicker(image: UIImage) {
        self.showHud()
        Observable<UIImage>.just(image)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(image)  -> [Block] in
                let imageName = UUID().uuidString+".png"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        return [Block.newImageBlock(imageUrl: imageName)]
                    }
                }
                return []
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    DBManager.sharedInstance.update(note: self.note) {
                        self.note.attachBlocks.append(objectsIn: blocks)
                    }
                }
        }
        .disposed(by: disposeBag)
    }
    
    
}



enum SectionType {
    case title(titleBlock: Block)
    case text(textBlock: Block)
    case todo(todoBlocks:[Block])
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
}

enum CellReuseIdentifier: String {
    case title = "title"
    case text = "text"
    case todo = "todo"
    case todo_group = "todo_group"
    case attachments = "attachments"
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
