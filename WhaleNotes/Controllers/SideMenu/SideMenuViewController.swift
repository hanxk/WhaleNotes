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
    
    static let selectedPadding = 14
}

protocol SideMenuViewControllerDelegate: AnyObject {
    func sideMenuItemSelected(menuItemType:SideMenuItem)
}

enum SideMenuItem:Equatable {
    
    case system(menuInfo:MenuSystemItem)
    case board(board:BlockInfo)
    
    static func == (lhs: SideMenuItem, rhs: SideMenuItem) -> Bool {
        switch (lhs,rhs)  {
        case (.system(let lmenu),.system(let rmenu) ):
            return  lmenu == rmenu
        case (.system,.board):
            return false
        case (.board(let board),.board(let board2)):
            return board.id == board2.id
        case (.board,.system):
            return false
        }
    }
}

//enum SelectedMenuItem {
//    case trash
//    case board(boardId:String)
//
//
//    var boardId:String {
//        switch self {
//        case .trash:
//            return "trash"
//        case .board(let boardId):
//            return boardId
//        }
//    }
//}

class SideMenuViewController: UIViewController {
    private var sections:[MenuSectionType] = []
    
    private var trashMenuItem = MenuSystemItem.trash(icon: "trash", title: "废纸篓")
    private var selectedItemId:String! {
        didSet {
            delegate?.sideMenuItemSelected(menuItemType: getSideMenuItem())
        }
    }
    
    private func getSideMenuItem() -> SideMenuItem {
        if self.selectedItemId == self.collectBoard.id {
            return SideMenuItem.system(menuInfo: MenuSystemItem.board(board: self.collectBoard))
        }
        
        if self.selectedItemId == SysMenuItemId.trash {
            return SideMenuItem.system(menuInfo:trashMenuItem)
        }
        
        let board = self.userBoards.first(where: {$0.id == self.selectedItemId})!
        return SideMenuItem.board(board: board)
    }
    
    private let disposeBag = DisposeBag()
    weak var delegate:SideMenuViewControllerDelegate? = nil {
        didSet {
            self.loadBoards()
            self.registerEvent()
        }
    }
    
