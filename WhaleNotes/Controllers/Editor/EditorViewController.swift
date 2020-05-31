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
    case insert(noteInfo:NoteInfo)
    case update(noteInfo:NoteInfo)
    case delete(noteInfo:NoteInfo)
}

enum EditorMode {
    case browser(noteInfo:NoteInfo)
    case create(noteInfo:NoteInfo)
    case delete(noteInfo:NoteInfo)
}

class EditorViewController: UIViewController {
    
    static let space: CGFloat = 14
    let bottombarHeight: CGFloat = 42.0
    let bottomExtraSpace: CGFloat = 42.0 + 10
    
    
    private var titleCell:TitleBlockCell?
    private var textCell: TextBlockCell?
    //    private var todoBlockCell: TodoBlockCell?
    
    private var attachmentsCell: AttachmentsBlockCell?
    
    
    var callbackNoteUpdate : ((EditorUpdateMode) -> Void)?
    
    private let usecase = EditorUseCase()
    
    
    // 索引
    private var noteInfo: NoteInfo!{
        didSet {
            self.note = noteInfo.note
        }
    }
    
    private var note: Note2!
    private var oldUpdatedAt:Date!
    
    var mode: EditorMode! {
        didSet {
            switch mode {
            case .browser(let noteInfo):
                self.noteInfo = noteInfo
                oldUpdatedAt = noteInfo.note.updatedAt
            case .create(let noteInfo):
                self.noteInfo = noteInfo
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
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: CellReuseIdentifier.todos.rawValue)
        $0.register(TodoGroupCell.self, forCellReuseIdentifier: CellReuseIdentifier.todos_group.rawValue)
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
                if noteInfo.isContentEmpry {
                    usecase.deleteNote(noteId: note.id) { isSuccess in
                        self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: self.noteInfo))
                    }
                    return
                }
                self.callbackNoteUpdate?(EditorUpdateMode.update(noteInfo: self.noteInfo))
            }
            break
        case .create:
            if noteInfo.isContentEmpry {
                usecase.deleteNote(noteId: note.id) { isSuccess in
                    self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: self.noteInfo))
                }
                return
            }
            self.callbackNoteUpdate?(EditorUpdateMode.insert(noteInfo: self.noteInfo))
        case .delete:
            self.callbackNoteUpdate?(EditorUpdateMode.delete(noteInfo: self.noteInfo))
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
        let sectionIndex = 1
        
        usecase.createBlock(block: Block2.newTextBlock(noteId: self.noteInfo.note.id)) { newBlock in
            self.noteInfo.addBlock(block: newBlock)
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
        // 新增 textblock
        //        DBManager.sharedInstance.update(note: note) {
        //            isNoteUpdated = true
        //            note.textBlock = Block.newTextBlock()
        //        }
    }
    
    fileprivate func handleTodoBlock() {
        
        let sectionIndex = self.getTodoInsertedIndex()
        
        let blockInfo = BlockInfo(block: Block2.newTodoBlock(text: "清单",noteId: self.noteInfo.note.id,sort: Double(sectionIndex)),
                                  childBlocks: [Block2.newTodoBlock()])
        usecase.createBlockInfo(blockInfo: blockInfo) { [weak self] newBlockInfo in
            guard let self = self else { return }
            self.noteInfo.addBlockInfo(blocksInfo: newBlockInfo)
            
            // 增加一个 section
            self.sections.insert(SectionType.todos(groupBlockId: newBlockInfo.id), at: sectionIndex)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet([sectionIndex]), with: .bottom)
            }) { _ in
                
            }
        }
        
    }
    
    fileprivate func getTodoInsertedIndex() -> Int {
        if let lastTodoSectionIndex = self.sections.lastIndex(where: { sectionType in
            if case .todos = sectionType {
                return true
            }
            return false
            
        }) {
            return lastTodoSectionIndex + 1
        }
        var todoInsertedIndex = 0
        if self.noteInfo.titleBlock != nil {
            todoInsertedIndex += 1
        }
        if self.noteInfo.textBlock != nil {
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
        if let _ = noteInfo.textBlock {
            self.sections.append(SectionType.text)
        }
        
        if noteInfo.todoBlockInfos.isNotEmpty {
            self.setupTodoSections(todoBlockInfos: noteInfo.todoBlockInfos)
        }
        
        if noteInfo.imageBlocks.isNotEmpty {
            self.sections.append(SectionType.images)
        }
    }
    
    fileprivate func setupTodoSections(todoBlockInfos: [BlockInfo]){
        for todoBlock in todoBlockInfos {
            self.sections.append(SectionType.todos(groupBlockId: todoBlock.id))
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
    
    
    
    func getTodoBlockInfo(sectionIndex:Int) -> BlockInfo {
        var index = sectionIndex
        index -= 1
        if noteInfo.textBlock != nil {
            index -= 1
        }
        
        return self.noteInfo.todoBlockInfos[index]
    }
    
    func getSectionIndexByBlock(block:Block2) -> Int{
        
        switch block.type {
        case BlockType.title.rawValue:
            return 0
        case BlockType.text.rawValue:
            return 1
        case BlockType.todo.rawValue:
            var section = 1
            if noteInfo.textBlock != nil {
                section += 1
            }
            if let row =  self.noteInfo.todoBlockInfos.firstIndex(where: {$0.id == block.blockId}){
                return row + section
            }
            return section
        default:
            return 0
        }
        
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .todos:
            let todoBlockInfo = self.getTodoBlockInfo(sectionIndex: section)
            if todoBlockInfo.block.isExpand {
                return todoBlockInfo.childBlocks.count + 1
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
        case .todos:
            return indexPath.row == 0 ? CellReuseIdentifier.todos_group.rawValue : CellReuseIdentifier.todos.rawValue
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionObj = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier:getCellIdentifier(sectionType: sectionObj, indexPath: indexPath), for: indexPath)
        switch sectionObj {
        case .title:
            let titleCell = (cell as! TitleBlockCell).then {
                $0.noteInfo = noteInfo
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
            textCell.note = noteInfo
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
        case .todos(let groupBlockId):
            let todoBlockInfo = self.noteInfo.mapTodoBlockInfos[groupBlockId]!
            if indexPath.row == 0 { // group cell
                let todoGroupCell = cell as! TodoGroupCell
                todoGroupCell.todoGroupBlock = todoBlockInfo.block
                setupTodoGroupCell(todoGroupCell: todoGroupCell)
            }else {
                let todoBlock = todoBlockInfo.childBlocks[indexPath.row-1]
                let todoCell = cell as! TodoBlockCell
                todoCell.todoBlock = todoBlock
                todoCell.note = noteInfo
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
            imagesCell.note = self.note
            self.attachmentsCell = imagesCell
            break
        }
        return cell
    }
    
    fileprivate func handleTodoEnterKeyTapped(block:Block2) {
        
        let section:Int = self.getSectionIndexByBlock(block: block)
        
        if block.text.isEmpty { // 删除
            self.tryDeleteBlock(block: block)
        }else { // 新增
            guard let row = self.noteInfo.mapTodoBlockInfos[block.blockId]?.childBlocks.firstIndex(where: {$0.id == block.id}) else { return }
            
            // 先更新
            self.tryUpdateBlock(block: block) {
                //新增
                let nextIndexPath = IndexPath(row: row+2, section: section)
                self.createNewTodoBlock(noteId: block.noteId, groupBlockId: block.blockId, targetIndex: nextIndexPath)
            }
        }
    }
    
    fileprivate func tryUpdateBlock(block:Block2,completion:(()->Void)? = nil) {
        usecase.updateBlock(block: block) { _ in
            self.noteInfo.updateBlock(block: block)
            completion?()
        }
    }
    
    
    fileprivate func tryDeleteBlock(block:Block2) {
        usecase.deleteBlock(block: block) { [weak self] (isSuccess) in
            guard let self = self else { return }
            
            let section = self.getSectionIndexByBlock(block: block)
            guard let row = self.noteInfo.mapTodoBlockInfos[block.blockId]?.childBlocks.firstIndex(where: {$0.id == block.id}) else { return }
            
            self.noteInfo.removeBlock(block: block)
            let indexPath = IndexPath(row: row+1, section: section)
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                //获取焦点
            })
        }
    }
    
    
    fileprivate func setupTodoGroupCell(todoGroupCell: TodoGroupCell) {
        todoGroupCell.arrowButtonTapped = { todoGroupBlock in
            self.expandOrFoldTodoSection(todoGroupBlock:todoGroupBlock)
        }
        todoGroupCell.menuButtonTapped = { btn,todoGroupBlock in
            let items = [
                ContextMenuItem(label: "删除", icon: "trash")
            ]
            
            ContextMenuViewController.show(sourceView: btn, sourceVC: self, items: items) { [weak self] menuItem in
                self?.deleteSection(todoGroupBlock: todoGroupBlock)
                
            }
        }
    }
    fileprivate func expandOrFoldTodoSection(todoGroupBlock:Block2) {
        guard let todoSectionIndex = self.sections.firstIndex(where: { sectionType in
            if case .todos(let todoBlockId) = sectionType {
                return todoBlockId == todoGroupBlock.id
            }
            return false
        }) else { return }
        
        var newBlock = todoGroupBlock
        newBlock.isExpand = !newBlock.isExpand
        usecase.updateBlock(block: newBlock) {_ in
            self.noteInfo.updateBlock(block: newBlock)
            self.tableView.performBatchUpdates({
                self.tableView.reloadSections(IndexSet([todoSectionIndex]), with: .automatic)
            },completion: nil)
        }
        
        //        usecase.deleteBlock(block: todoGroupBlock) { isSuccess  in
        //             if isSuccess {
        //                 self.noteInfo.removeBlock(block: todoGroupBlock)
        //                 self.sections.remove(at: todoSectionIndex)
        //                 self.tableView.performBatchUpdates({
        //                     self.tableView.deleteSections(IndexSet([todoSectionIndex]), with: .bottom)
        //                 }, completion: nil)
        //             }
        //         }
    }
    
    fileprivate func deleteSection(todoGroupBlock:Block2) {
        
        guard let todoSectionIndex = self.sections.firstIndex(where: { sectionType in
            if case .todos(let todoBlockId) = sectionType {
                return todoBlockId == todoGroupBlock.id
            }
            return false
        }) else { return }
        
        usecase.deleteBlock(block: todoGroupBlock) { isSuccess  in
            if isSuccess {
                self.noteInfo.removeBlock(block: todoGroupBlock)
                self.sections.remove(at: todoSectionIndex)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteSections(IndexSet([todoSectionIndex]), with: .bottom)
                }, completion: nil)
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
        case .todos(let groupBlockId):
            let todoFooterView = TodoFooterView()
            todoFooterView.addButtonTapped = { [weak self] in
                guard let self = self else { return }
                guard let  todoBlockInfo = self.noteInfo.mapTodoBlockInfos[groupBlockId] else { return }
                let nextIndexPath = IndexPath(row: todoBlockInfo.childBlocks.count+1, section: section)
                self.createNewTodoBlock(noteId: todoBlockInfo.noteId, groupBlockId: todoBlockInfo.id, targetIndex: nextIndexPath)
            }
            return todoFooterView
        default:
            return nil
        }
    }
    
    private func calcNewSort(groupBlockId:Int64,newRowIndex:Int) -> Double {
        guard let todoBlocks = noteInfo.mapTodoBlockInfos[groupBlockId] else { return 0 }
        let rightIndex = newRowIndex - 1
        
        let sort = { () -> Double in
            if todoBlocks.childBlocks.isEmpty {
                return 65536
            }
            // 第一个
            if rightIndex == 0 {
                return todoBlocks.childBlocks[rightIndex].sort/2
            }
            // 尾部
            if rightIndex >= todoBlocks.childBlocks.count {
                return todoBlocks.childBlocks[todoBlocks.childBlocks.count-1].sort + 65536
            }
            // mid
            return (todoBlocks.childBlocks[rightIndex].sort + todoBlocks.childBlocks[rightIndex-1].sort) / 2
        }()
        
        return sort
    }
    
    private func createNewTodoBlock(noteId:Int64,groupBlockId:Int64,targetIndex:IndexPath) {
        
        let sort = calcNewSort(groupBlockId: groupBlockId, newRowIndex: targetIndex.row)
        
        // 新增
        let todoBlock = Block2.newTodoBlock(text: "", noteId: noteId, parent: groupBlockId,sort: sort)
        usecase.createBlock(block: todoBlock) { newBlock in
            // 更新数据源
            self.noteInfo.addBlock(block: newBlock)
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [targetIndex], with: .automatic)
            }, completion: { _ in
                //获取焦点
                if let cell = self.tableView.cellForRow(at:targetIndex) as? TodoBlockCell {
                    cell.textView.becomeFirstResponder()
                }
                
                
            })
            
        }
    }
    
}


