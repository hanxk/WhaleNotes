//
//  SideMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

enum SideMenuCellContants {
    static let iconWidth:CGFloat = 34
    static let cellPadding = 20
    static let highlightColor =  UIColor(hexString: "#EFEFEF")
}

class SideMenuViewController: UIViewController {
    
    private var menuSectionTypes:[MenuSectionType] = []
    
    private let disposeBag = DisposeBag()
    
    var sectionSpecial = -1
    
    private lazy var bottomView:SideMenuBottomView = SideMenuBottomView().then {
        
        $0.callbackNewBlock = { sender in
            let items = [
                ContextMenuItem(label: "添加便签板", icon: "plus.rectangle",tag: 1),
                ContextMenuItem(label: "添加分类", icon: "folder.badge.plus",tag:2)
            ]
            ContextMenuViewController.show(sourceView:sender, sourceVC: self, items: items) { [weak self] menuItem in
                guard let self = self,let flag = menuItem.tag as? Int else { return }
                if flag == 1 {
                    BoardEditAlertViewController.showModel(vc: self) { emoji,title in
                        self.createBoard(emoji: emoji, title: title)
                    }
                }else {
                    self.showAlertTextField(title: "添加分类",text:"" ,placeholder: "输入分类名称") {[weak self] inputText in
                        self?.createBoardCategory(title: inputText)
                    }
                }
            }
            
        }
        
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        
        
        $0.separatorColor = .clear
        $0.register(MenuSystemCell.self, forCellReuseIdentifier:CellReuseIdentifier.system.rawValue)
        $0.register(MenuBoardCell.self, forCellReuseIdentifier:CellReuseIdentifier.board.rawValue)
        $0.register(MenuCategoryCell.self, forCellReuseIdentifier:CellReuseIdentifier.category.rawValue)
        
        $0.separatorColor = .clear
        
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        $0.delegate = self
        $0.dataSource = self
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        
        $0.showsVerticalScrollIndicator = false
        
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        
        $0.dragInteractionEnabled = true
    }
    
    
    private var boards:[Board] = []
    
    private var mapCategoryIdAnIndex:[Int64:Int]  = [:]
    private var boardCategories:[BoardCategoryInfo] = [] {
        didSet {
            self.mapCategoryIdAnIndex.removeAll()
            for (index,boardCategoryInfo) in boardCategories.enumerated() {
                mapCategoryIdAnIndex[boardCategoryInfo.category.id] = index
            }
        }
    }
    private let sectionCategoryBeginIndex = 2
    
    private var selectedIndexPath:IndexPath = IndexPath(row: 0, section: 0)
    
    private lazy var cellSelectedBackgroundView = SideMenuViewController.generateCellSelectedView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadBoards()
        
    }
    
    private func setupUI() {
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        
        self.view.addSubview(bottomView)
        bottomView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(44)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        let bg = UIColor.init(hexString: "#FBFBFB")
        self.tableView.backgroundColor = bg
        
    }
    
    private func loadBoards() {
        BoardRepo.shared.getBoardCategoryInfos()
            .subscribe(onNext: { [weak self] result in
                self?.setupData(boardsResult: result)
                }, onError: { err in
                    Logger.error(err)
            })
            .disposed(by: disposeBag)
    }
    
    
    private func setupData(boardsResult:([Board],[BoardCategoryInfo])) {
        menuSectionTypes.removeAll()
        menuSectionTypes.append(MenuSectionType.system(items: [
            MenuSystemItem.collect(icon: "rectangle.on.rectangle.angled", title: "收集板"),
            MenuSystemItem.trash(icon: "trash", title: "废纸篓")
        ]))
        
        self.boards = boardsResult.0
        menuSectionTypes.append(MenuSectionType.boards)
        
        self.boardCategories = boardsResult.1
        for _ in 0..<self.boardCategories.count {
            menuSectionTypes.append(MenuSectionType.categories)
        }
        
        
        self.tableView.reloadData()
    }
    
}


//MARK: board 分类
extension SideMenuViewController {
    
