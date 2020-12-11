//
//  MenuController.swift
//  Menu Conroller
//
//  Created by Anmol Rajpal on 15/05/20.
//  Copyright © 2020 Anmol Rajpal. All rights reserved.
//

import UIKit

public class MenuController:InteractiveModalViewController {
    public required init(headerView:UIView? = nil, headerHeight:CGFloat = 54.0, actions:[UIControlMenuAction]) {
        super.init(controller: UIControlMenuController(headerView: headerView, headerHeight: headerHeight, actions: actions))
    }
}
