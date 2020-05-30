//
//  Log.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class Logger {
    
    private init(){}
    
    static func info( _ text: String, _ argument: Any? = nil) {
        if let argument = argument {
            print(text + "_" + String(describing: argument))
        }else {
            print(text)
        }
    }
    static func error( _ error: NSError) {
        print(error)
    }
    static func error( _ error: Error) {
        print(error)
    }
}

