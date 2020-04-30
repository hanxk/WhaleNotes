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
    
    private var items:[MenuItem] = [
        MenuItem(label: "文本", icon: "textbox", type: .text),
        MenuItem(label: "待办事项", icon: "checkmark.square", type: .todo),
        MenuItem(label: "从相册选择", icon: "photo.on.rectangle", type: .image),
        MenuItem(label: "拍照", icon: "camera", type: .camera),
    ]
    
    var cellTapped:((MenuType) -> Void)?
    
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

struct MenuItem  {
    var label: String
    var icon: String
    var type: MenuType
}

enum MenuType {
    case text
    case image
    case camera
    case todo
}



extension PopBlocksViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockMenuCell", for: indexPath) as! BlockMenuCell
        cell.menuItem = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
}


extension PopBlocksViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.cellTapped?(item.type)
    }

}
