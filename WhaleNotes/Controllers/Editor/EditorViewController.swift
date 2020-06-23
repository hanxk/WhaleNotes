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
import MobileCoreServices
import TLPhotoPicker
import RxSwift
import MBProgressHUD
import DeepDiff
import JXPhotoBrowser


enum EditorUpdateMode {
    case insert(noteInfo:Note)
    case update(noteInfo:Note)
    case delete(noteInfo:Note)
    case moved(noteInfo:Note)
}

enum EditorMode {
    case browser(noteInfo:Note)
    case create(noteInfo:Note)
    case delete(noteInfo:Note)
}

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 16
    let bottombarHeight: CGFloat = 42.0
    let topExtraSpace: CGFloat =  10
    let bottomExtraSpace: CGFloat = 42.0
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    var disposebag = DisposeBag()
    
    
    private var attachmentsCell: AttachmentsBlockCell? {
        if let index = sections.firstIndex(where: {$0 == SectionType.images}),
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index)) as? AttachmentsBlockCell  {
            return cell
        }
        return nil
    }
    
    
    var callbackNoteUpdate : ((EditorUpdateMode) -> Void)?
    
    private let noteRepo = NoteRepo.shared
    
    
    // 索引
    private var note: Note!
    
    
    private var bg:String! {
        didSet {
            let bg =  UIColor(hexString: note.backgroundColor)
            bottombar.backgroundColor = bg
            self.navigationItem.titleView = titleTextField
            navigationController?.navigationBar.barTintColor = bg
            self.view.backgroundColor =  bg
        }
    }
    
    private var oldUpdatedAt:Date!
    
    var mode: EditorMode! {
        didSet {
            switch mode {
            case .browser(let noteInfo):
                self.note = noteInfo
                oldUpdatedAt = noteInfo.rootBlock.updatedAt
            case .create(let noteInfo):
                self.note = noteInfo
            default:
                break
            }
        }
    }
    var isNew = false
    
    var isNoteUpdated:Bool = false
    
    
    var todoRowIndexMap:[Int:(Int,Int)] = [:]
    
    private var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then { [weak self] in
        
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(BoardsCell.self, forCellReuseIdentifier:CellReuseIdentifier.boards.rawValue)
        $0.register(TitleBlockCell.self, forCellReuseIdentifier:CellReuseIdentifier.title.rawValue)
        $0.register(TextBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.text.rawValue)
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.todo.rawValue)
        $0.register(AttachmentsBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.images.rawValue)
        $0.contentInset = UIEdgeInsets(top: topExtraSpace, left: 0, bottom: bottomExtraSpace, right: 0)
        $0.showsVerticalScrollIndicator = false
        
        $0.backgroundColor = .clear
        $0.delegate = self
        $0.dataSource = self
        
        $0.allowsSelection = false
        
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        $0.keyboardDismissMode = .interactive
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        $0.dropDelegate = self
        
    }
    
    private lazy var bottombar: BottomBarView = BottomBarView().then {[weak self] in
        guard let self = self else { return }
        $0.moreButton.addTarget(self, action: #selector(self.handleMoreButtonTapped), for: .touchUpInside)
        $0.addButton.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
        $0.keyboardButton.addTarget(self, action: #selector(self.handleKeyboardButtonTapped), for: .touchUpInside)
    }
    
    lazy var titleTextField =  TitleTextField(frame:  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )).then {
        $0.textAlignment = .center
        $0.placeholder = "标题"
        $0.clipsToBounds = true
        $0.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 120, height: 44 )
        $0.backgroundColor = .clear
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .primaryText
        $0.delegate = self
    }
    
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    private var keyboardIsHide = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
        
    }
    
    
    @objc func handleMenuTapped(sender:UIBarButtonItem) {
        self.hideKeyboard()
    }
    
    func hideKeyboard() {
        titleTextField.resignFirstResponder()
        self.tableView.endEditing(true)
    }
    
    var updateAt:Date!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.backgroundColor = .red
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        

        self.bg = note.backgroundColor
        updateAt = self.note.updatedAt
    }
    @objc func rotated() {
//        self.attachmentsCell?.handleScreenRotation()
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
            if self.oldUpdatedAt != note.updatedAt{
                if note.isContentEmpry {
                    self.deleteNote()
                    return
                }
                self.callbackNoteUpdate?(EditorUpdateMode.update(noteInfo: self.note))
            }
            break
        case .create:
            if note.isContentEmpry {
                self.deleteNote()
                return
            }
            self.callbackNoteUpdate?(EditorUpdateMode.insert(noteInfo: self.note))
        case .delete:
            self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: self.note))
        case .none:
            break
        }
    }
    
    private func setupUI() {
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
        case .create(let noteInfo):
            if noteInfo.textBlock != nil {
                textCell?.textView.becomeFirstResponder()
            }else if noteInfo.todoBlocks.isNotEmpty {
                self.tryFocusTodoSection()
            }
        default:
            break
        }
    }
    
    private func tryFocusTodoSection() {
        if let cell = self.tableView.cellForRow(at:IndexPath(row: 0, section: todoSectionIndex)) as? TodoBlockCell {
            cell.textView.becomeFirstResponder()
        }
    }
}

