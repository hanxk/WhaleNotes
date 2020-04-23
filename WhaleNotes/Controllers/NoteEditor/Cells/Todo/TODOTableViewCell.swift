//
//  TODOTableViewCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/22.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class TODOTableViewCell: UITableViewCell {
    
    let todoCellHeight: CGFloat = 34
    
    let tableView: UITableView = UITableView().then {
//        $0.rowHeight = UITableView.automaticDimension
//        $0.estimatedRowHeight = 44
        $0.separatorStyle = .none
    }
    var textChanged: ((String) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.selectionStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        tableView.register(TODOItemCell.self, forCellReuseIdentifier: CellType.item.rawValue)
        contentView.addSubview(self.tableView)
        tableView.snp.makeConstraints { (make) in
//            make.left.equalTo(self.contentView).offset(10)
//            make.right.equalTo(self.contentView)
//            make.top.equalTo(self.contentView).offset(10)
//            make.bottom.equalTo(self.contentView).offset(-10)
           make.top.left.right.equalTo(contentView)
        }
//        tableView.backgroundColor = .red
    }
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
}

extension TODOTableViewCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: CellType.item.rawValue, for: indexPath) as! TODOItemCell
        cell.textChanged = { [weak self] text in
//            DispatchQueue.main.async {
//                UIView.performWithoutAnimation {
//                }
//            }
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
//            self?.textChanged?(text)
        }
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        let cell =  tableView.dequeueReusableCell(withIdentifier: CellType.item.rawValue, for: indexPath) as! TODOItemCell
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! TODOItemCell
        return cell.cellHeight
    }
}


extension TODOTableViewCell: UITableViewDelegate {
}

private enum CellType: String {
    case item = "TODOItemCell"
}
