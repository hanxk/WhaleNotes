//
//  TodoBlockEditorView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoBlockEditorView: BaseCardEditorView {
    
    private var viewModel:CardEditorViewModel!
    var callbackTryHideKeyboard:(()->Void)?
    
    private var todoListBlock:BlockInfo! {
        return viewModel.blockInfo
    }
    private var contents:[BlockInfo]! {
        return todoListBlock.contents
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then { [weak self] in
        $0.estimatedRowHeight = 50
        $0.separatorColor = .clear
        $0.register(TodoBlockCell.self, forCellReuseIdentifier: "TodoBlockCell")
        //        $0.contentInset = UIEdgeInsets(top: topExtraSpace, left: 0, bottom: bottomExtraSpace, right: 0)
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
    
    private var keyboardHeight: CGFloat = 0
    private var keyboardHeight2: CGFloat = 0
    private var keyboardIsHide = true
    let bottombarHeight: CGFloat = 0 //42
    let bottomExtraSpace: CGFloat =  0
    
    init(viewModel:CardEditorViewModel) {
        super.init(frame: .zero)
        self.viewModel = viewModel
        self.initializeUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        self.tableView.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
    }
    
    func todoBecomeFirstResponder() {
        self.tryGetFocus(row: self.contents.count-1)
    }
    
    
    @objc func tableTapped(tap:UITapGestureRecognizer) {
        let location = tap.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: location)
        if path != nil {
            return
        }
        if keyboardIsHide {
            self.createContentAtLast()
        }else {
            self.callbackTryHideKeyboard?()
        }
    }
}


extension TodoBlockEditorView:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoListBlock.contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let todoBlock = self.todoListBlock.contents[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoBlockCell", for: indexPath) as! TodoBlockCell
        cell.todoBlock = todoBlock
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let todoFooterView = TodoFooterView()
        if todoListBlock.block.status != .trash {
            todoFooterView.addButtonTapped = { [weak self] in
                self?.createContentAtLast()
            }
        }
        return todoFooterView
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(style: .destructive, title: "删除") {  (contextualAction, view, boolValue) in
            self.deleteContent(self.contents[indexPath.row])
        }
        
        let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
        
        return swipeActions
    }
    
    
    func refreshTableViewHeight() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {[weak self] in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }
        }
        print("refreshTableViewHeight")
    }
    
    func createContentAtLast() {
        let index = contents.count
        let newPosition = contents.isEmpty ? 65536 : contents[contents.count-1].position + 65536
        let newTodoBlock = Block.todo(parentId: todoListBlock.id, position: newPosition)
        viewModel.createContent(newTodoBlock,index: index) {
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .none)
                self.tryGetFocus(row: index)
            }, completion: nil)
        }
    }
}

extension TodoBlockEditorView:UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 34
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //        if section == 0 {
        //            return CGFloat.leastNormalMagnitude
        //        }
        return CGFloat.leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let fromSection = sourceIndexPath.section
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
    }
}

extension TodoBlockEditorView {
    func swapRowInSameSection(section:Int,fromRow:Int,toRow:Int) {
        let newPos = self.calcNewPosition(fromRow: fromRow, toRow:toRow)
        
        
        var todoBlock = self.contents[fromRow]
        todoBlock.position = newPos
        
        self.viewModel.updatePosition(todoBlock,from: fromRow,to: toRow)
    }
    
    private func calcNewPosition(fromRow:Int,toRow:Int) -> Double {
        if toRow == 0 {
            return self.contents[0].position / 2
        }
        let rowCount = self.contents.count
        if toRow ==  rowCount - 1 {
            return  self.contents[rowCount-1].position + BlockConstants.position
        }

        if fromRow < toRow {
           return  (self.contents[toRow+1].position + self.contents[toRow].position ) / 2
        }
        return  (self.contents[toRow-1 ].position + self.contents[toRow].position ) / 2


    }
}

extension TodoBlockEditorView:TodoBlockCellDelegate {
    func todoCheckChanged(todoBlock: BlockInfo) {
        viewModel.updateContent(todoBlock)
    }
    
    func todoTextChanged() {
        self.refreshTableViewHeight()
    }
    
    func todoEndEditing(todoBlock: BlockInfo) {
        viewModel.updateContent(todoBlock)
    }
    
    func todoEnterKeyInput(todoBlock: BlockInfo) {
        if todoBlock.title.isEmpty { // 删除
            self.deleteContent(todoBlock)
        }else { // 保存 + 新增
            
            guard let index =  contents.firstIndex(of: todoBlock) else { return }
            
            let newInsertedIndex = index + 1
            let newPosition = newInsertedIndex == contents.count ? todoBlock.position + Double(65536) :
                (contents[index].position +  contents[newInsertedIndex].position) / 2
            let newTodoBlock = Block.todo(parentId: todoListBlock.id, position: newPosition)
            
            viewModel.updateContentAndInsertNew(todoBlock, newContent: newTodoBlock, newIndex: newInsertedIndex) {
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [IndexPath(row: newInsertedIndex, section: 0)], with: .none)
                    self.tryGetFocus(row: newInsertedIndex)
                }, completion: nil)
            }
        }
    }
    
    func todoNeedDelete(todoBlock: BlockInfo) {
        self.deleteContent(todoBlock,isNeedGetFocus: true)
    }
    
    private func deleteContent(_ todoBlock:BlockInfo,isNeedGetFocus:Bool = false) {
        guard let index =  contents.firstIndex(of: todoBlock) else { return }
        viewModel.deleteContent(todoBlock) {
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
                if isNeedGetFocus {
                   self.tryGetFocus(row: index-1)
                }
            }, completion: nil)
        }
    }
    
    private func tryGetFocus(row:Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let todoCell = self?.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? TodoBlockCell else { return }
            todoCell.textView.becomeFirstResponder()
        }
    }
    
}

// drag and drop
extension TodoBlockEditorView: UITableViewDragDelegate, UITableViewDropDelegate  {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
    }
}

//// 键盘
extension TodoBlockEditorView {
    
    @objc func handleKeyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            let rect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]  as! NSValue).cgRectValue
            keyboardIsHide = false
            keyboardHeight = rect.height
            keyboardHeight2 =  keyboardHeight + bottombarHeight
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            //            self.bottombar.snp.updateConstraints { (make) in
            //                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset( -(rect.height - view.safeAreaInsets.bottom))
            //            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.layoutIfNeeded()
            }
            
            var contentInset = self.tableView.contentInset
            contentInset.bottom = rect.height + bottomExtraSpace + TodoGroupCell.CELL_HEIGHT
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
            
            //            self.bottombar.isKeyboardShow = true
            
            
        }
    }
    
    @objc func handleKeyboardHideNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            if keyboardIsHide {
                return
            }
            keyboardHeight = 0
            keyboardIsHide = true
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            //            self.bottombar.snp.updateConstraints { (make) in
            //                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(0)
            //            }
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.layoutIfNeeded()
            }
            var contentInset = self.tableView.contentInset
            contentInset.bottom = bottomExtraSpace
            
            self.tableView.contentInset = contentInset
            self.tableView.scrollIndicatorInsets = contentInset
            
            
            //            self.bottombar.isKeyboardShow = false
        }
    }
}
