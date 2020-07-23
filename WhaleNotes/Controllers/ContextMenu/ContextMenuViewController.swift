//
//  ContextMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/11.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import ContextMenu

open class ContextMenuViewController: UIViewController {
    
    
    var items:[(SectionMenuItem,[ContextMenuItem])] = []
    var itemTappedCallback:((ContextMenuItem,UIViewController)->Void)!
    
    var menuWidth:CGFloat = 0
    let sectionHeight:CGFloat = 8

    private lazy var  cellBackgroundView = UIView().then {
        $0.backgroundColor = UIColor.popMenuHighlight
    }
    
    static func show(sourceView:UIView,sourceVC: UIViewController,menuWidth:CGFloat = 0,items:[ContextMenuItem],callback:@escaping (ContextMenuItem,UIViewController)->Void) {
        let menuVC =  ContextMenuViewController()
        menuVC.items = [(SectionMenuItem(id: 0),items)]
        menuVC.menuWidth = menuWidth
        menuVC.itemTappedCallback = callback
        
        menuVC.showContextMenu(sourceView: sourceView)
//        ContextMenu.shared.show(
//            sourceViewController: sourceVC,
//            viewController: menuVC,
//            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(shadowOpacity:0.06,xPadding: -100, yPadding: 0, overlayColor: UIColor.black.withAlphaComponent(0.2))),
//            sourceView: sourceView
//        )
//        self.showContextualMenu(menuVC)
    }
    
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.delegate = self
        $0.dataSource = self
        $0.register(ContextMenuCell.self, forCellReuseIdentifier: "ContextMenuCell")
        $0.backgroundColor = .popMenuBg
        
        
        $0.layoutMargins = UIEdgeInsets.zero
        $0.separatorInset = UIEdgeInsets.zero
        $0.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Double.leastNormalMagnitude))
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        
        let maxHeight = 6.7 * ContextMenuCell.cellHeight - 44
        
        var itemsCount:CGFloat = 0
        for item in items {
            itemsCount += CGFloat(item.1.count)
        }
        
        let height = itemsCount * ContextMenuCell.cellHeight - 44
        
        preferredContentSize = CGSize(width: caculateTextWidth(), height: min(height, maxHeight))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func caculateTextWidth() -> CGFloat {
        var longestText = ""
        for section in items {
            section.1.forEach {
                if longestText.count < $0.label.count {
                    longestText =  $0.label
                }
            }
        }
        if menuWidth == 0 {
            return ContextMenuCell.caculateTextWidth(text: longestText)
        }
        return menuWidth
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

struct ContextMenuItem  {
    var label: String
    var icon: String
    var tag: Any?
    var isNeedJump: Bool = false
    var isDestructive: Bool = false
    var isPreventDismiss: Bool = false
}

struct SectionMenuItem {
    var id:Int
    var label:String = ""
}




extension ContextMenuViewController: UITableViewDataSource{
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContextMenuCell", for: indexPath) as! ContextMenuCell
        cell.menuItem = items[indexPath.section].1[indexPath.row]
        cell.selectedBackgroundView = cellBackgroundView
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  ContextMenuCell.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > 0 {
            return sectionHeight
        }
        return CGFloat.leastNormalMagnitude
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > 0 {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: sectionHeight))
            headerView.backgroundColor = .divider
            return headerView
        }
        return nil
    }
}


extension ContextMenuViewController: UITableViewDelegate{
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.section].1[indexPath.row]
        if !item.isNeedJump && !item.isPreventDismiss {
            self.dismiss(animated: true, completion: {
                self.itemTappedCallback(item,self)
            })
        }else {
            tableView.cellForRow(at: indexPath)?.isSelected = false
            _ = self.itemTappedCallback(item,self)
        }

    }

}
