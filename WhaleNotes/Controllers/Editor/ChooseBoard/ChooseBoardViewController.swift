//
//  ChooseBoardViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class ChooseBoardViewController:UIViewController {
    
}

enum BoardSectionType {
    case system(systemBoards: [Board])
    case boards
    case categories
}
