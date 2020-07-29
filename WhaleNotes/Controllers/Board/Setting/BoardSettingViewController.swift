//
//  BoardSettingViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class BoardSettingViewController:UIViewController {
    
    enum BoardSettingItem: String {
        case icon = "icon"
        case title = "title"
        case archived = "archived"
        case trash = "trash"
    }
    
    enum BoardSettingEditedType {
        case update(board:BlockInfo)
        case delete(board:BlockInfo)
    }
    
    static let horizontalPadding:CGFloat = 16
    
    private var settingItems:[BoardSettingItem] = [BoardSettingItem.icon,BoardSettingItem.title,BoardSettingItem.archived,BoardSettingItem.trash]
    var boardProperties:BlockBoardProperty {
        get {self.board.blockBoardProperties!}
        set {self.board.blockBoardProperties = newValue}
    }
    var board:BlockInfo! {
        didSet {
            if oldValue != nil {
                isBoardEdited = true
            }
            if  boardProperties.type == .user {
                self.settingItems = [BoardSettingItem.icon,BoardSettingItem.title,BoardSettingItem.archived,BoardSettingItem.trash]
            }else {
                self.settingItems = [BoardSettingItem.icon,BoardSettingItem.title,BoardSettingItem.archived]
            }
        }
    }
    
    var callbackBoardSettingEdited:((BoardSettingEditedType)->Void)?
    
    private var isBoardEdited:Bool = false
    private let cellReuseIndentifier = "ChangeBoardCell"
    
    private let disposeBag = DisposeBag()
    
    private var isPreventChild = false
    
    private var archiveCount:Int = 0 {
        didSet {
            if oldValue == archiveCount { return }
            guard let index = settingItems.firstIndex(where: {$0 == .archived}) else { return }
            self.tableView.performBatchUpdates({
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: index)], with: .none)
            }, completion: nil)
        }
    }
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.separatorColor = .dividerGray
        $0.delegate = self
        $0.dataSource = self
        $0.showsVerticalScrollIndicator = false
        $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
        $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
        
        $0.register(BoardIconView.self, forHeaderFooterViewReuseIdentifier: BoardSettingItem.icon.rawValue)
        $0.register(BoardIconCell.self, forCellReuseIdentifier: BoardSettingItem.icon.rawValue)
        $0.register(BoardSettingTitleCell.self, forCellReuseIdentifier: BoardSettingItem.title.rawValue)
        $0.register(BoardSettingItemCell.self, forCellReuseIdentifier: BoardSettingItem.archived.rawValue)
        $0.register(BoardSettingButtonCell.self, forCellReuseIdentifier: BoardSettingItem.trash.rawValue)
        
        $0.backgroundColor = .settingbg
    }
    
    private lazy var  cellBackgroundView = UIView().then {
        $0.backgroundColor = UIColor.sidemenuSelectedBg
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        let cancelButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        let barButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(self.doneButtonTapped))
        barButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.brand], for: .normal)
        self.navigationItem.rightBarButtonItem = barButtonItem
        self.navigationController?.navigationBar.barTintColor = .bg
        
        
        self.title = boardProperties.title
        self.navigationController?.presentationController?.delegate = self
        
        self.setupData()
    }
    
    private func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    private func setupData() {
        
        BoardRepo.shared.getNotesCount(boardId: self.board.id, noteBlockStatus: .archive)
            .subscribe(onNext: {
                self.archiveCount = $0
                self.tableView.reloadData()
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.isPreventChild = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isPreventChild = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            self.navigationController?.presentationController?.delegate = nil
        }
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTapped() {
        if isBoardEdited {
            self.board.updatedAt = Date()
            BoardRepo.shared.updateBoardProperties(boardId: self.board.id, blockBoardProperties: boardProperties)
                .subscribe {
                    self.callbackBoardSettingEdited?(BoardSettingEditedType.update(board:self.board))
                    self.dismiss(animated: true, completion:nil)
                } onError: {
                    Logger.error($0)
                }
                .disposed(by: disposeBag)
        }else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension BoardSettingViewController:UIAdaptivePresentationControllerDelegate,UIActionSheetDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if  self.isPreventChild {
            return false
        }
        if isBoardEdited {
            self.showDismissSheet()
            return false
        }
        return true
    }
    
    func showDismissSheet() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "放弃更改", style: .destructive, handler:
                                            {
                                                (alert: UIAlertAction!) -> Void in
                                                self.dismiss(animated: true, completion: nil)
                                            })
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler:
                                            {
                                                (alert: UIAlertAction!) -> Void in
                                                optionMenu.dismiss(animated: true, completion: nil)
                                            })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
}

extension BoardSettingViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingItems.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = self.settingItems[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: sectionType.rawValue)!
        switch sectionType {
        case .icon:
            break
        case .title:
            let titleCell = cell as! BoardSettingTitleCell
            titleCell.title = boardProperties.title
            titleCell.titleTextField.isEnabled = boardProperties.type == .user
            titleCell.callbackTitleChanged = { title in
                self.boardProperties.title = title
                self.navigationItem.rightBarButtonItem?.isEnabled = title.isNotEmpty
            }
            break
        case .archived:
            let archivedCell = cell as! BoardSettingItemCell
            archivedCell.titleAndValue = ("已归档的便签", String(self.archiveCount))
            break
        case .trash:
            let trashCell = cell as! BoardSettingButtonCell
            trashCell.lblText = "彻底删除"
            break
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.settingItems[section]
        switch sectionType {
        case .icon:
            if let iconView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BoardSettingItem.icon.rawValue) as? BoardIconView {
                iconView.iconImage = boardProperties.getBoardIcon(fontSize: 50)
                iconView.isEdited = boardProperties.type == .user
                iconView.callbackTapped = {
                    let vc = EmojiViewController()
                    vc.callbackEmojiSelected = { [weak self] emoji in
                        guard let self = self else { return }
                        self.boardProperties.icon = emoji.value
                        iconView.iconImage = self.boardProperties.getBoardIcon(fontSize: 50)
                    }
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                return iconView
            }
            return nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = self.settingItems[section]
        switch sectionType {
        case .title:
            return "便签板名称"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = self.settingItems[section]
        switch sectionType {
        case .icon:
            return BoardIconView.getCellHeight(boardType: self.boardProperties.type)
        case .title:
            return 48
        case .archived:
            return 26
        case .trash:
            return 40
        }
    }
}


extension BoardSettingViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight:CGFloat = 46
        let sectionType = self.settingItems[indexPath.section]
        switch sectionType {
        case .icon:
            return BoardIconCell.cellHeight
        default:
            return cellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        let sectionType = self.settingItems[indexPath.section]
        switch sectionType {
        case .trash:
            self.deleteBoard()
        case .archived:
            let archiveVC = ArchiveNotesViewController()
            archiveVC.board = self.board
            archiveVC.callbackNotesCountChanged = { [weak self] count in
                self?.archiveCount = count
            }
            self.navigationController?.pushViewController(archiveVC, animated: true)
        default:
            break
        }
    }
}

extension BoardSettingViewController {
    private func deleteBoard() {
        let alert = UIAlertController(title: "彻底删除", message: "删除后的内容将不能够被恢复。确认要删除吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "彻底删除", style: .destructive, handler: { _ in
            self.handleDeleteBoard()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func handleDeleteBoard() {
        BoardRepo.shared.delete(boardId: self.board.id)
            .subscribe {
                self.dismiss(animated: true, completion: {
                    self.callbackBoardSettingEdited?(BoardSettingEditedType.delete(board:self.board))
                })
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
    }
}
