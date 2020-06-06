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


enum EditorUpdateMode {
    case insert(noteInfo:Note)
    case update(noteInfo:Note)
    case delete(noteInfo:Note)
}

enum EditorMode {
    case browser(noteInfo:Note)
    case create(noteInfo:Note)
    case delete(noteInfo:Note)
}

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    //    private var todoBlockCell: TodoBlockCell?
    var disposebag = DisposeBag()
    
    
    private var attachmentsCell: AttachmentsBlockCell?
    
    
    var callbackNoteUpdate : ((EditorUpdateMode) -> Void)?
    
    private let noteRepo = NoteRepo()
    
    
    // 索引
    private var note: Note!{
        didSet {
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
    
    var sections:[SectionType] = []
    
    var isTodoExpand = true
    
    var dragIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then { [weak self] in
        
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TitleBlockCell.self, forCellReuseIdentifier:CellReuseIdentifier.title.rawValue)
        $0.register(TextBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.text.rawValue)
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.todo.rawValue)
        $0.register(TodoGroupCell.self, forCellReuseIdentifier: CellReuseIdentifier.todoToggle.rawValue)
        $0.register(AttachmentsBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.images.rawValue)
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
    
    
    
    var keyboardHeight: CGFloat = 0
    var keyboardHeight2: CGFloat = 0
    //    var isNew = false
    private var keyboardIsHide = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupData()
        
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
        
        updateAt = self.note.updatedAt
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
        case .create(let noteInfo):
            if noteInfo.textBlock != nil {
                textCell?.textView.becomeFirstResponder()
            }else if noteInfo.todoToggleBlocks.isNotEmpty {
                self.tryFocusTodoSection()
            }
        default:
            break
        }
    }
    
    private func tryFocusTodoSection() {
        
        guard let sectionIndex = self.sections.firstIndex(where: { sectionType in
            if case .todoToggle = sectionType {
                return true
            }
            return false
            
        }) else {
            return
        }
        
        //获取焦点
        if let cell = self.tableView.cellForRow(at:IndexPath(row: 1, section: sectionIndex)) as? TodoBlockCell {
            cell.textView.becomeFirstResponder()
        }
    }
}

// context menu
extension EditorViewController {
    
    @objc func handleMoreButtonTapped(sender: UIButton) {
        self.view.endEditing(true)
    }
    
    private func moveNote2Trash() {
        //        guard let noteNotificationToken = self.noteNotificationToken else { return }
        //        DBManager.sharedInstance.moveNote2Trash(self.note, withoutNotifying: [noteNotificationToken]) {
        //            self.mode = EditorMode.delete(note: self.note)
        //            self.navigationController?.popViewController(animated: true)
        //        }
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
        let sectionIndex = 1
        self.createBlock(block: Block.newTextBlock(text: "", noteId: self.note.id)) { _ in
            self.sections.insert(SectionType.text, at:1)
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
        
        let sectionIndex = self.getTodoInsertedIndex()
        
        let sort = Double((self.note.todoToggleBlocks.count+1)*65536)
        let toggleBlock = Block.newToggleBlock(noteId: self.note.id, sort: sort)
        noteRepo.createToggleBlock(toggleBlock:toggleBlock) { [weak self] newBlockInfo in
            guard let self = self else { return }
            self.note.addTodoToggleBlock(blockInfo: newBlockInfo)
            
            // 增加一个 section
            self.sections.insert(SectionType.todoToggle(id: newBlockInfo.0.id), at: sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .bottom)
            }) { _ in
                
                //获取焦点
                if let cell = self.tableView.cellForRow(at:IndexPath(row: 1, section: sectionIndex)) as? TodoBlockCell {
                    cell.textView.becomeFirstResponder()
                }
                
            }
        }
        
    }
    
    fileprivate func getTodoInsertedIndex() -> Int {
        if let lastTodoSectionIndex = self.sections.lastIndex(where: { sectionType in
            if case .todoToggle = sectionType {
                return true
            }
            return false
            
        }) {
            return lastTodoSectionIndex + 1
        }
        var todoInsertedIndex = 0
        todoInsertedIndex += 1
        if self.note.textBlock != nil {
            todoInsertedIndex += 1
        }
        return todoInsertedIndex
    }
}


// 数据处理
extension EditorViewController {
    
    fileprivate func setupData() {
        self.setupSectionsTypes()
        self.tableView.reloadData()
    }
    
