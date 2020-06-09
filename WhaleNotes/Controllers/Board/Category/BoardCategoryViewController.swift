//
//  BoardCategoryViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


class BoardCategoryViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "选择分类"
        self.setupUI()
    }
    
    private func setupUI() {
        let newCategory =  UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(self.addNewCategory))
        navigationItem.rightBarButtonItems = [newCategory]
    }
    
    @objc private func addNewCategory() {
        showInputAlertDialog()
    }
    
    
    
    private func showInputAlertDialog() {
        let alert = UIAlertController(title: "新建分类", message: "", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "输入分类名称"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields?[0] {
                
            }
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields?[0] {
              
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}


extension BoardCategoryViewController {
    
    private func loadCategories() {
        
    }
    
    private func addCategory() {
        
    }
    
    private func delCategory() {
        
    }
    
    private func updateCategory() {
        
    }
}