    private(set) var collectBoard:BlockInfo!
    private(set) var boardsMap:[String:BlockInfo] = [:]
    
    
    private(set) var userBoards:[BlockInfo]! {
        didSet {
            var boards:[BlockInfo] = []
            boards.append(contentsOf: userBoards)
            boards.append(collectBoard)
            boardsMap = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })
        }
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.separatorColor = .clear
        $0.register(MenuSystemCell.self, forCellReuseIdentifier:CellReuseIdentifier.system.rawValue)
        $0.register(MenuBoardCell.self, forCellReuseIdentifier:CellReuseIdentifier.board.rawValue)
        
        $0.separatorColor = .clear
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
        $0.delegate = self
        $0.dataSource = self
        
        $0.dragInteractionEnabled = true
        $0.dragDelegate = self
        
        $0.showsVerticalScrollIndicator = false
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        $0.backgroundColor = .clear
        $0.dragInteractionEnabled = true
    }
    
    
    static func generateCellSelectedView() ->UIView {
        return UIView().then {
            $0.backgroundColor = .sidemenuSelectedBg
            let cornerRadius:CGFloat = 8
            $0.layer.smoothCornerRadius = CGFloat(cornerRadius)
            $0.clipsToBounds = true
            $0.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.tableView.reloadData()
        
    }
    
    private func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.backgroundColor = .sidemenuBg
        self.setupToolbar()
    }
    
    private func loadBoards() {
        BoardsRepo.shared.getBoards()
            .subscribe {
                self.setupData(boards: $0)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupData(boards:[BlockInfo]) {
        
        guard let collectBoard =  boards.first(where: {$0.blockBoardProperties!.type == .collect}) else { return }
        self.collectBoard = collectBoard
        self.userBoards =  boards.filter({ $0.blockBoardProperties!.type == .user}).sorted(by: {$0.position < $1.position})
        
        // 默认展示收集板
        self.selectedItemId = collectBoard.id
        
        let systemMenuItems =  [
            MenuSystemItem.board(board: collectBoard),
            trashMenuItem
        ]
        sections.removeAll()
        
        self.sections.append(MenuSectionType.system(items: systemMenuItems))
        self.sections.append(MenuSectionType.boards)
    }
    deinit {
        self.unRegisterEvent()
    }
}

//MARK: Event
extension SideMenuViewController {
    private func registerEvent() {
        EventManager.shared.addObserver(observer: self, selector: #selector(handleBoardCreated), name: .My_BoardCreated)
    }
    
    private func unRegisterEvent() {
        EventManager.shared.removeObserver(observer: self)
    }
    
    @objc private func handleBoardCreated(notification: Notification) {
        guard let board = notification.object as? BlockInfo else { return }
        self.userBoards.insert(board, at: 0)
        self.tableView.performBatchUpdates({
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .none)
        }, completion: nil)
    }
}

extension SideMenuViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .system(let items):
            return items.count
        case .boards:
            return self.userBoards.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > 0 {
            return 24
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = self.sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: getCellIdentifier(sectionType: sectionType, indexPath: indexPath))!
        switch sectionType {
        case .system(let items):
            let sysCell = cell as! MenuSystemCell
            sysCell.menuSysItem = items[indexPath.row]
            sysCell.cellIsSelected = isSideMenuSelected(indexPath: indexPath)
        case .boards:
            let board = self.userBoards[indexPath.row]
            let boardCell = cell as! MenuBoardCell
            boardCell.cellIsSelected = isSideMenuSelected(indexPath: indexPath)
            boardCell.board = board
        }
        return cell
    }
    
    private func getCellIdentifier(sectionType:MenuSectionType,indexPath:IndexPath) -> String {
        switch sectionType {
        case .system:
            return CellReuseIdentifier.system.rawValue
        case .boards:
            return CellReuseIdentifier.board.rawValue
        }
    }
    
    private func isSideMenuSelected(indexPath: IndexPath) -> Bool {
        return getItemId(indexPath: indexPath) == self.selectedItemId
     }
    
    private func getItemId(indexPath:IndexPath) -> String {
        let sectionType = self.sections[indexPath.section]
        switch sectionType {
        case .system(let items):
           return  items[indexPath.row].id
        case .boards:
            return self.userBoards[indexPath.row].id
        }
    }
    
    private func setSelected(indexPath:IndexPath) {
       let oldSelectedIndex = getOldSelectedIndexPath()
        self.selectedItemId = getItemId(indexPath: indexPath)
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [oldSelectedIndex,indexPath], with: .none)
        }, completion: nil)
    }
    
    private func getOldSelectedIndexPath() -> IndexPath {
        if selectedItemId == self.collectBoard.id {
            return IndexPath(row: 0, section: 0)
        }
        if selectedItemId == SysMenuItemId.trash {
            return IndexPath(row: 1, section:0)
        }
        let row = self.userBoards.firstIndex(where: {$0.id == selectedItemId})!
        return IndexPath(row: row, section:1)
    }
    
}


