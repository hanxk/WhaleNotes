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
    case updated(noteInfo:NoteInfo)
    case deleted(noteInfo:NoteInfo)
    case moved(noteInfo:NoteInfo,boardBlock:BlockInfo)
    case archived(noteInfo:NoteInfo)
    case trashed(noteInfo:NoteInfo)
}

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 16
    let bottombarHeight: CGFloat = 42.0
    let topExtraSpace: CGFloat =  10
    let bottomExtraSpace: CGFloat = 42.0
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    var disposebag = DisposeBag()
    
    private var attachmentsCell: AttachmentsBlockCell?
    var callbackNoteUpdate : ((EditorUpdateEvent) -> Void)?
    
    
    private var columnCount:Int {
        return atachmentsBlocks.count > 1 ? 2 : 1
    }
    private var imageWidth:CGFloat {
        get {
            let cellCountPerRow = CGFloat(columnCount)
            let fullWidth = UIScreen.main.bounds.size.width - EditorViewController.space*2
            let width: CGFloat  = (fullWidth - AttachmentsConstants.cellSpace*(cellCountPerRow-1)) / cellCountPerRow
            return width
        }
    }
    private var imageTotalHeight:CGFloat = 0
    
    // 索引
    var note: NoteInfo!
    var isNew:Bool = false
    
    var todoSectionIndex:Int {
        return self.note.textBlock == nil ? 0 : 1
    }
    
    var attachSectionIndex:Int {
        return self.sections.count - 1
    }
    
    private var atachmentsBlocks:[BlockInfo] {
        return note.attachmentGroupBlock?.contentBlocks ?? []
    }
    
    private var todoBlocks:[BlockInfo] {
        return note.todoGroupBlock?.contentBlocks ?? []
    }
    
    
    private lazy  var noteInfoModel:NoteEidtorMenuModel = {
        let noteInfoModel = NoteEidtorMenuModel(model: note)
        noteInfoModel.noteInfoPub.subscribe(onNext: { event in
            self.handleNoteInfoEvent(event: event)
        }).disposed(by: disposeBag)
        return noteInfoModel
    }()
    
    private var bg:NoteBackground! {
        didSet {
            let bgColor = bg.uicolor
            bottombar.backgroundColor = bgColor
            self.navigationItem.titleView = titleTextField
            navigationController?.navigationBar.barTintColor = bgColor
            self.view.backgroundColor =  bgColor
        }
    }
    
    private var oldUpdatedAt:Date!
    private var isCancelNotify:Bool = false
    
    
    private var todoRowIndexMap:[Int:(Int,Int)] = [:]
    
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
        
        
        self.bg = note.properties.backgroundColor
        updateAt = self.note.updatedAt
    }
    @objc func rotated() {
        //        self.attachmentsCell?.handleScreenRotation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
        self.hideKeyboard()
        tryNotifiNoteUpdated()
    }
    
    
    private func tryNotifiNoteUpdated() {
        if isCancelNotify { return }
        if self.oldUpdatedAt != note.updatedAt{
            self.callbackNoteUpdate?(EditorUpdateEvent.updated(noteInfo: self.note))
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
        
        self.registerTableViewTaped()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setFirstResponder()
        
    }
    
    private func setFirstResponder() {
        if !self.isNew { return }
        let section = self.sections.count-1
        let sectionType = self.sections[section]
        
        switch sectionType {
        case .todo:
            if let cell = tableView.cellForRow(at:IndexPath(row: 0, section: section)) as? TodoBlockCell {
                cell.textView.becomeFirstResponder()
            }
            break
        case .text:
            if let cell = tableView.cellForRow(at:IndexPath(row: 0, section: section)) as? TextBlockCell {
                cell.textView.becomeFirstResponder()
            }
            break
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

extension EditorViewController {
    
    
    func noteMenuDataMoved(note: NoteInfo) {
        self.navigationController?.popViewController(animated: true)
        //        self.callbackNoteUpdate?(EditorUpdateMode.moved(noteInfo: note))
    }
    
    @objc func handleMoreButtonTapped(sender: UIButton) {
        let noteMenuVC = NoteMenuViewController()
        noteMenuVC.note = note
        noteMenuVC.mode = note.status == .trash ? .trash : .detail
        noteMenuVC.callback = self.handleMenuTapped
        noteMenuVC.showContextMenu(sourceView: sender)
    }
    
    
    private func handleMenuTapped(menuType:NoteEditorAction) {
        
        switch menuType {
        case .pin:
            break
        case .archive:
            noteInfoModel.update(status: .archive)
            break
        case .move:
            self.openChooseBoardVC()
            break
        case .background:
            self.openChooseBackgroundVC()
            break
        case .trash:
            noteInfoModel.update(status: .trash)
            break
        case .deleteBlock:
            break
        case .restore:
            noteInfoModel.update(status: .normal)
            break
        case .delete:
            self.showDeleteBlockTip(tip: "便签") {
                self.noteInfoModel.delete()
            }
            break
        }
    }
    
    
    @objc func handleKeyboardButtonTapped(sender: UIButton) {
        self.hideKeyboard()
    }
    
    
    func noteBlockDelete(blockType: BlockType) {
        switch blockType {
        case .text:
            self.showDeleteBlockTip(tip: "文本") {
                self.deleteTextBlock()
            }
        case .todo:
            self.showDeleteBlockTip(tip: "待办事项") {
                self.deleteRootTodoBlock()
            }
        case .image:
            self.showDeleteBlockTip(tip: "图片") {
                self.deleteImageBlocks()
            }
        default:
            break
        }
    }
    private func showDeleteBlockTip(tip:String,callback: @escaping ()->Void) {
        let alert = UIAlertController(title: "删除\(tip)", message: "删除后内容将不能够被恢复,确认要删除吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确认删除", style: .destructive, handler: { _ in
            callback()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
}

//MARK: 添加 block
extension EditorViewController {
    
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
            self.createTextBlock()
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
        case .bookmark:
            break;
        }
    }
    
    fileprivate func createTextBlock() {
        if let textCell = textCell {
            textCell.textView.becomeFirstResponder()
            return
        }
        let textBlockInfo = Block.text(parentId: self.note.id, position: BlockConstants.position/3)
        self.insertBlockInfo(textBlockInfo)
    }
    
    private func insertBlockInfo(_ blockInfo:BlockInfo) {
        NoteRepo.shared.createBlockInfo(blockInfo: blockInfo)
            .subscribe {
                self.handleBlockInfoInserted($0)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
        
    }
    
    private func handleBlockInfoInserted(_ blockInfo:BlockInfo) {
        self.note.update(blockInfo: blockInfo)
        switch blockInfo.type {
        case .text:
            self.handleSectionInserted(sectionType: SectionType.text)
            break
        case .todo:
            break
        case .image:
            break
        case .group:
            let tag = NoteInfoGroupTag.init(rawValue: blockInfo.groupProperties!.tag)!
            switch tag {
            case .todo:
                self.handleSectionInserted(sectionType: SectionType.todo)
            case .attachment:
                self.handleSectionInserted(sectionType: SectionType.attachment)
            }
        default:
            break
        }
    }
    
    private func handleSectionInserted(sectionType:SectionType) {
        switch sectionType {
        case .text:
            self.sections.insert(sectionType, at: 0)
        case .todo:
            let index = self.sections.contains(.text) ? 1 : 0
            self.sections.insert(sectionType, at: index)
        case .attachment:
            self.sections.insert(sectionType, at: self.sections.count)
        }
        
        guard let insertedSection = self.sections.firstIndex(of: sectionType) else { return }
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([insertedSection]), with: .none)
        }, completion: { _ in
            // 获取焦点
            if sectionType == .text,
               let cell = self.tableView.cellForRow(at:IndexPath(row: 0, section: insertedSection)) as? TextBlockCell {
                cell.textView.becomeFirstResponder()
                return
            }
            
        })
    }
    
    fileprivate func addTodoSection() {
        // 添加在第一行
        if let todoGroupBlock = note.todoGroupBlock {
            let todoCount = todoGroupBlock.contentBlocks.count
            let position:Double = todoCount == 0 ? BlockConstants.position : (todoGroupBlock.contentBlocks[todoCount-1].position +  BlockConstants.position)
            self.createNewTodoBlock(position: position, insertRow: todoCount)
        }else {
            self.createRootTodoBlock()
        }
    }
}



// 数据处理
extension EditorViewController {
    
    fileprivate func setupData() {
        
        self.setupSectionsTypes()
        self.tableView.reloadData()
        
        bottombar.updatedDateStr =  self.note.updatedAt.formattedYMDHM
        bottombar.addButton.isEnabled = self.note.status != NoteBlockStatus.trash
        
        self.oldUpdatedAt = self.note.updatedAt
        
        self.titleTextField.text = self.note.properties.title
        self.titleTextField.isEnabled = self.note.status != NoteBlockStatus.trash
        
    }
    
    fileprivate func setupSectionsTypes() {
        self.sections.removeAll()
        if let _ = note.textBlock {
            self.sections.append(SectionType.text)
        }
        
        if let _ = note.todoGroupBlock {
            self.sections.append(SectionType.todo)
        }
        
        if let _ = note.attachmentGroupBlock {
            self.sections.append(SectionType.attachment)
            self.imageTotalHeight = self.calculateTotalHeight()
        }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todo:
            return self.todoBlocks.count
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
        case .attachment:
            return CellReuseIdentifier.images.rawValue
        case .todo:
            return CellReuseIdentifier.todo.rawValue
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier:getCellIdentifier(sectionType: sectionObj, indexPath: indexPath), for: indexPath)
        switch sectionObj {
        case .text:
            let textCell = cell as! TextBlockCell
            textCell.title = self.note.textBlock!.blockTextProperties?.title
            textCell.textChanged {[weak tableView] newText in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            textCell.textEndEdit = { [weak self] newText in
                self?.updateText(newText: newText)
            }
            self.textCell = textCell
            break
        case .todo:
            let todoBlock = self.todoBlocks[indexPath.row]
            let todoCell = cell as! TodoBlockCell
            todoCell.todoBlock = todoBlock
            todoCell.backgroundColor = .clear
            todoCell.delegate = self
        case .attachment:
            let imagesCell = cell as! AttachmentsBlockCell
            //            imagesCell.columnCount = self.columnCount
            imagesCell.imageWidth = imageWidth
            imagesCell.heightChanged = { [weak tableView]  in
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            }
            imagesCell.callbackCellTapped  = { indexPath in
                //                let browser = PhotoViewerViewController(note: self.note, pageIndex: indexPath.row)
                //                browser.isFromNoteDetail = true
                //                browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
                //                    let path = IndexPath(item: index, section: indexPath.section)
                //                    let cell = imagesCell.collectionView.cellForItem(at: path) as? ImageCell
                //                    return cell?.imageView
                //                })
                //                browser.callbackPhotoBlockDeleted = { newNote  in
                //                    self.handleImageBlocksUpdated(newNote:newNote)
                //                }
                //                browser.show()
                
            }
            imagesCell.reloadData(imageBlocks: self.atachmentsBlocks)
            self.attachmentsCell = imagesCell
        }
        return cell
    }
    
    private func updateText(newText:String) {
        guard var textBlock =  self.note.textBlock,let properties = textBlock.blockTextProperties else { return }
        if properties.title == newText {
            return
        }
        textBlock.updatedAt = Date()
        textBlock.blockTextProperties?.title = newText
        self.note.update(blockInfo: textBlock)
        NoteRepo.shared.updateTitle(id: textBlock.id, title: newText,updatedTimeBlockId: self.note.id)
            .subscribe { _ in
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
    }
    
    private func updateTitle(newTitle:String) {
        self.note.properties.title = newTitle
        self.note.updatedAt = Date()
        NoteRepo.shared.updateTitle(id: self.note.id, title: newTitle,updatedTimeBlockId: self.note.id)
            .subscribe { _ in
                self.note.update(blockInfo: self.note.noteBlock)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
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
                self.deleteBlockInfo(blockInfo: self.todoBlocks[indexPath.row])
            }
            
            let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
    
            return swipeActions
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
                    self?.handleTodoAddButtonTapped()
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
    
    private func handleTodoAddButtonTapped() {
        let lastTodoIndexPath = IndexPath(row: self.todoBlocks.count-1, section:todoSectionIndex)
        if let cell = self.tableView.cellForRow(at: lastTodoIndexPath) as? TodoBlockCell,
           cell.textView.isFirstResponder
           {
            let text = cell.textView.text.trimmingCharacters(in: .whitespaces)
            if text.isEmpty { return }
            cell.handleEnterKeyInput()
            return
        }
        
        let position = (self.todoBlocks.last?.position ?? 0) + BlockConstants.position
        let todoBlockInfo = Block.todo(parentId: self.note.todoGroupBlock!.id, position: position)
        NoteRepo.shared.createBlockInfo(blockInfo: todoBlockInfo)
            .subscribe { _ in
                self.handleTodoInserted(blockInfo: todoBlockInfo, insertRow: self.todoBlocks.count)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)

        
        
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
    
    
    private func createNewTodoBlock(position:Double,insertRow:Int) {

        guard let todoGroupBlock = self.note.todoGroupBlock else { return }
        // 新增
        let todoBlock = Block.todo(parentId: todoGroupBlock.id, position: position)
        
        NoteRepo.shared.createBlockInfo(blockInfo: todoBlock)
            .subscribe {
                self.handleTodoInserted(blockInfo: $0, insertRow: insertRow)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)

    }
    
    
    private func createRootTodoBlock() {
        var todoGroupBlock = Block.group(parent: note.id, properties: BlockGroupProperty(tag: NoteInfoGroupTag.todo.rawValue), position: BlockConstants.position / 2)
        
        let todoBlockInfo = Block.todo(parentId: todoGroupBlock.id, position: BlockConstants.position)
        todoGroupBlock.contentBlocks.append(todoBlockInfo)
        
        
        func handleTodoSectionInserted(todoGroupBlock:BlockInfo) {
            self.note.update(blockInfo: todoGroupBlock)
            let indexPath = IndexPath(row: 0, section: todoSectionIndex)
        
            self.sections.insert(.todo, at: indexPath.section)
            self.tableView.performBatchUpdates {
                self.tableView.insertSections(IndexSet([indexPath.section]), with: .none)
            } completion: { _ in
                if let cell = self.tableView.cellForRow(at: indexPath) as? TodoBlockCell {
                    cell.textView.becomeFirstResponder()
                }
            }
        }
        
        NoteRepo.shared.createBlockInfo(blockInfo: todoGroupBlock)
            .subscribe {
                handleTodoSectionInserted(todoGroupBlock: $0)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
    }
    
}


//MARK: TodoBlockCellDelegate
extension EditorViewController: TodoBlockCellDelegate {
    func textDidChange() {
        self.refreshTableViewHeight()
    }
    
    func todoCheckedChange(newBlock: BlockInfo) {
        self.updateTodoBlockProperties(newBlock: newBlock)
    }
    
    func refreshTableViewHeight() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {[weak self] in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }
        }
    }
    
    func todoBlockEnterKeyInput(newBlock: BlockInfo) {
        self.handleTodoEnterKeyTapped(newBlock:newBlock)
    }
    
    func todoBlockNeedDelete(newBlock: BlockInfo) {
        self.deleteBlockInfo(blockInfo:newBlock)
    }
    
    func todoBlockContentChange(newBlock: BlockInfo) {
        self.updateTodoBlockProperties(newBlock: newBlock)
    }
    
    private func updateTodoBlockProperties(newBlock: BlockInfo) {
        self.note.update(blockInfo: newBlock)
        NoteRepo.shared.updateProperties(id: newBlock.id, properties: newBlock.blockTodoProperties, updatedTimeBlockId: newBlock.block.parentId)
            .subscribe { _ in
            } onError: {
                Logger.error($0)
            }.disposed(by: disposebag)
    }
    
    
    fileprivate func handleTodoEnterKeyTapped(newBlock:BlockInfo) {
        if newBlock.blockTodoProperties!.title.isEmpty { // 删除
            self.deleteBlockInfo(blockInfo:newBlock)
        }else { // 新增
            self.updateAndCreateNew(updateTodoBlock: newBlock)
        }
    }
    
    private func deleteBlockInfo(blockInfo:BlockInfo) {
        NoteRepo.shared.deleteBlockInfo(blockId: blockInfo.id)
            .subscribe { _ in
                self.handleDeleteBlockInfo(deletedBlockInfo: blockInfo)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
    }
    
    private func handleDeleteBlockInfo(deletedBlockInfo:BlockInfo) {
        switch deletedBlockInfo.type {
        case .todo:
            if let index = self.todoBlocks.firstIndex(of: deletedBlockInfo) {
                note.deleteTodo(index: index)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: todoSectionIndex)], with: .automatic)
                }, completion: nil)
            }
            break
        default:
            break
        }
    }
    
    private func updateAndCreateNew(updateTodoBlock:BlockInfo) {
        guard let row = self.todoBlocks.firstIndex(of: updateTodoBlock) else { return }
        
        let newPos = row == self.todoBlocks.count - 1 ? updateTodoBlock.position + BlockConstants.position : (updateTodoBlock.position + self.todoBlocks[row+1].position) / 2
        
        NoteRepo.shared.updateProperties(id: updateTodoBlock.id, properties: updateTodoBlock.blockTodoProperties, updatedTimeBlockId: updateTodoBlock.block.parentId)
            .flatMap { _ -> Observable<BlockInfo> in
                self.note.update(blockInfo: updateTodoBlock)
                return NoteRepo.shared.createBlockInfo(blockInfo: Block.todo(parentId: updateTodoBlock.block.parentId, position: newPos))
            }
            .subscribe {
                self.handleTodoInserted(blockInfo: $0, insertRow: row+1)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
    }
    
    private func handleTodoInserted(blockInfo:BlockInfo,insertRow:Int) {
        let section = self.note.textBlock == nil ? 0 : 1
        let indexPath = IndexPath(row: insertRow, section: section)
        self.note.insert(blockInfo: blockInfo, at:insertRow)
        self.tableView.performBatchUpdates {
            self.tableView.insertRows(at:[indexPath], with: .automatic)
        } completion: { _ in
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // your code here
            if let cell = self.tableView.cellForRow(at: indexPath) as? TodoBlockCell {
                cell.textView.becomeFirstResponder()
            }
        }
    }
    
}

//MARK: UITableViewDelegate
extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .attachment:
            if self.atachmentsBlocks.isEmpty {
                return 0
            }
            return self.imageTotalHeight
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let param = UIDragPreviewParameters()
        param.backgroundColor = .clear
        return param
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let param = UIDragPreviewParameters()
        param.backgroundColor = .clear
        return param
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        if sections[section-1] == .text{
            
            if sections[section] == .todo {
                
                return CGFloat.leastNormalMagnitude
            }
            if sections[section] == .attachment {
                
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
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
    }
    
    
    private func calcNewPosition(fromRow:Int,toRow:Int) -> Double {
        if toRow == 0 {
            return self.todoBlocks[0].position / 2
        }
        let rowCount = self.todoBlocks.count
        if toRow ==  rowCount - 1 {
            return  self.todoBlocks[rowCount-1].position + BlockConstants.position
        }
        
        if fromRow < toRow {
           return  (self.todoBlocks[toRow+1].position + self.todoBlocks[toRow].position ) / 2
        }
        return  (self.todoBlocks[toRow-1 ].position + self.todoBlocks[toRow].position ) / 2
        
        
    }
    
    func swapRowInSameSection(section:Int,fromRow:Int,toRow:Int) {
        
        let newPos = self.calcNewPosition(fromRow: fromRow, toRow:toRow)
        var movedTodoBlockInfo = self.todoBlocks[fromRow]
        movedTodoBlockInfo.blockPosition.position = newPos
        
        NoteRepo.shared.updatePosition(blockPosition: movedTodoBlockInfo.blockPosition, noteId: self.note.id)
            .subscribe { _ in
                self.note.moveTodo(todoBlock: movedTodoBlockInfo, from: fromRow, to: toRow)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        // 跨 section
        if destSection < sourceSection {
            return IndexPath(row: 0, section: sourceSection)
        } else if destSection > sourceSection {
            return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
        }
        return proposedDestinationIndexPath
    }
}

//MARK: 处理空白区域点击
extension EditorViewController {
    
    private func registerTableViewTaped() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        tapGesture.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc func tableViewTapped(_ sender: UITapGestureRecognizer) {
        
        if sender.state != .ended {
            return
        }
        if self.sections.count == 0 {
            self.handleAddButtonTapped(sender: self.bottombar.addButton)
            return
        }
        
        let touch = sender.location(in: tableView)
        if let _ = tableView.indexPathForRow(at: touch) { // 点击空白区域
            return
        }
        
        
        let section = self.sections.count-1
        let sectionType = self.sections[section]
        switch sectionType {
        case .text:
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? TextBlockCell {
                cell.textView.becomeFirstResponder()
            }
        case .todo:
            if let cell = tableView.cellForRow(at: IndexPath(row: self.todoBlocks.count-1, section: section)) as? TodoBlockCell {
                cell.textView.becomeFirstResponder()
            }
        default:
            break
        }
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
    
    private func deleteNoteBlock(sectionType:SectionType) {
        guard let sectionIndex = self.sections.firstIndex(of: sectionType) else { return }
        var blockInfo:BlockInfo?
        switch sectionType {
        case .text:
            blockInfo = self.note.textBlock
        case .todo:
            blockInfo = self.note.todoGroupBlock
        case .attachment:
            blockInfo = self.note.attachmentGroupBlock
        }
        
        guard let _blockInfo = blockInfo else { return }
        
        NoteRepo.shared.deleteBlockInfo(blockId: _blockInfo.id)
            .subscribe(onNext: { _ in
                handleDeleteSectionBlock()
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
        
        func handleDeleteSectionBlock() {
            self.note.delete(blockInfo: _blockInfo)
            self.sections.remove(at: sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.deleteSections(IndexSet([sectionIndex]), with: .none)
            }, completion: nil)
        }
    }
    
    private func deleteTextBlock() {
        self.deleteNoteBlock(sectionType: .text)
    }
    
    
    private func deleteImageBlocks() {
        self.deleteNoteBlock(sectionType: .attachment)
    }
    
    private func deleteRootTodoBlock() {
      self.deleteNoteBlock(sectionType: .todo)
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
        NoteRepo.shared.saveImages(images: images)
            .subscribe {
                self.addImagesBlocks(imageProperties: $0)
            } onError: {
                Logger.error($0)
            } onCompleted: {
                self.hideHUD()
            }
            .disposed(by: disposebag)
    }
    
    private func addImagesBlocks(imageProperties:[BlockImageProperty]) {
        
        if var imageGroupBlock = self.note.attachmentGroupBlock {
            var position = imageGroupBlock.contentBlocks.isEmpty ?  BlockConstants.position :  imageGroupBlock.contentBlocks[0].position
            let imageBlocks:[BlockInfo] = imageProperties.reversed().map {
                position /=  2
                let position = position
                return Block.image(parent: imageGroupBlock.id, properties:$0,position: position)
            }.reversed()
            imageGroupBlock.contentBlocks.insert(contentsOf: imageBlocks, at: 0)
            NoteRepo.shared.createBlockInfo(blockInfos: imageBlocks,updatedAtId: self.note.id)
                .subscribe {_ in
                    self.handleSectionImage(imageGroupBlock: imageGroupBlock)
                } onError: {
                    Logger.error($0)
                }
                .disposed(by: disposebag)
            
            return
        }
        
        var imageGroupBlock =  Block.group(parent: self.note.id, properties: BlockGroupProperty(tag: NoteInfoGroupTag.attachment.rawValue), position: BlockConstants.position)
        let images:[BlockInfo] = imageProperties.enumerated().map {
            let position = Double($0.offset+1) * BlockConstants.position
            return Block.image(parent: imageGroupBlock.id, properties: $0.element, position: position)
        }
        imageGroupBlock.contentBlocks.append(contentsOf: images)
        
        NoteRepo.shared.createBlockInfo(blockInfo: imageGroupBlock)
            .subscribe {
                self.handleSectionImage(imageGroupBlock: $0)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposebag)
        
        
    }
    
    private func handleSectionImage(imageGroupBlock:BlockInfo) {
        
        if self.note.attachmentGroupBlock != nil {
            
            self.note.update(blockInfo: imageGroupBlock)
            self.imageTotalHeight = self.calculateTotalHeight()
            self.refreshTableViewHeight()
            
            if let imagesCell = self.attachmentsCell {
                imagesCell.handleNewImageBlocksInstered(blockInfos: imageGroupBlock.contentBlocks)
            }
            self.sroll2ImageShow()
            return
        }
        self.note.update(blockInfo: imageGroupBlock)
        self.sections.append(SectionType.attachment)
        self.imageTotalHeight = self.calculateTotalHeight()
        self.refreshTableViewHeight()
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([self.sections.count-1]), with: .none)
        }, completion: nil)
    }
    
    private func sroll2ImageShow() {
        guard  let sectionIndex = sections.firstIndex(where: {$0 == SectionType.attachment}) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Code you want to be delayed
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: sectionIndex), at: .top, animated: true)
        }
    }
}