//MARK: NoteMenuViewControllerDelegate
extension EditorViewController:NoteMenuViewControllerDelegate {
    func noteMenuMoveToTrash(note: Note) {
        self.navigationController?.popViewController(animated: true)
        self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: note))
    }
    
    func noteMenuChooseBoards(note: Note) {
        self.openChooseBoardsVC()
    }
    
    func noteMenuBackgroundChanged(note: Note) {
        self.note = note
        self.bg = note.backgroundColor
    }
    
    
    func noteMenuDataMoved(note: Note) {
        self.navigationController?.popViewController(animated: true)
        self.callbackNoteUpdate?(EditorUpdateMode.moved(noteInfo: note))
    }
    
    @objc func handleMoreButtonTapped(sender: UIButton) {
        if note.status == NoteBlockStatus.trash {
            NoteMenuViewController.showTrashMenu(note: self.note, sourceView: sender, delegate: self)
        }else {
            NoteMenuViewController.show(note: self.note, sourceView: sender,delegate: self)
        }
    }
    
    
    @objc func handleKeyboardButtonTapped(sender: UIButton) {
        self.hideKeyboard()
    }
    
    private func moveNote2Trash(sender: UIButton) {
        //        guard let noteNotificationToken = self.noteNotificationToken else { return }
        //        DBManager.sharedInstance.moveNote2Trash(self.note, withoutNotifying: [noteNotificationToken]) {
        //            self.mode = EditorMode.delete(note: self.note)
        //            self.navigationController?.popViewController(animated: true)
        //        }
        
    }
    
    
    //MARK: 添加 block
    @objc func handleAddButtonTapped(sender: UIButton) {
        
        self.view.endEditing(true)
        
        NotesView.showNotesMenu(sourceView: sender, sourceVC: self) { [weak self]  menuType in
            self?.handleCreateModeMenu(type:menuType)
        }
    }
    
    fileprivate func handleCreateModeMenu(type: MenuType) {
        self.tableView.resignFirstResponder()
        switch type {
        case .text:
            self.handleText()
        case .todo:
            self.addTodoSection()
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
        let sectionIndex = 0
        self.createBlock(block: Block.newTextBlock(text: "", noteId: self.note.id)) { _ in
            self.sections.insert(SectionType.text, at:sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .bottom)
            }) { _ in
                
                //获取焦点
                if let cell = self.tableView.cellForRow(at:IndexPath(row: 0, section: sectionIndex)) as? TextBlockCell {
                    cell.textView.becomeFirstResponder()
                }
                
            }
        }
    }
    
    fileprivate func addTodoSection() {
        // 添加在第一行
        if let _ = note.rootTodoBlock {
            let nextIndexPath = IndexPath(row: note.todoBlocks.count, section: todoSectionIndex)
            let sort = self.calcNextTodoBlockSort(newTodoIndex: nextIndexPath.row)
            self.createNewTodoBlock(sort: sort, targetIndex: nextIndexPath)
        }else {
            self.createRootTodoBlock()
        }
    }
}


extension EditorViewController:NoteMenuViewControllerTrashDelegate {
    func noteMenuDeleteTapped(note: Note) {
        let alert = UIAlertController(title: "删除便签", message: "你确定要彻底删除该便签吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "彻底删除", style: .destructive, handler: { _ in
            
            NoteRepo.shared.deleteNote(noteId: note.id)
                .subscribe(onNext: { isSuccess in
                    self.noteMenuDataRestored(note: note)
                }, onError: { error in
                    Logger.error(error)
                },onCompleted: {
                })
                .disposed(by: self.disposeBag)
            
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel,handler: nil))
        self.present(alert, animated: true)
    }
    
    func noteMenuDataRestored(note: Note) {
        self.navigationController?.popViewController(animated: true)
        self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: note))
    }
    
}