    fileprivate func setupSectionsTypes() {
        self.sections.append(SectionType.title)
        if let _ = note.textBlock {
            self.sections.append(SectionType.text)
        }
        for todoTogggleBlock in note.todoToggleBlocks {
            self.sections.append(SectionType.todoToggle(id: todoTogggleBlock.id))
        }
        if note.imageBlocks.isNotEmpty {
            self.sections.append(SectionType.images)
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

extension EditorViewController: UITableViewDataSource {
    
    func getSectionIndexByBlock(block:Block) -> Int{
        
        switch block.type {
        case BlockType.note.rawValue:
            return 0
        case BlockType.text.rawValue:
            return 1
        case BlockType.todo.rawValue:
            var section = 1
            if note.textBlock != nil {
                section += 1
            }
            if let row = self.note.todoToggleBlocks.firstIndex(where: {$0.id == block.parent}){
                return row + section
            }
            return 2
        default:
            return 0
        }
        
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todoToggle(let id):
            if self.note.getToggleBlockById(id: id).isExpand {
                return note.getChildTodoBlocks(parent: id).count + 1
            }
            return 1
        default:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func getCellIdentifier(sectionType:SectionType,indexPath:IndexPath) -> String {
        
        switch sectionType {
        case .title:
            return CellReuseIdentifier.title.rawValue
        case .text:
            return CellReuseIdentifier.text.rawValue
        case .images:
            return CellReuseIdentifier.images.rawValue
        case .todoToggle:
            return indexPath.row == 0  ? CellReuseIdentifier.todoToggle.rawValue : CellReuseIdentifier.todo.rawValue
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier:getCellIdentifier(sectionType: sectionObj, indexPath: indexPath), for: indexPath)
        switch sectionObj {
        case .title:
            let titleCell = (cell as! TitleBlockCell).then {
                $0.titleBlock = note.rootBlock
                $0.enterkeyTapped { [weak self] _ in
                    self?.textCell?.textView.becomeFirstResponder()
                }
            }
            titleCell.blockUpdated = { [weak self] block in
                guard let self = self else { return }
                self.tryUpdateBlock(block: block)
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
            textCell.blockUpdated = { [weak self] block in
                guard let self = self else { return }
                self.tryUpdateBlock(block: block)
            }
            self.textCell = textCell
            break
        case .todoToggle(let id):
            if indexPath.row == 0 { // group cell
                let todoGroupCell = cell as! TodoGroupCell
                todoGroupCell.todoGroupBlock = note.getToggleBlockById(id: id)
                todoGroupCell.delegate = self
            }else {
                let todoBlock = note.getChildTodoBlocks(parent:id)[indexPath.row-1]
                let todoCell = cell as! TodoBlockCell
                todoCell.todoBlock = todoBlock
                todoCell.note = note
                todoCell.delegate = self
            }
            break
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
            imagesCell.noteInfo = self.note
            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todoToggle:
            return indexPath.row > 0
        default:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "删除") {  (contextualAction, view, boolValue) in
            
            if case .todoToggle(let id) = self.sections[indexPath.section]
            {
                self.tryDeleteBlock(block: self.note.getChildTodoBlocks(parent: id)[indexPath.row-1])
            }
            
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        
        return swipeActions
    }
    
    fileprivate func handleTodoEnterKeyTapped(block:Block) {
        
        let section:Int = self.getSectionIndexByBlock(block: block)
        
        if block.text.isEmpty { // 删除
            self.tryDeleteBlock(block: block)
        }else { // 新增
            guard let row = self.note.getChildTodoBlocks(parent: block.parent).firstIndex(where: {$0.id == block.id}) else { return }
            
            // 先更新
            self.tryUpdateBlock(block: block) {
                //新增
                let nextIndexPath = IndexPath(row: row+2, section: section)
                self.createNewTodoBlock(todoToggleId: block.parent, targetIndex: nextIndexPath)
            }
        }
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
        case .todoToggle(let id):
            let todoFooterView = TodoFooterView()
            todoFooterView.addButtonTapped = { [weak self] in
                guard let self = self else { return }
                let nextIndexPath = IndexPath(row: self.note.getChildTodoBlocks(parent: id).count + 1, section: section)
                self.createNewTodoBlock(todoToggleId: id, targetIndex: nextIndexPath)
            }
            return todoFooterView
        default:
            return nil
        }
    }
    
    
    private func createNewTodoBlock(todoToggleId:Int64,targetIndex:IndexPath) {
        let sort = calcNewSort(todoToggleId:todoToggleId, newRowIndex: targetIndex.row)
        // 新增
        let todoBlock = Block.newTodoBlock(noteId: self.note.id, parent: todoToggleId,sort: sort)
        self.createBlock(block: todoBlock) { _ in
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [targetIndex], with: .automatic)
            }, completion: { _ in
                //获取焦点
                if let cell = self.tableView.cellForRow(at:targetIndex) as? TodoBlockCell {
                    cell.textView.becomeFirstResponder()
                }
            })
        }    }
    
}


//MARK: TodoBlockCellDelegate
extension EditorViewController: TodoBlockCellDelegate {
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
        self.tryDeleteBlock(block: newBlock)
    }
    
    func todoBlockContentChange(newBlock: Block) {
        self.tryUpdateBlock(block: newBlock)
    }
    
}

//MARK: TodoGroupCellDelegate
extension EditorViewController: TodoGroupCellDelegate {
    func todoGroupArrowButtonTapped(todoGroupBlock: Block) {
        self.expandOrFoldTodoSection(todoGroupBlock:todoGroupBlock)
    }
    
