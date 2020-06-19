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
    
    
    var items:[ContextMenuItem]!
    var itemTappedCallback:((ContextMenuItem,UIViewController)->Void)!
    
    var menuWidth:CGFloat = 0

    private lazy var  cellBackgroundView = UIView().then {
        $0.backgroundColor = UIColor.tappedColor
    }
    
    static func show(sourceView:UIView,sourceVC: UIViewController,menuWidth:CGFloat = 0,items:[ContextMenuItem],callback:@escaping (ContextMenuItem,UIViewController)->Void) {
        let menuVC =  ContextMenuViewController()
        menuVC.items = items
        menuVC.menuWidth = menuWidth
        menuVC.itemTappedCallback = callback
        ContextMenu.shared.show(
            sourceViewController: sourceVC,
            viewController: menuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(shadowOpacity:0.06,overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: sourceView
        )
    }
    
    
    private lazy var tableView = UITableView().then { [weak self] in
                $0.separatorColor = .clear
        $0.delegate = self
        $0.dataSource = self
        $0.register(ContextMenuCell.self, forCellReuseIdentifier: "ContextMenuCell")
        $0.separatorStyle = .singleLine
        
        $0.layoutMargins = UIEdgeInsets.zero
        $0.separatorInset = UIEdgeInsets.zero
        $0.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Double.leastNormalMagnitude))
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        preferredContentSize = CGSize(width: caculateTextWidth(), height: CGFloat(items.count) * ContextMenuCell.cellHeight - 44)
        self.view.backgroundColor = .blue
        
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
        items.forEach {
            if longestText.count < $0.label.count {
                longestText =  $0.label
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
}




extension ContextMenuViewController: UITableViewDataSource{
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContextMenuCell", for: indexPath) as! ContextMenuCell
        cell.menuItem = items[indexPath.row]
        cell.selectedBackgroundView = cellBackgroundView
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  ContextMenuCell.cellHeight
    }
    
}


extension ContextMenuViewController: UITableViewDelegate{
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        if !item.isNeedJump {
            self.dismiss(animated: true, completion: {
                self.itemTappedCallback(item,self)
            })
        }else {
            tableView.cellForRow(at: indexPath)?.isSelected = false
            self.itemTappedCallback(item,self)
        }

    }

}
