//
//  Constant.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/11.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

let itunesSecret = "cf86d5cf3c0e440692140e5e80fd376e"
let imageUploadUrl = "https://sm.ms/api/v2/upload"
let smKey = "WXABjEOoe8L7NApRlHpkKsglLauJXqXl"
let umengKey = "5d2594e20cafb28ba1000dbe"
let buglyId = "57bc8a7c74"

var windowWidth: CGFloat { return UIApplication.shared.keyWindow?.w ?? 0}
var windowHeight: CGFloat { return UIApplication.shared.keyWindow?.h ?? 0 }
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

let appID = "1472328263"
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
let premiumMonthlyProductID = "com.qinxiu.markdown.premium.monthly"
let premiumYearlyProductID = "com.qinxiu.markdown.premium.yearly"
let premiumForeverProductID = "com.qinxiu.markdown.premium.forever"

//itms-services://?action=purchaseIntent&bundleId=com.qinxiu.markdown&productIdentifier=com.qinxiu.markdown.premium.yearly

let isPad = UIDevice.current.userInterfaceIdiom == .pad

let passedDate = Date(fromString: "2020-05-26", format: "yyyy-MM-dd")!
 
let rateUrl = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1472328263&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"

var emailUrl: String = {
    return "mailto:zhubingcheng.dev@gmail.com?subject=Markdown%20\(Configure.shared.currentVerion ?? "")%20\(isPad ? "iPad" : "iPhone")%20\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)&body="
}()

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