    func todoGroupMenuButtonTapped(menuButton: UIButton, todoGroupBlock: Block) {
        let items = [
            ContextMenuItem(label: "删除", icon: "trash")
        ]
        ContextMenuViewController.show(sourceView: menuButton, sourceVC: self, items: items) { [weak self] menuItem in
            self?.deleteTodoSection(todoGroupBlock: todoGroupBlock)
        }
    }
    
    func todoGroupTextChanged(todoGroupBlock: Block) {
        self.tryUpdateBlock(block: todoGroupBlock)
    }
    
    func todoGroupEnterKeyInput(todoGroupBlock: Block) {
        
        if !todoGroupBlock.isExpand {//先展开
            self.expandOrFoldTodoSection(todoGroupBlock:todoGroupBlock)
        }
        
        // 顶部创建新的 todo
        guard let todoSectionIndex = self.sections.firstIndex(where: { sectionType in
            if case .todoToggle(let id) = sectionType {
                return id == todoGroupBlock.id
            }
            return false
        }) else { return }
        let nextIndexPath = IndexPath(row: 1, section: todoSectionIndex)
        self.createNewTodoBlock( todoToggleId: todoGroupBlock.id, targetIndex: nextIndexPath)
    }
    
    fileprivate func expandOrFoldTodoSection(todoGroupBlock:Block) {
        guard let todoSectionIndex = self.sections.firstIndex(where: { sectionType in
            if case .todoToggle(let id) = sectionType {
                return id == todoGroupBlock.id
            }
            return false
        }) else { return }
        
        var newBlock = todoGroupBlock
        newBlock.isExpand = !newBlock.isExpand
        
        self.tryUpdateBlock(block: newBlock) {
            self.tableView.performBatchUpdates({
                self.tableView.reloadSections(IndexSet([todoSectionIndex]), with: .automatic)
            },completion: nil)
        }
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .images:
            return attachmentsCell?.totalHeight ?? 0
        case .todoToggle:
            return indexPath.row == 0 ? TodoGroupCell.CELL_HEIGHT : UITableView.automaticDimension
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
        case .todoToggle:
            let sectionPreIndex = section - 1
            let preSectionType =  self.sections[sectionPreIndex]
            switch preSectionType {
            case .title:
                return 2
            case .todoToggle(let id):
                let todoToggleBlock = self.note.getToggleBlockById(id: id)
                return todoToggleBlock.isExpand ? 0 : 0
            default:
                return 10
            }
        case .images:
            return 18
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todoToggle(let id):
            let todoToggleBlock = self.note.getToggleBlockById(id: id)
            return todoToggleBlock.isExpand ? 30 : CGFloat.leastNormalMagnitude
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todoToggle:
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
    
    
    private func calcNewSort(todoToggleId:Int64,newRowIndex:Int) -> Double {
        let todoBlocks = note.getChildTodoBlocks(parent: todoToggleId)
        let rightIndex = newRowIndex - 1
        
        let sort = { () -> Double in
            if todoBlocks.isEmpty {
                return 65536
            }
            // 第一个(记得第一个是 group)
            if rightIndex == 0 {
                return todoBlocks[rightIndex].sort/2
            }
            // 尾部
            if rightIndex >= todoBlocks.count - 1 {
                return todoBlocks[todoBlocks.count-1].sort + 65536
            }
            
            
            // mid
            return (todoBlocks[rightIndex].sort + todoBlocks[rightIndex-1].sort) / 2
        }()
        
        return sort
    }
    
    func swapRowInSameSection(section:Int,fromRow:Int,toRow:Int) {
        
        var todoToggleBlock:Block!
        if case .todoToggle(let id) =  self.sections[section] {
            todoToggleBlock =  self.note.getToggleBlockById(id: id)
        }else {
            return
        }
        
        // 重新计算 index
        let sort = calcNewSort(todoToggleId: todoToggleBlock.id, newRowIndex: toRow)
        //        if sort <= 10 { // 重排
        //            var blocks = todoBlockInfo.childBlocks
        //            blocks.swapAt(fromRow, toRow)
        //            var blockIdAndSorts:[Int64:Double] = [:]
        //            for (index,block) in blocks.enumerated() {
        //                blockIdAndSorts[block.id] = Double((index+1) * 65536)
        //            }
        //            return
        //        }
        var todoBlock = self.note.getChildTodoBlocks(parent: todoToggleBlock.id)[fromRow-1]
        todoBlock.sort = sort
        self.tryUpdateBlock(block: todoBlock) {
            //            print("***********************"+String(toRow))
            //            self.noteInfo.todoBlockInfos[0].childBlocks.forEach({
            //                Logger.info(String($0.sort),$0.text)
            //            })
            //            print("***********************")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: toRow, section: section)) as? TodoBlockCell {
                    cell.todoBlock = todoBlock
                }
            }
        }
        
        
    }
    