// 数据处理
extension EditorViewController {
    
    fileprivate func setupData() {
        
        self.setupSectionsTypes()
        self.tableView.reloadData()
        
        bottombar.updatedDateStr =  self.note.updatedDateStr
        bottombar.addButton.isEnabled = self.note.status != NoteBlockStatus.trash
        
        self.titleTextField.text = self.note.rootBlock.text
        self.titleTextField.isEnabled = self.note.status != NoteBlockStatus.trash
        
    }
    
    fileprivate func setupSectionsTypes() {
        self.sections.removeAll()
        if let _ = note.textBlock {
            self.sections.append(SectionType.text)
        }
        
        if note.rootTodoBlock != nil {
            self.sections.append(SectionType.todo)
        }
        
        if note.imageBlocks.isNotEmpty {
            self.sections.append(SectionType.images)
        }
//        self.sections.append(SectionType.boards)
    }
    
}

// 数据处理-todo
extension EditorViewController {
    
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
    
    
    
    private func tryGetFocus(sectionIndex: Int) {
        //        let sectionType = self.sections[sectionIndex]
        //        if  case .todo(let todoBlockInfo) = sectionType {
        //            if let rowIndex = todoBlocks.lastIndex(where: { $0.text.isEmpty }) {
        //                let indexPath =  IndexPath(row: rowIndex, section: sectionIndex)
        //                let cell = tableView.cellForRow(at:indexPath)
        //                if cell == nil {
        //                    tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        //                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        //                        guard let self = self else { return }
        //                        if  let newCell = self.tableView.cellForRow(at:indexPath) as? TodoBlockCell{
        //                            newCell.textView.becomeFirstResponder()
        //                        }
        //                    }
        //                    return
        //                }
        //                if let todoCell = cell as? TodoBlockCell {
        //                    todoCell.textView.becomeFirstResponder()
        //                }
        //            }
        //        }
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

//MARK: UITableViewDataSource
extension EditorViewController: UITableViewDataSource {
    
    var todoSectionIndex:Int {
        if let section = sections.firstIndex(of: SectionType.todo) {
            return section
        }
        var section = 1
        if let textSection = sections.firstIndex(of: SectionType.text) {
            section = textSection + 1
        }
        return section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo:
            return note.todoBlocks.count
        default:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    private func getCellIdentifier(sectionType:SectionType,indexPath:IndexPath) -> String {
        
        switch sectionType {
        case .text:
            return CellReuseIdentifier.text.rawValue
        case .images:
            return CellReuseIdentifier.images.rawValue
        case .todo:
            return CellReuseIdentifier.todo.rawValue
            
        case .boards:
            return CellReuseIdentifier.boards.rawValue
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier:getCellIdentifier(sectionType: sectionObj, indexPath: indexPath), for: indexPath)
        switch sectionObj {
        case .boards:
            let boardsCell = cell as! BoardsCell
            boardsCell.boards =  note.boards
            boardsCell.callbackTaped = { [weak self] in
                self?.openChooseBoardsVC()
            }
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
            textCell.blockUpdated = { [weak self] block in
                guard let self = self else { return }
                self.tryUpdateBlock(block: block)
            }
            self.textCell = textCell
            break
        case .todo:
            let todoBlock = self.note.todoBlocks[indexPath.row]
            let todoCell = cell as! TodoBlockCell
            todoCell.todoBlock = todoBlock
            todoCell.note = note
            todoCell.backgroundColor = .clear
            todoCell.delegate = self
        case .images:
            let imagesCell = cell as! AttachmentsBlockCell
            imagesCell.heightChanged = { [weak tableView]  in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            imagesCell.callbackCellTapped  = { indexPath in
                let browser = PhotoViewerViewController(note: self.note, pageIndex: indexPath.row)
                browser.isFromNoteDetail = true
                browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
                    let path = IndexPath(item: index, section: indexPath.section)
                    let cell = imagesCell.collectionView.cellForItem(at: path) as? ImageCell
                    return cell?.imageView
                })
                browser.callbackPhotoBlockDeleted = { newNote  in
                    self.handleImageBlocksUpdated(newNote:newNote)
                }
                browser.show()
                
            }
            imagesCell.reloadData(imageBlocks:  self.note.imageBlocks)
//            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
    
    private func handleImageBlocksUpdated(newNote:Note) {
        self.note = newNote
        guard let index = self.sections.firstIndex(where: {$0 == SectionType.images}) else { return }
        if newNote.imageBlocks.isEmpty {
            self.sections.remove(at: index)
            self.tableView.performBatchUpdates({
                self.tableView.deleteSections(IndexSet([index]), with: .automatic)
            }, completion: nil)
        }else {
            
            if let cell = self.attachmentsCell {
                cell.reloadData(imageBlocks: self.note.imageBlocks)
            }
//            self.tableView.performBatchUpdates({
//                self.tableView.reloadSections(IndexSet([index]), with: .automatic)
//            }, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo:
            return true
        default:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "删除") {  (contextualAction, view, boolValue) in
            self.tryDeleteTodoBlock(block: self.note.todoBlocks[indexPath.row])
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        
        return swipeActions
    }
    
    fileprivate func handleTodoEnterKeyTapped(block:Block) {
        
        
        if block.text.isEmpty { // 删除
            self.tryDeleteTodoBlock(block: block)
        }else { // 新增
            guard let row = self.note.todoBlocks.firstIndex(where: {$0.id == block.id}) else { return }
            
            // 先更新
            self.tryUpdateBlock(block: block) {
                //新增
                let nextIndexPath = IndexPath(row: row+1, section: self.todoSectionIndex)
                
                let sort = self.calcNextTodoBlockSort(newTodoIndex: nextIndexPath.row)
                self.createNewTodoBlock(sort: sort, targetIndex: nextIndexPath)
            }
        }
    }
    
    
    func openChooseBoardsVC()  {
        let vc = ChooseBoardViewController()
        vc.note = note
        vc.callbackBoardChoosed = { newNote in
            if let boardSectionIndex = self.sections.firstIndex(of: SectionType.boards),
                let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: boardSectionIndex)) as? BoardsCell {
                self.note = newNote
                cell.boards = newNote.boards
            }
        }
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    fileprivate func handleTextViewEnterKey(textView: UITextView){
        let tableView = self.tableView
        if let cursorPosition = textView.selectedTextRange?.start {
            let caretPositionRect = textView.caretRect(for: cursorPosition)
            
            let inWindowRect = textView.convert(caretPositionRect, to: nil)
            let visibleHeight = UIScreen.main.bounds.height - (self.keyboardHeight+self.bottombarHeight)
            
            let cursorY = inWindowRect.origin.y +  caretPositionRect.height
            
            if cursorY > visibleHeight { // 光标隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let newOffsetY =  tableView.contentOffset.y +  (cursorY - self.keyboardHeight2)
                    tableView.contentOffset.y = newOffsetY
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionType = sections[section]
        switch sectionType {
        case .todo:
            let todoFooterView = TodoFooterView()
            if note.status != NoteBlockStatus.trash {
                todoFooterView.addButtonTapped = { [weak self] in
                    guard let self = self else { return }
                    let nextIndexPath = IndexPath(row:self.note.todoBlocks.count, section: section)
                    let sort = self.calcNextTodoBlockSort(newTodoIndex: nextIndexPath.row)
                    self.createNewTodoBlock(sort: sort, targetIndex: nextIndexPath)
                }
                todoFooterView.menuButtonTapped = {[weak self] menuButton in
                    self?.handlerTodoMenuButtonTapped(menuButton:menuButton)
                }
            }
            return todoFooterView
        default:
            return nil
        }
    }
    
    private func handlerTodoMenuButtonTapped(menuButton: UIButton) {
        
        let TAG_DEL = 1
        
        let items = [
            ContextMenuItem(label: "删除", icon: "trash",tag:TAG_DEL)
        ]
        ContextMenuViewController.show(sourceView:menuButton, sourceVC: self, items: items) { [weak self] menuItem, vc in
            vc.dismiss(animated: true, completion: nil)
            guard let self = self,let tag = menuItem.tag as? Int else { return }
            switch tag {
            case TAG_DEL:
                self.showAlertMessage(message: "确认要删除所有待办事项吗？", positiveButtonText: "删除",isPositiveDestructive:true) {
                    self.deleteRootTodoBlock()
                    
                }
                break
            default:
                break
                
            }
        }
    }
    
    
    private func createNewTodoBlock(sort:Double,targetIndex:IndexPath) {
        
        guard let rootTodoBlock = self.note.rootTodoBlock else { return }
        // 新增
        let todoBlock = Block.newTodoBlock(noteId: self.note.id, sort: sort,parent: rootTodoBlock.id)
        self.createBlock(block: todoBlock) { _ in
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [targetIndex], with: .bottom)
            }, completion: { _ in
                
                //获取焦点
                if let cell = self.tableView.cellForRow(at:targetIndex) as? TodoBlockCell {
                    cell.textView.becomeFirstResponder()
                }else {
                    self.tableView.scrollToRow(at: targetIndex, at: .bottom, animated: false)
                    if let cell = self.tableView.cellForRow(at:targetIndex) as? TodoBlockCell {
                        cell.textView.becomeFirstResponder()
                    }
                }
            })
        }
        
    }
    
    
    private func createRootTodoBlock() {
        noteRepo.createRootTodoBlock(noteId: note.id)
            .subscribe(onNext: {
                self.note.setupTodoBlocks(todoBlocks: $0)
                self.setupSectionsTypes()
                self.tableView.performBatchUpdates({
                    self.tableView.insertSections(IndexSet([self.todoSectionIndex]), with: .automatic)
                }) { _ in
                    if let cell = self.tableView.cellForRow(at:IndexPath(row: 0, section: self.todoSectionIndex)) as? TodoBlockCell {
                        cell.textView.becomeFirstResponder()
                    }
                }
                
            },onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
        
    }
    
}


//MARK: TodoBlockCellDelegate
extension EditorViewController: TodoBlockCellDelegate {
    func todoCheckedChange(newBlock: Block) {
        self.tryUpdateBlock(block: newBlock) {
            
        }
    }
    
    func handleTodoCellUpdated(newBlock: Block) {
        guard let todoBlockIndex = self.note.getTodoBlockIndex(todoBlock: newBlock) else { return }
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [IndexPath(row: todoBlockIndex, section: self.todoSectionIndex)], with: .automatic)
        }, completion: nil)
    }
    
    func textDidChange() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {[weak self] in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }
        }
    }
    
    func todoBlockEnterKeyInput(newBlock: Block) {
        self.handleTodoEnterKeyTapped(block:newBlock)
    }
    
    func todoBlockNeedDelete(newBlock: Block) {
        self.tryDeleteTodoBlock(block: newBlock)
    }
    
    func todoBlockContentChange(newBlock: Block) {
        self.tryUpdateBlock(block: newBlock)
    }
    
}