extension SideMenuViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.setSelected(indexPath: indexPath)
    }
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if proposedDestinationIndexPath.section == 0 {
            return IndexPath(row: 0, section: sourceIndexPath.section)
        }
         return proposedDestinationIndexPath
     }
     
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromSection = sourceIndexPath.section
        
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        
        swapRowInSameSection(section: fromSection, fromRow: fromRow, toRow: toRow)
    }
    
    func calcNewPosition(fromRow:Int,toRow:Int) -> Double {
        if toRow == userBoards.count - 1 {
            return userBoards[userBoards.count-1].position + 65536
        }
        if toRow == 0 {
            return userBoards[0].position / 2
        }
        if fromRow < toRow {
            return (userBoards[toRow].position + userBoards[toRow+1].position) / 2
        }
        return (userBoards[toRow].position + userBoards[toRow-1].position) / 2
    }
    
    // 排序处理
    func swapRowInSameSection(section: Int,fromRow: Int, toRow: Int) {
        
        let position = calcNewPosition(fromRow: fromRow, toRow: toRow)
        
        var blockInfo = self.userBoards[fromRow]
        blockInfo.position = position
        blockInfo.updatedAt = Date()
        self.userBoards.remove(at: fromRow)
        self.userBoards.insert(blockInfo, at: toRow)
        
        BlockRepo.shared.update(blockPosition: blockInfo.blockPosition)
            .subscribe { _ in
                
            } onError: {
                Logger.error($0)
            }.disposed(by: disposeBag)
//        self.userBoards.forEach {
//            print("\($0.blockBoardProperties!.icon)  ----  \($0.position) ")
//        }
    }
    
}

//MARK: Toolbar
extension SideMenuViewController {
    
    private func setupToolbar() {
        let imageSize:CGFloat = 18
        let addBoard = self.generateUIBarButtonItem(title:"新建便签板",imageName: "plus.circle",imageSize: imageSize, action:  #selector(addBoardTapped))
        let setting = self.generateUIBarButtonItem(imageName: "slider.horizontal.3",imageSize: imageSize, action:  #selector(settingTapped))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [addBoard,spacer,setting]
        
        if let toolbar = self.navigationController?.toolbar {
            toolbar.tintColor = .iconColor
            toolbar.barTintColor =  .sidemenuBg
            toolbar.layer.borderColor = UIColor.init(hexString: "#f1f1f1").cgColor
            toolbar.clipsToBounds = true
        }
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @objc func addBoardTapped (sender:UIBarButtonItem) {
        //        let items = [
        //            ContextMenuItem(label: "添加便签板", icon: "plus.rectangle",tag: 1),
        //            ContextMenuItem(label: "添加分类", icon: "folder.badge.plus",tag:2)
        //        ]
        //        ContextMenuViewController.show(sourceView:sender.view!, sourceVC: self, items: items) { [weak self] menuItem, vc  in
        //            vc.dismiss(animated: true, completion: nil)
        //            guard let self = self,let flag = menuItem.tag as? Int else { return}
        //            if flag == 1 {
        //                self.openCreateBoardVC(parent: self.boardGroupBlock)
        //            }else {
        //                self.showCategoryInputAlert()
        //            }
        //        }
        self.openCreateBoardVC()
    }
    private func openCreateBoardVC() {
        let vc = CreateBoardViewController()
//        vc.callbackPositive = {emoji,title in
////            self.createBoard(emoji: emoji, title: title, parent: parent)
//        }
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func settingTapped () {
        
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
}


enum SysMenuItemId {
    static let trash = "trash"
}

fileprivate enum CellReuseIdentifier: String {
    case system = "system"
    case board = "boards"
}

enum MenuSystemItem:Equatable {
    case board(board: BlockInfo)
    case trash(icon:String,title:String)
    
    static func == (lhs: MenuSystemItem, rhs: MenuSystemItem) -> Bool {
        switch (lhs,rhs)  {
        case (.board(let lmenu),.board(let rmenu) ):
            return  lmenu.id == rmenu.id
        case (.board,.trash):
            return false
        case (.trash,.trash):
            return true
        case (.trash(icon:  _, title:  _), .board(board: _)):
            return false
        }
    }
    
    var icon:String {
        switch self {
        case .board(let board):
            return board.blockBoardProperties?.icon ?? ""
        case .trash(let icon,_):
            return icon
        }
    }
    
    var iconImage:UIImage? {
        return UIImage(systemName: icon, pointSize: 15, weight: .regular)
    }
    
    var title:String {
        switch self {
        case .board(let board):
            return board.title
        case .trash(_,let title):
            return title
        }
    }
    
    
    var id:String {
        switch self {
        case .board(let board):
            return board.id
        case .trash:
            return SysMenuItemId.trash
        }
    }
    
}
