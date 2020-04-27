//
//  PopBlocksViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class PopBlocksViewController: UIViewController {
    
    private let cellHeight: CGFloat = 55
    
    private var items:[BlockItem] = [
        BlockItem(label: "文本", icon: "textbox", createMode: .text),
        BlockItem(label: "清单", icon: "checkmark.square", createMode: .todo),
        BlockItem(label: "图片", icon: "photo", createMode: .image),
    ]
    
    var cellTapped:((CreateMode) -> Void)?
    
    private lazy var tableView = UITableView().then { [weak self] in
        //        $0.separatorColor = .clear
        $0.delegate = self
        $0.dataSource = self
        $0.register(BlockMenuCell.self, forCellReuseIdentifier: "BlockMenuCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        
        preferredContentSize = CGSize(width: 120, height: items.count * Int(cellHeight) - 44)
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
    
}

struct BlockItem  {
    var label: String
    var icon: String
    var createMode: CreateMode
}


extension PopBlocksViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockMenuCell", for: indexPath) as! BlockMenuCell
        cell.blockItem = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
}


extension PopBlocksViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.cellTapped?(item.createMode)
    }

}