//MARK: UITableViewDelegate
extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .boards:
            return BoardsCell.cellHeight
        case .images:
            if let cell = self.attachmentsCell {
                return cell.totalHeight
            }
            return 0
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        if sections[section-1] == .text{
            
            if sections[section] == .todo {
                
                return CGFloat.leastNormalMagnitude
            }
            if sections[section] == .images {
                
                return  4
            }
        }
        
        let spacing:CGFloat = 14
        switch sections[section] {
        case .todo:
            return 6
        case .text:
            return spacing
        default:
            return spacing
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todo:
            return 34
        case .text:
            return CGFloat.leastNormalMagnitude
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todo:
            return true
        default:
            return false
        }
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromSection = sourceIndexPath.section
        //        let toSection = destinationIndexPath.section
        
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        
        swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
    }
    
    private func calcNextTodoBlockSort(newTodoIndex:Int) -> Double {
        let todoBlocks = note.todoBlocks
        let sort = { () -> Double in
            if todoBlocks.isEmpty {
                return 65536
            }
            if newTodoIndex == 0 {
                return todoBlocks[newTodoIndex].sort/2
            }
            if newTodoIndex > todoBlocks.count - 1 {
                return todoBlocks[todoBlocks.count-1].sort + 65536
            }
            return (todoBlocks[newTodoIndex].sort + todoBlocks[newTodoIndex-1].sort) / 2
        }()
        return sort
    }
    
    func swapRowInSameSection(section:Int,fromRow:Int,toRow:Int) {
        
        // 计算 sort
        let sort = self.calcNextTodoBlockSort(newTodoIndex: toRow)
        
        var todoBlock = self.note.todoBlocks[fromRow]
        todoBlock.sort = sort
        
        self.tryUpdateBlock(block: todoBlock)
        self.note.todoBlocks.remove(at: fromRow)
        self.note.todoBlocks.insert(todoBlock, at: toRow)
        
        self.note.todoBlocks.forEach {
            Logger.info("\($0.text)  \($0.sort)")
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        //        if case .todoToggle  = self.sections[destSection]  {
        //            if proposedDestinationIndexPath.row == 0 { // 第 0 行是 title
        //                return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
        //            }
        //            return proposedDestinationIndexPath
        //        }
        //
        
        // 跨 section
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
            }
            
            var contentInset = self.tableView.contentInset
            contentInset.bottom = rect.height + bottomExtraSpace + TodoGroupCell.CELL_HEIGHT
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
            
            self.bottombar.isKeyboardShow = true
            
            // 显示完成按钮
//            self.navigationItem.rightBarButtonItem = completeBtn
            
            
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
            
            
            self.bottombar.isKeyboardShow = false
//            self.navigationItem.rightBarButtonItem =  nil
        }
    }
}

