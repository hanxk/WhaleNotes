//
//  Constants.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/21.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

enum ConstantsUI {
     static let tagDefaultImageName = "grid"
}

func logi(_ info:String) {
    Logger.info(info)
}

func loge(_ error:Error) {
    Logger.error(error)
}
func loge(_ text:String, _ error:Error) {
    Logger.error(text,error)
}
