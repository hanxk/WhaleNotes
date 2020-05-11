//
//  ContextMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/11.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import ContextMenu

class ContextMenuViewController: UIViewController {
    
    private let cellHeight: CGFloat = 55
    
    var items:[ContextMenuItem]!
    var itemTappedCallback:((ContextMenuItem)->Void)!
    
    static func show(sourceView:UIView,sourceVC: UIViewController,items:[ContextMenuItem],callback:@escaping (ContextMenuItem)->Void) {
        let menuVC =  ContextMenuViewController()
        menuVC.items = items
        menuVC.itemTappedCallback = callback
        ContextMenu.shared.show(
            sourceViewController: sourceVC,
            viewController: menuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: sourceView
        )
    }
    
    
    private lazy var tableView = UITableView().then { [weak self] in
        //        $0.separatorColor = .clear
        $0.delegate = self
        $0.dataSource = self
        $0.register(ContextMenuCell.self, forCellReuseIdentifier: "ContextMenuCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        preferredContentSize = CGSize(width: caculateTextWidth(), height: CGFloat(items.count) * cellHeight - 44)
        self.view.backgroundColor = .blue
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        return BlockMenuCell.caculateTextWidth(text: longestText)
    }
    
}

struct ContextMenuItem  {
    var label: String
    var icon: String
}




extension ContextMenuViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContextMenuCell", for: indexPath) as! ContextMenuCell
        cell.menuItem = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
}


extension ContextMenuViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.dismiss(animated: true, completion: {
            self.itemTappedCallback(item)
        })
    }

}