    func createBoardCategory(title:String) {
        let boardCategory = BoardCategory(id: 0, title: title, sort: 1, isExpand: true, createdAt: Date())
        BoardRepo.shared.createBoardCategory(boardCategory: boardCategory)
            .subscribe(onNext: { [weak self] newBoardCategory in
                self?.handleBoardCategoryInsert(insertedBoardCategory: newBoardCategory)
                }, onError: { error in
                    Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    func handleBoardCategoryInsert(insertedBoardCategory: BoardCategory) {
        self.boardCategories.insert(BoardCategoryInfo(category: insertedBoardCategory, boards: []), at: 0)
        self.menuSectionTypes.insert(MenuSectionType.categories, at: sectionCategoryBeginIndex)
        self.tableView.performBatchUpdates({
            self.tableView.insertSections(IndexSet([sectionCategoryBeginIndex]), with: .automatic)
        }, completion: { _ in
            DispatchQueue.main.async {
                let indexPath = IndexPath(item:0, section: self.sectionCategoryBeginIndex)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        })
    }
    
    
    func handleCategoryMenuEdit(boardCategoryInfo: BoardCategoryInfo,sourceView: UIView) {
        
        let TAG_ADD = 1
        let TAG_EDIT = 2
        let TAG_DEL = 3
        
        
        let items = [
            ContextMenuItem(label: "添加便签板", icon: "plus.rectangle",tag: TAG_ADD),
            ContextMenuItem(label: "编辑分类", icon: "pencil",tag:TAG_EDIT),
            ContextMenuItem(label: "删除分类", icon: "trash",tag:TAG_DEL)
        ]
        ContextMenuViewController.show(sourceView:sourceView, sourceVC: self, items: items) { [weak self] menuItem in
            guard let self = self,let tag = menuItem.tag as? Int else { return }
            switch tag {
            case TAG_ADD:
                BoardEditAlertViewController.showModel(vc: self) { emoji,title in
                    self.createBoard(emoji: emoji, title: title,boardCategory:boardCategoryInfo.category)
                }
            case TAG_EDIT:
                self.showAlertTextField(title: "编辑分类",text:boardCategoryInfo.category.title ,placeholder: "输入分类名称") {[weak self] inputText in
                    guard let self = self, let boardCategory =  boardCategoryInfo.category else { return }
                    if boardCategory.title == inputText { return }
                    var newBoardCategory  = boardCategory
                    newBoardCategory.title = inputText
                    self.updateBoardCayegory(newBoardCategory: newBoardCategory)
                }
                break
            case TAG_DEL:
                self.showAlertMessage(message: "确认删除该分类", positiveButtonText: "删除",isPositiveDestructive:true) {
                    self.deleteBoardCategory(boardCategoryInfo: boardCategoryInfo)
                }
                break
            default:
                break
                
            }
        }
    }
    
    
    func updateBoardCayegory(newBoardCategory:BoardCategory) {
        BoardRepo.shared.updateBoardCategory(boardCategory: newBoardCategory)
            .subscribe(onNext: { [weak self] isSuccess in
                if isSuccess {
                    self?.handleBoardCategoryUpdate(newBoardCategory: newBoardCategory)
                }
                }, onError: { error in
                    Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    func handleBoardCategoryUpdate(newBoardCategory: BoardCategory) {
        guard let categoryIndex = self.mapCategoryIdAnIndex[newBoardCategory.id] else { return }
        let section =  categoryIndex + self.sectionCategoryBeginIndex
        if self.boardCategories[categoryIndex].category.isExpand != newBoardCategory.isExpand { // 刷新 section
            self.boardCategories[categoryIndex].category = newBoardCategory
            self.tableView.performBatchUpdates({
                self.tableView.reloadSections(IndexSet([section]), with: .automatic)
            }, completion: nil)
            return
        }
        self.boardCategories[categoryIndex].category = newBoardCategory
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .none)
        }, completion: nil)
    }
    
    
    func deleteBoardCategory(boardCategoryInfo:BoardCategoryInfo) {
        
        var deletedBoardCategoryInfo = boardCategoryInfo
        
        var baseSort = self.boards.count == 0 ? 65536 : self.boards[0].sort
        
        let count = deletedBoardCategoryInfo.boards.count
        for i in (0..<count).reversed() {
            baseSort /= 2
            deletedBoardCategoryInfo.boards[i].categoryId = 0
            deletedBoardCategoryInfo.boards[i].sort = baseSort
        }
        
        BoardRepo.shared.deleteBoardCategory(boardCategoryInfo:deletedBoardCategoryInfo)
            .subscribe(onNext: { [weak self] isSuccess in
                if isSuccess {
                    self?.handleBoardCategoryInfoDelete(boardCategoryInfo: deletedBoardCategoryInfo)
                }
                }, onError: { error in
                    Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    
    func handleBoardCategoryInfoDelete(boardCategoryInfo: BoardCategoryInfo) {
        //移除 category
        guard let categoryIndex = self.mapCategoryIdAnIndex[boardCategoryInfo.category.id] else { return }
        
        self.boards.insert(contentsOf: boardCategoryInfo.boards, at: 0)
        
        self.menuSectionTypes.remove(at: categoryIndex + self.sectionCategoryBeginIndex)
        self.boardCategories.remove(at: categoryIndex)
        
        var updatedRowsIndexPath:[IndexPath] = []
        for (index,_) in  boardCategoryInfo.boards.enumerated() {
            updatedRowsIndexPath.append(IndexPath(row: index, section: 1))
        }
        
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet([2+categoryIndex]), with: .automatic)
            self.tableView.insertRows(at: updatedRowsIndexPath, with: .automatic)
        }, completion: nil)
    }
    
    func expandOrCollapse(section:Int) {
        if var  category = self.boardCategories[section-2].category {
            category.isExpand = !category.isExpand
            self.updateBoardCayegory(newBoardCategory: category)
        }
    }
}



//MARK: board
extension SideMenuViewController {
    func createBoard(emoji: Emoji,title:String,boardCategory: BoardCategory? = nil) {
        let board = Board(icon: emoji.value, title: title, sort: self.getBoardSort(boardCategory:boardCategory),categoryId:boardCategory?.id ?? 0)
        BoardRepo.shared.createBoard(board: board)
            .subscribe(onNext: { [weak self] newBoard in
                self?.handleBoardInsert(insertedBoard: newBoard)
                }, onError: { error in
                    Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    func handleBoardInsert(insertedBoard: Board) {
        if insertedBoard.categoryId > 0 { // 往分类里面添加 board
            guard let categoryIndex = self.mapCategoryIdAnIndex[insertedBoard.categoryId] else { return }
            
            let section = 2+categoryIndex
            var delayTime:DispatchTime = DispatchTime.now()
            if !self.boardCategories[categoryIndex].category.isExpand {
                delayTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(500)
                // 先展开
                self.expandOrCollapse(section:section)
            }
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                
                self.boardCategories[categoryIndex].boards.insert(insertedBoard, at: 0)
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: section)], with: .automatic)
                }, completion: { _ in
                    self.tryUpdateSelectedIndexPath(updatedSection:section)
                })
            }
            return
        }
        self.boards.insert(insertedBoard, at: 0)
        self.tableView.performBatchUpdates({
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
        }, completion: { _ in
            self.tryUpdateSelectedIndexPath(updatedSection: 1)
        })
    }
    
    func setSelected(indexPath: IndexPath) {
        let oldIndexPath =  self.selectedIndexPath
        var updatedIndexPaths:[IndexPath]   = []
        
        if tableView.cellForRow(at: oldIndexPath) != nil {
            updatedIndexPaths.append(oldIndexPath)
        }
        
        self.selectedIndexPath = indexPath
        if tableView.cellForRow(at: self.selectedIndexPath) != nil {
            updatedIndexPaths.append( self.selectedIndexPath)
        }
        
        if updatedIndexPaths.isEmpty { return }
        
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: updatedIndexPaths, with: .none)
        }, completion: nil)
    }
    
    func tryUpdateSelectedIndexPath(updatedSection:Int) {
        
        if self.selectedIndexPath.section != updatedSection {
            self.setSelected(indexPath: IndexPath(row:self.selectedIndexPath.row+1,section: updatedSection))
            return
        }
        
        
        
        //        if tableView.cellForRow(at: oldValue) != nil {
        //             self.tableView.performBatchUpdates({
        //                  self.tableView.reloadRows(at: [selectedIndexPath,oldValue], with: .none)
        //             }, completion: nil)
        //         }else {
        //
        //             if tableView.cellForRow(at: selectedIndexPath) != nil {
        //
        //                 self.tableView.performBatchUpdates({
        //                                     self.tableView.reloadRows(at: [selectedIndexPath], with: .none)
        //                                }, completion: nil)
        //             }
        //         }
        
    }
    
    func updateBoard(newBoard:Board,callback:(()->Void)? = nil) {
        BoardRepo.shared.updateBoard(board: newBoard)
            .subscribe(onNext: { isSuccess in
                if isSuccess  {
                    self.handleBoardUpdated(board: newBoard)
                    callback?()
                }
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    func handleBoardUpdated(board: Board) {
        if board.categoryId == 0 {
            if let boardIndex = self.boards.firstIndex(where: {$0.id == board.id}) {
                let isSortUpdate =  self.boards[boardIndex].sort != board.sort
                self.boards[boardIndex] = board
                if isSortUpdate {
                    self.boards =  self.boards.sorted(by: {$0.sort < $1.sort})
                }
            }
        }else {
            if let categoryIndex = self.mapCategoryIdAnIndex[board.categoryId],
                let boardIndex =  self.boardCategories[categoryIndex].boards.firstIndex(where: { $0.id == board.id})
            {
                let isSortUpdate = self.boardCategories[categoryIndex].boards[boardIndex].sort != board.sort
                self.boardCategories[categoryIndex].boards[boardIndex] = board
                if isSortUpdate {
                    self.boardCategories[categoryIndex].boards =  self.boardCategories[categoryIndex].boards.sorted(by: {$0.sort < $1.sort})
                }
            }
        }
    }
    
    func getBoardSort(boardCategory: BoardCategory?) -> Double {
        
        var boards = self.boards
        if let boardCategory = boardCategory {
            guard let categoryIndex = self.mapCategoryIdAnIndex[boardCategory.id] else { return 65536}
            boards = self.boardCategories[categoryIndex].boards
        }
        
        if boards.count == 0 {
            return 65536
        }
        return boards[0].sort / 2
    }
    
    func calcSort(toRow:Int,boards:[Board])->Double {
        if boards.count == 0 {
            return 65536
        }
        if toRow == 0 {
            return boards[toRow].sort / 2
        }
        if toRow == boards.count - 1 {
            return  boards[toRow].sort + 65536
        }
        if toRow == boards.count {
            return  boards[toRow-1  ].sort + 65536
        }
        return (boards[toRow-1].sort + boards[toRow].sort)/2
    }
    
    
    // 排序处理
    func swapRowInSameSection(section: Int,fromRow: Int, toRow: Int) {
        if case .boards = self.menuSectionTypes[section] {
            var board = self.boards[fromRow]
            board.sort = calcSort(toRow: toRow, boards: self.boards)
            self.updateBoard(newBoard: board) {
                self.boards.forEach {
                    print($0.sort)
                }
            }
        }else {
            let boardInfo = self.boardCategories[section-2]
            var board = boardInfo.boards[fromRow-1]
            board.sort = calcSort(toRow: toRow-1, boards:boardInfo.boards)
            self.updateBoard(newBoard: board) {
                self.boardCategories[section-2].boards.forEach {
                    print($0.sort)
                }
            }
        }
    }
    
    func swapRowCrossSection(fromSection: Int,toSection: Int,fromRow: Int, toRow: Int) {
        
        var board:Board?
        // 移除 from 中的 board
        if case .categories = self.menuSectionTypes[fromSection] {
            board = self.boardCategories[fromSection - self.sectionCategoryBeginIndex].boards[fromRow-1]
            self.boardCategories[fromSection - self.sectionCategoryBeginIndex].boards.remove(at: fromRow - 1)
        }else {
            board = self.boards[fromRow]
            self.boards.remove(at: fromRow)
        }
        
        guard var fromBoard = board else { return }
        
        var insertRow = 0
        
        if case .categories = self.menuSectionTypes[toSection] {
            fromBoard.categoryId =  self.boardCategories[toSection - self.sectionCategoryBeginIndex].category.id
            fromBoard.sort =  self.calcSort(toRow: toRow-1, boards: self.boardCategories[toSection - self.sectionCategoryBeginIndex].boards)
            insertRow = self.boardCategories[toSection - self.sectionCategoryBeginIndex].insertBoard(fromBoard)
            
            
            let isExpand = self.boardCategories[toSection - self.sectionCategoryBeginIndex].category.isExpand
            if !isExpand {
                
                // 先显示，然后再删除
                sectionSpecial = toSection
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3) {
                    self.tableView.performBatchUpdates({
                        self.tableView.reloadSections(IndexSet([toSection]), with: .fade)
                    }, completion: nil)
                }
            }
            
            
        }else {
            fromBoard.sort =  self.calcSort(toRow: toRow, boards: self.boards)
            fromBoard.categoryId = 0
            
            var insertIndex = self.boards.firstIndex(where: {$0.sort > fromBoard.sort}) ?? 0
            self.boards.insert(fromBoard, at: insertIndex)
            insertRow = insertIndex
        }
        
        self.updateBoard(newBoard: fromBoard)
        
        //        let insertIndexPath = IndexPath(row: insertRow, section: toSection)
        
        
        
    }
}


//MARK: UITableViewDelegate
extension SideMenuViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = self.menuSectionTypes[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: getCellIdentifier(sectionType: sectionType, indexPath: indexPath))!
        switch sectionType {
        case .system(let items):
            let sysCell = cell as! MenuSystemCell
            sysCell.menuSysItem = items[indexPath.row]
            sysCell.cellIsSelected = selectedIndexPath == indexPath
            break
        case .boards:
            let boardCell = cell as! MenuBoardCell
            boardCell.board = self.boards[indexPath.row]
            boardCell.cellIsSelected = selectedIndexPath == indexPath
            break
        case .categories:
            if indexPath.row == 0 {
                let boardCategoryInfo = self.boardCategories[indexPath.section-2]
                let categoryCell = cell as! MenuCategoryCell
                categoryCell.boardCategory = boardCategoryInfo.category
                categoryCell.callbackMenuTapped = { [weak self] button,boardCategory in
                    self?.handleCategoryMenuEdit(boardCategoryInfo: boardCategoryInfo,sourceView: button)
                }
            }else {
                let boardCell = cell as! MenuBoardCell
                boardCell.board = self.boardCategories[indexPath.section-2].boards[indexPath.row-1]
                boardCell.cellIsSelected = selectedIndexPath == indexPath
            }
        }
        return cell
    }
    
    private func getCellIdentifier(sectionType:MenuSectionType,indexPath:IndexPath) -> String {
        switch sectionType {
        case .system:
            return CellReuseIdentifier.system.rawValue
        case .boards:
            return CellReuseIdentifier.board.rawValue
        case .categories:
            if indexPath.row == 0 {
                return CellReuseIdentifier.category.rawValue
            }
            return CellReuseIdentifier.board.rawValue
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .system:
            return MenuHeaderView()
        default:
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .boards:
            return true
        case .categories:
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
        
        
        if self.selectedIndexPath == sourceIndexPath {
            self.selectedIndexPath = destinationIndexPath
        }
    }
    
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section
        
        let sourSectionType = self.menuSectionTypes[sourceSection]
        let desSectionType = self.menuSectionTypes[destSection]
        
        
        switch desSectionType {
        case .boards:
            return proposedDestinationIndexPath
        case .categories:
            if proposedDestinationIndexPath.row == 0 {
                return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
            }
            return proposedDestinationIndexPath
        case .system:
            if destSection > sourceSection {
                return IndexPath(row: self.tableView(tableView, numberOfRowsInSection:sourceSection)-1, section: sourceSection)
            }
            if case .categories  = sourSectionType {
                return IndexPath(row: 1, section: sourceSection)
            }
            return IndexPath(row: 0, section: sourceSection)
            
        }
    }
    
    
    static func generateCellSelectedView() ->UIView {
        return UIView().then {
            $0.backgroundColor = SideMenuCellContants.highlightColor
            let cornerRadius:CGFloat = 4
            $0.layer.cornerRadius = CGFloat(cornerRadius)
            $0.clipsToBounds = true
            $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            $0.isHidden = true
        }
    }
    
}


