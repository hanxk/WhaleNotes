//
//  NoteDetailMenuController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import ContextMenu

class NoteDateViewController: UIViewController {
    
    
//    var items:[ContextMenuItem] = [
//        ContextMenuItem(label: "置顶", icon: "pin", tag: 1),
//        ContextMenuItem(label: "便签板", icon: "rectangle.on.rectangle.angled", tag: 1),
//        ContextMenuItem(label: "背景色", icon: "paintbrush", tag: 1),
//        ContextMenuItem(label: "移动到废纸篓", icon: "trash", tag: 1),
//    ]
    
    var items:[(String,String)] = []
    var noteBlock:BlockInfo!{
        didSet {
            self.items.append(("更新时间",noteBlock.updatedAt.formattedYMDHM))
            self.items.append(("创建时间",noteBlock.block.createdAt.formattedYMDHM))
            self.tableView.reloadData()
        }
    }
    
    var itemTappedCallback:((ContextMenuItem)->Void)!
    
    private var menuWidth:CGFloat = 0

    private lazy var  cellBackgroundView = UIView().then {
        $0.backgroundColor = UIColor.tappedColor
    }
    
    
    private lazy var tableView = UITableView().then { [weak self] in
        $0.separatorColor = .clear
        $0.delegate = self
        $0.dataSource = self
        $0.register(NoteDateCell.self, forCellReuseIdentifier: "NoteDateCell")
        $0.separatorStyle = .singleLine
        
        $0.layoutMargins = UIEdgeInsets.zero
        $0.separatorInset = UIEdgeInsets.zero
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.title = "显示信息"
    }
    
    private func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
}



extension NoteDateViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteDateCell", for: indexPath) as! NoteDateCell
        cell.dateInfo = self.items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}


extension NoteDateViewController: UITableViewDelegate{
    
    
}
