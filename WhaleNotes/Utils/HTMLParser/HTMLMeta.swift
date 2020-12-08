//
//  HTMLMeta.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/8.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct HTMLMeta  {
    var title:String = ""
    var image:String = ""
    var description:String = ""
    var siteName:String = ""
    var url:String = ""
    
    init(title:String,description:String,image:String,siteName:String,url:String) {
        self.title  = title
        self.description  = description
        self.image  = image
        self.siteName  = siteName
        self.url  = url
    }
    //                let doc: Document = try SwiftSoup.parseBodyFragment(html)
    //                var title = try doc.select("meta[property='og:title']").attr("content")
    //                let image = try doc.select("meta[property='og:image']").attr("content")
    //                let description = try doc.select("meta[property='og:description']").attr("content")
    //                if title.isEmpty {
    //                    let siteName = try doc.select("meta[property='og:site_name']").attr("content")
    //                    title = siteName
    //                }
}
