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
        case update(board:Board)
        case delete(board:Board)
    }
    
    static let horizontalPadding:CGFloat = 16
    
    private var settingItems:[BoardSettingItem] = [BoardSettingItem.icon,BoardSettingItem.title,BoardSettingItem.archived,BoardSettingItem.trash]
    var board:Board! {
        didSet {
            isBoardEdited = true
        }
    }
    
    var callbackBoardSettingEdited:((BoardSettingEditedType)->Void)?
    
    private var isBoardEdited:Bool = false
    
    private let cellReuseIndentifier = "ChangeBoardCell"
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped).then {
                $0.separatorColor = UIColor(hexString: "#ECECEC")
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
        $0.backgroundColor = .bg
        
        self.title = "便签板设置"
    }
    
    private lazy var  cellBackgroundView = UIView().then {
        $0.backgroundColor = UIColor.tappedColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        
        let cancelButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        let barButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(self.doneButtonTapped))
        //        barButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.brand], for: .normal)
        self.navigationItem.rightBarButtonItem = barButtonItem
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
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTapped() {
        if isBoardEdited {
            BoardRepo.shared.updateBoard(board: self.board)
                .subscribe(onNext: { [weak self] result in
//                    self?.setupData(boardsResult: result)
                    guard let self = self else { return }
                    self.dismiss(animated: true, completion: {
                        self.callbackBoardSettingEdited?(BoardSettingEditedType.update(board:self.board))
                    })
                    
                    }, onError: { err in
                        Logger.error(err)
                })
                .disposed(by: disposeBag)
        }
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
            let iconCell = cell as! BoardIconCell
            iconCell.board = board
            break
        case .title:
            let titleCell = cell as! BoardSettingTitleCell
            titleCell.title = board.title
            titleCell.callbackTitleChanged = { title in
                self.board.title = title
                self.navigationItem.rightBarButtonItem?.isEnabled = title.isNotEmpty
            }
            break
        case .archived:
            let archivedCell = cell as! BoardSettingItemCell
            archivedCell.titleAndValue = ("已归档的便签", "1")
            break
        case .trash:
            let trashCell = cell as! BoardSettingButtonCell
            trashCell.lblText = "彻底删除"
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.settingItems[section]
        switch sectionType {
        case .icon:
            if let iconView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BoardSettingItem.icon.rawValue) as? BoardIconView {
                iconView.board = self.board
                iconView.callbackTapped = {
                    let vc = EmojiViewController()
                    vc.callbackEmojiSelected = { [weak self] emoji in
                        guard let self = self else { return }
                        self.board.icon = emoji.value
                        iconView.board = self.board
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
            return BoardIconView.cellHeight
        case .title:
            return 48
        case .archived:
            return 26
        case .trash:
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return CGFloat.leastNormalMagnitude
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
        BoardRepo.shared.deleteBoard(boardId: self.board.id)
            .subscribe(onNext: { _ in
                self.dismiss(animated: true, completion: {
                    self.callbackBoardSettingEdited?(BoardSettingEditedType.delete(board:self.board))
                })
            }, onError: { error in
                Logger.error(error)
            })
        .disposed(by: disposeBag)
    }
}