//MARK: UITableViewDataSource
extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.menuSectionTypes[section] {
        case .system(let items):
            return items.count
        case .boards:
            return self.boards.count
        case .categories: // 分类作为单独一个 cell
            let categoryInfo = self.boardCategories[section-2]
            if !categoryInfo.category.isExpand {
                
                if self.sectionSpecial == section {
                    self.sectionSpecial = -1
                    return 2
                }
                return 1
            }
            return categoryInfo.boards.count + 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSectionTypes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            return 42
        default:
            return 42
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let sectionSpace:CGFloat  = 20
        
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .system:
            return 44
        case .categories:
            if case .categories = self.menuSectionTypes[section-1] {
                return 2
            }
            return sectionSpace
        case .boards:
            return sectionSpace
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionType = self.menuSectionTypes[section]
        switch sectionType {
        case .categories:
            let categoryInfo = self.boardCategories[section-2]
            if categoryInfo.category.isExpand {
                return 20
            }
            break
        default:
            return 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            self.setSelected(indexPath: indexPath)
            break
        case .boards:
            self.setSelected(indexPath: indexPath)
            break
        case .categories:
            if indexPath.row > 0 {
                self.setSelected(indexPath: indexPath)
            }else {
                self.expandOrCollapse(section: indexPath.section)
            }
            break
        }
    }
    
}


// drag and drop
extension SideMenuViewController: UITableViewDragDelegate, UITableViewDropDelegate  {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}


enum MenuSectionType {
    case system(items: [MenuSystemItem])
    case boards
    case categories
}

fileprivate enum CellReuseIdentifier: String {
    case system = "system"
    case board = "boards"
    case category = "category"
}

enum MenuSystemItem {
    case collect(icon:String,title:String)
    case trash(icon:String,title:String)
    
    var icon:String {
        switch self {
        case .collect(let icon,_):
            return icon
        case .trash(let icon,_):
            return icon
        }
    }
    var title:String {
        switch self {
        case .collect(_,let title):
            return title
        case .trash(_,let title):
            return title
        }
    }
}
