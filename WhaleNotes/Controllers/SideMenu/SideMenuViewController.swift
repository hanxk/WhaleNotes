//
//  SideMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class SideMenuViewController: UITableViewController {
    
    private var menuSectionTypes:[MenuSectionType] = []
    private let disposeBag = DisposeBag()
    
    private var bottomView:SideMenuBottomView = SideMenuBottomView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.tableView = UITableView(frame: .zero, style: .grouped).then {
            

            $0.separatorColor = .clear
            $0.register(MenuSystemCell.self, forCellReuseIdentifier:CellReuseIdentifier.system.rawValue)
            $0.register(MenuBoardCell.self, forCellReuseIdentifier:CellReuseIdentifier.board.rawValue)
            $0.register(MenuCategoryCell.self, forCellReuseIdentifier:CellReuseIdentifier.category.rawValue)
            
            $0.separatorColor = .clear
            
//            $0.contentInset = UIEdgeInsets(top: -1.0, left: 0, bottom: bottomExtraSpace, right: 0)
            $0.delegate = self
            $0.dataSource = self
            
            $0.sectionHeaderHeight = CGFloat.leastNormalMagnitude
            $0.sectionFooterHeight = CGFloat.leastNormalMagnitude
            
            $0.dragInteractionEnabled = true
        }
        let bg = UIColor.init(hexString: "#FBFBFB")
        self.tableView.backgroundColor = bg
        
        
        self.view.addSubview(bottomView)
        bottomView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(44)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        bottomView.callbackNewBlock = {
            let navController = MyNavigationController(rootViewController: BoardEditViewController())
            self.navigationController?.present(navController, animated: true, completion: nil)
        }
        
        self.loadBoards()
    
    }
    
    private func loadBoards() {
        BoardeRepo.shared.getBoardCategoryInfos()
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
//        menuSectionTypes.append(MenuSectionType.boards(boards: boardsResult.0))
//        menuSectionTypes.append(MenuSectionType.categories(categories: boardsResult.1))
        self.tableView.reloadData()
    }

}

// delegate
extension SideMenuViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = self.menuSectionTypes[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: getCellIdentifier(sectionType: sectionType, indexPath: indexPath))!
        switch sectionType {
        case .system(let items):
            let sysCell = cell as! MenuSystemCell
            sysCell.menuSysItem = items[indexPath.row]
            break
        case .boards(let boards):
            break
        case .categories(let categories):
            break
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
            return CellReuseIdentifier.category.rawValue
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = self.menuSectionTypes[section]
          switch sectionType {
          case .system:
              return MenuHeaderView()
          default:
              return nil
        }
    }
    
}


// datasource
extension SideMenuViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.menuSectionTypes[section] {
        case .system(let items):
            return items.count
        case .boards(let boards):
            return boards.count
        case .categories(let categories): // 分类作为单独一个 cell
            return categories.count + 1
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuSectionTypes.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = self.menuSectionTypes[indexPath.section]
        switch sectionType {
        case .system:
            return 42
        default:
            return 42
        }
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = self.menuSectionTypes[section]
          switch sectionType {
          case .system:
              return 44
          default:
              return 0
        }
    }
}


enum MenuSectionType {
    case system(items: [MenuSystemItem])
    case boards(boards:[Board])
    case categories(categories:[BoardCategoryInfo])
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