// MARK: Repo handler
extension EditorViewController {
    private func deleteNote() {
        noteRepo.deleteNote(noteId: note.id)
            .subscribe(onNext: { [weak self] _  in
                if let self = self {
                    self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: self.note))
                }
                },onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func tryUpdateBlock(block:Block,completion: (()->Void)? = nil) {
        noteRepo.updateBlock(block: block)
            .subscribe(onNext: { [weak self] updatedBlock in
                guard let self = self else { return }
                self.note.updateBlock(block: updatedBlock)
                if let completion = completion {
                    completion()
                    return
                }
                }, onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func tryDeleteTodoBlock(block:Block) {
        if self.note.todoBlocks.count == 1 {
            self.deleteRootTodoBlock()
            return
        }
        
        noteRepo.deleteBlock(block: block)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                guard let index = self.note.getTodoBlockIndex(todoBlock: block) else { return }
                
                self.note.removeBlock(block: block)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: self.todoSectionIndex)], with: .automatic)
                }, completion: { _ in
                    
                })
                
                
                }, onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func deleteRootTodoBlock() {
        
        guard let rootTodoBlock = self.note.rootTodoBlock else { return }
        noteRepo.deleteBlock(block: rootTodoBlock)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.note.removeBlock(block: rootTodoBlock)
                
                let todoSectionIndex = self.todoSectionIndex
                self.sections.remove(at: todoSectionIndex)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteSections(IndexSet([todoSectionIndex]), with: .automatic)
                }, completion: nil)
                }, onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
        
    }
    
    private func createBlock(block:Block,callback:((Block)->Void)?) {
        
        noteRepo.createBlock(block: block)
            .subscribe(onNext: { newBlock in
                self.note.addBlock(block: newBlock)
                callback?(newBlock)
            },onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: 相册
extension EditorViewController: TLPhotosPickerViewControllerDelegate {
    
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    
    func handlePicker(images: [TLPHAsset]) {
        self.showHud()
        noteRepo.createImageBlocks(noteId: self.note.id, images: images, success: { [weak self] imageBlocks in
            if let self = self {
                self.hideHUD()
                self.handleSectionImage(imageBlocks: imageBlocks)
            }
        }) { [weak self]  in
            self?.hideHUD()
        }
    }
    
    private func handleSectionImage(imageBlocks:[Block]) {
        if  let imagesCell = self.attachmentsCell {
            //附加
            self.note.addImageBlocks(imageBlocks)
            let insertionIndices = imageBlocks.enumerated().map { (index,_) in return index }
            // 刷新 collection
            imagesCell.handleDataChanged(insertionIndices: insertionIndices, insertedImages: imageBlocks)
            return
        }
        
        self.sections.append(SectionType.images)
        self.note.addImageBlocks(imageBlocks)
        let sectionIndex = self.sections.count - 1
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([sectionIndex]), with: .bottom)
        }, completion: nil)
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
        noteRepo.createImageBlocks(noteId: self.note.id, image: image, success: { [weak self] imageBlock in
            if let self = self {
                self.hideHUD()
                self.handleSectionImage(imageBlocks: [imageBlock])
            }
        }) { [weak self]  in
            self?.hideHUD()
        }
    }
    
    
}

//MARK: title textfield delegate
extension EditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.titleTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let title = textField.text ?? ""
        if  title != note.rootBlock.text {
            
            if  var titleBlock = note.rootBlock {
                titleBlock.text = title
                self.tryUpdateBlock(block: titleBlock)
            }
        }
        return true
    }
    
}


private enum SectionType {
    case boards
    case text
    case todo
    case images
}

fileprivate enum CellReuseIdentifier: String {
    case boards = "boards"
    case title = "title"
    case text = "text"
    case todo = "todo"
    case images = "images"
}

fileprivate enum TodoMode {
    case unchecked
    case checked
}


enum CreateMode {
    case text
    case todo
    case images(blocks:[Block])
}
