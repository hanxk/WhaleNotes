//
//  DBResult.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

//enum DBResult<Value> {
//  case success(Value)
//  case failure(DBError)
//  
//  var failurValue: DBError? {
//    switch self {
//    case .failure(let err):
//      return err
//    default:
//      return nil
//    }
//  }
//  
//  var successValue: Value? {
//    switch self {
//    case .failure(_):
//      return nil
//    case .success(let value):
//      return value
//    }
//  }
//}
//
struct DBError:Error {
  let code:DBErrorCode
  let message:String
  
    init(code:DBErrorCode = .normal, message:String = "db error") {
    self.code = code
    self.message = message
  }
}
//
//
enum DBErrorCode {
  case normal
}