extension EditorViewController {
    
    private func handleNoteInfoEvent(event:EditorUpdateEvent) {
        self.callbackNoteUpdate?(event)
        switch event {
            case .statusChanged(noteInfo: let noteInfo):
                self.handleNoteStatusChanged(noteInfo)
            case .backgroundChanged(noteInfo: let noteInfo):
                self.handleBackgroundChanged(noteInfo)
            case .moved(let noteInfo,_):
                self.handleNoteMoved(noteInfo)
            case .delete(noteInfo: let noteInfo):
                self.handleNoteDeleted(noteInfo)
            case .updated:
                break
        }
    }
    
    func handleNoteStatusChanged(_ note: NoteInfo) {
        self.note = note
        self.isCancelNotify = true
        self.navigationController?.popViewController(animated: true)
        self.imemPop(note)
    }
    
    func handleNoteMoved(_ note: NoteInfo) {
        self.imemPop(note)
    }
    
    func handleNoteDeleted(_ note: NoteInfo) {
        self.imemPop(note)
    }
    
    private func imemPop(_ note: NoteInfo) {
        self.note = note
        self.isCancelNotify = true
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func handleBackgroundChanged(_ note: NoteInfo) {
        self.note = note
        self.bg = note.properties.backgroundColor
    }
    
    
    private func handleNoteUpdated(newNote:NoteInfo) {
        if newNote.status == .trash ||
            newNote.status == .archive ||
            self.note.parentId != newNote.parentId {
            self.note = newNote
            self.navigationController?.popViewController(animated: true)
            return
        }
        let isChangeBackground = newNote.properties.backgroundColor  != note.properties.backgroundColor
        self.note = newNote
        
        if isChangeBackground {
            
        }
        
    }
    
    private func openChooseBoardVC() {
        let vc = ChangeBoardViewController()
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    private func openChooseBackgroundVC() {
        let colorVC = NoteColorViewController()
        colorVC.callbackColorChoosed = { [weak self] background in
            self?.noteInfoModel.update(background: background)
        }
        let nav = MyNavigationController(rootViewController: colorVC)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = colorVC.self
        self.present(nav, animated: true, completion: nil)
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
        //        noteRepo.createImageBlocks(noteId: self.note.id, image: image, success: { [weak self] imageBlock in
        //            if let self = self {
        //                self.hideHUD()
        //                self.handleSectionImage(imageBlocks: [imageBlock])
        //            }
        //        }) { [weak self]  in
        //            self?.hideHUD()
        //        }
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
        if  title != note.properties.title {
            self.updateTitle(newTitle: title)
        }
        return true
    }
    
}

//MARK: 计算高度
extension EditorViewController {
    
    func calculateTotalHeight() -> CGFloat{
        Logger.info("计算高度啊。。。。。。。。。。。。。。。。。。")
        var cellsHeight:[Int: CGFloat] = {
            var cellsHeight:[Int: CGFloat] = [:]
            for index in 0..<columnCount {
                cellsHeight[index] = 0
            }
            return cellsHeight
        }()
        for (_,block) in self.atachmentsBlocks.enumerated() {
            if let properties = block.blockImageProperties {
                
                let fitHeight = self.imageWidth * CGFloat(properties.height) / CGFloat(properties.width)
                
                let columnIndex = getCurrentMinValueIndex(cellsHeight: cellsHeight)
                let oldHeight = cellsHeight[columnIndex] ?? 0
                let bottomSpace = ((oldHeight == 0) ? CGFloat.zero : AttachmentsConstants.cellSpace)
                cellsHeight[columnIndex] = oldHeight + fitHeight + bottomSpace
            }
            
            
        }
        return cellsHeight.values.max() ?? 0
    }
    
    private func getCurrentMinValueIndex(cellsHeight:[Int: CGFloat] ) -> Int {
        if cellsHeight.count == 0 {
            return 0
        }
        var tempVal = CGFloat.greatestFiniteMagnitude
        var index = 0
        for (cellIndex, columnHeight) in cellsHeight {
            if tempVal > columnHeight {
                tempVal = columnHeight
                index = cellIndex
            }
        }
        return index
    }
    
}


private enum SectionType:Equatable {
    case text
    case todo
    case attachment
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