    func swapRowCrossSection(fromSection:Int,toSection:Int,fromRow:Int,toRow:Int) {
        
        var fromTodoToggleBlock:Block!
        if case .todoToggle(let id) =  self.sections[fromSection] {
            fromTodoToggleBlock =  self.note.getToggleBlockById(id: id)
        }
        
        var toTodoToggleBlock:Block!
        if case .todoToggle(let id) =  self.sections[toSection] {
            toTodoToggleBlock =  self.note.getToggleBlockById(id: id)
        }
        
        
        let fromTodoBlock = self.note.getChildTodoBlocks(parent: fromTodoToggleBlock.id)[fromRow-1]
        var newTodoBlock =  fromTodoBlock
        
        
        let sort = calcNewSort(todoToggleId: toTodoToggleBlock.id, newRowIndex: toRow)
        
        newTodoBlock.sort = sort
        newTodoBlock.parent = toTodoToggleBlock.id
        
        noteRepo.updateBlock(block: newTodoBlock)
            .subscribe(onNext: {[weak self] _ in
                self?.note.removeBlock(block: fromTodoBlock)
                self?.note.addBlock(block: newTodoBlock)
                
                
                }, onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        if case .todoToggle  = self.sections[destSection]  {
            if proposedDestinationIndexPath.row == 0 { // 第 0 行是 title
                return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
            }
            return proposedDestinationIndexPath
        }
        
        // 跨 section
        if destSection < sourceSection {
            return IndexPath(row: 1, section: sourceSection)
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
            contentInset.bottom = rect.height + bottomExtraSpace + TodoGroupCell.CELL_HEIGHT
            
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
    
    private func tryDeleteBlock(block:Block) {
        noteRepo.deleteBlock(block: block)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                let section = self.getSectionIndexByBlock(block: block)
                guard let row = self.note.getChildTodoBlocks(parent: block.parent).firstIndex(where: {$0.id == block.id}) else { return }
                
                self.note.removeBlock(block: block)
                let indexPath = IndexPath(row: row+1, section: section)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }, completion: { _ in
                    
                })
                }, onError: {
                    Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func deleteTodoSection(todoGroupBlock:Block) {
        
        noteRepo.deleteBlock(block: todoGroupBlock)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                let todoSectionIndex = self.getSectionIndexByBlock(block: todoGroupBlock)
                
                self.note.removeBlock(block: todoGroupBlock)
                self.sections.remove(at: todoSectionIndex)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteSections(IndexSet([todoSectionIndex]), with: .bottom)
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
        
        if let imagesCell =  self.attachmentsCell  {
            //附加
            self.note.addImageBlocks(imageBlocks)
            imagesCell.noteInfo = self.note
            let insertionIndices = imageBlocks.enumerated().map { (index,_) in return index }
            
            // 刷新 collection
            imagesCell.handleDataChanged(insertionIndices: insertionIndices)
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



enum SectionType {
    case title
    case text
    case todoToggle(id:Int64)
    case images
}

enum CellReuseIdentifier: String {
    case title = "title"
    case text = "text"
    case todo = "todo"
    case todoToggle = "todo_toggle"
    case images = "images"
}

enum TodoMode {
    case unchecked
    case checked
}


enum CreateMode {
    case text
    case todo
    case images(blocks:[Block])
}