extension EditorViewController: TodoBlockCellDelegate {
    func textDidChange() {
         DispatchQueue.main.async {
                   UIView.performWithoutAnimation {[weak self] in
                       self?.tableView.beginUpdates()
                       self?.tableView.endUpdates()
                   }
               }
    }
    
    func todoBlockEnterKeyInput(newBlock: Block2) {
        self.handleTodoEnterKeyTapped(block:newBlock)
    }
    
    func todoBlockNeedDelete(newBlock: Block2) {
        self.tryDeleteBlock(block: newBlock)
    }
    
    func todoBlockContentChange(newBlock: Block2) {
        self.tryUpdateBlock(block: newBlock)
    }
    
}

extension EditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .images:
            return attachmentsCell?.totalHeight ?? 0
        case .todos:
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
        case .todos:
            let sectionPreIndex = section - 1
            let preSectionType =  self.sections[sectionPreIndex]
            switch preSectionType {
            case .title:
                return 2
            case .todos:
                let todoBlockInfo = self.getTodoBlockInfo(sectionIndex: section)
                return todoBlockInfo.block.isExpand ? 0 : 0
            default:
                return 10
            }
        case .images:
            //            let sectionPreIndex = section - 1
            //            if self.sections[sectionPreIndex].identifier == "todo" {
            //                return 16
            //            }
            return 18
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .todos:
            let todoBlockInfo = self.getTodoBlockInfo(sectionIndex: section)
            return todoBlockInfo.block.isExpand ? 30 : CGFloat.leastNormalMagnitude
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .todos:
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
        
        var blockInfo:BlockInfo?
        if case .todos(let groupBlockId) =  self.sections[section] {
            blockInfo = self.noteInfo.mapTodoBlockInfos[groupBlockId]
        }
        guard let todoBlockInfo = blockInfo else { return }
        
        // 重新计算 index
        let sort = calcNewSort(groupBlockId: todoBlockInfo.id, newRowIndex: toRow)
        //        if sort <= 10 { // 重排
        //            var blocks = todoBlockInfo.childBlocks
        //            blocks.swapAt(fromRow, toRow)
        //            var blockIdAndSorts:[Int64:Double] = [:]
        //            for (index,block) in blocks.enumerated() {
        //                blockIdAndSorts[block.id] = Double((index+1) * 65536)
        //            }
        //            return
        //        }
        
        var todoBlock = todoBlockInfo.childBlocks[fromRow-1]
        todoBlock.sort = sort
        self.tryUpdateBlock(block: todoBlock)
    }
    
    func swapRowCrossSection(fromSection:Int,toSection:Int,fromRow:Int,toRow:Int) {
        
        var blockInfo:BlockInfo?
        if case .todos(let groupBlockId) =  self.sections[fromSection] {
            blockInfo = self.noteInfo.mapTodoBlockInfos[groupBlockId]
        }
        guard let fromTodoBlockInfo = blockInfo else { return }
        
        if case .todos(let groupBlockId) =  self.sections[toSection] {
            blockInfo = self.noteInfo.mapTodoBlockInfos[groupBlockId]
        }
        guard let toTodoBlockInfo = blockInfo else { return }
        
        
        let fromTodoBlock = fromTodoBlockInfo.childBlocks[fromRow-1]
        
        var newTodoBlock = fromTodoBlockInfo.childBlocks[fromRow-1]
        
        let sort = calcNewSort(groupBlockId: toTodoBlockInfo.id, newRowIndex: toRow)
        newTodoBlock.sort = sort
        newTodoBlock.blockId = toTodoBlockInfo.id
        
        usecase.updateBlock(block: newTodoBlock) { isSuccess in
            self.noteInfo.removeBlock(block: fromTodoBlock)
            self.noteInfo.addBlock(block: newTodoBlock)
        }
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        if case .todos = self.sections[destSection]  {
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
//        Observable<[TLPHAsset]>.just(images)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(images)  -> [Block] in
//                var imageBlocks:[Block] = []
//                images.forEach {
//                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
//                        let imageName =  $0.uuidName
//                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
//                        if success {
//                            imageBlocks.append(Block.newImageBlock(imageUrl: imageName))
//                        }
//                    }
//                }
//                return imageBlocks
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe {
//                self.hideHUD()
//                //                if let blocks  = $0.element {
//                //                    DBManager.sharedInstance.update(note: self.note) {
//                //                        self.note.attachBlocks.append(objectsIn: blocks)
//                //                    }
//                //                }
//        }
//        .disposed(by: disposeBag)
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
//        Observable<UIImage>.just(image)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(image)  -> [Block] in
//                let imageName = UUID().uuidString+".png"
//                if let rightImage = image.fixedOrientation() {
//                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
//                    if success {
//                        return [Block.newImageBlock(imageUrl: imageName)]
//                    }
//                }
//                return []
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe {
//                self.hideHUD()
//                //                if let blocks  = $0.element {
//                //                    DBManager.sharedInstance.update(note: self.note) {
//                //                        self.note.attachBlocks.append(objectsIn: blocks)
//                //                    }
//                //                }
//        }
//        .disposed(by: disposeBag)
    }
    
    
}



enum SectionType {
    case title
    case text
    case todos(groupBlockId:Int64)
    case images
    
    
}

enum CellReuseIdentifier: String {
    case title = "title"
    case text = "text"
    case todos = "todos"
    case todos_group = "todos_group"
    case images = "images"
}

enum TodoMode {
    case unchecked
    case checked
}


enum CreateMode {
    case text
    case todo
    case images(blocks:[Block2])
}
