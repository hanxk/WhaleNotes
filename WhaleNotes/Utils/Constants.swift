//
//  Constants.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/11.
//  Copyright © 2021 hanxk. All rights reserved.
//
import UIKit


var windowWidth: CGFloat { return UIScreen.main.bounds.width}
var windowHeight: CGFloat { return UIScreen.main.bounds.height }
let itunesSecret = "cf86d5cf3c0e440692140e5e80fd376e"
let imageUploadUrl = "https://sm.ms/api/v2/upload"
let smKey = "WXABjEOoe8L7NApRlHpkKsglLauJXqXl"
let umengKey = "5d2594e20cafb28ba1000dbe"
let buglyId = "57bc8a7c74"

var bottomInset: CGFloat {
    if #available(iOS 11.0, *) {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    } else {
        return 0
    }
}

var topInset: CGFloat {
    if #available(iOS 11.0, *) {
        return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 20
    } else {
        return 20
    }
}

let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
let supportPath =  NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""

let configPath = supportPath
let resourcesPath = supportPath + "/Resources"
let tempPath = supportPath + "/Temp"
let externalPath = supportPath + "/Inbox"
let inboxPath = documentPath + "/Inbox"

let cloudPath: String = {
    guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        return ""
    }
    return ubiquityURL.path
}()

let PAGESIZE = 10

let HASHTAG = "#"
let ENTER_KEY:Character = "\n"
let SPACE_KEY:Character = " "

var window:UIWindow  {
    return UIApplication.shared.windows[0]
//       let topPadding = window.safeAreaInsets.top
//       let bottomPadding = window.safeAreaInsets.bottom
}

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
