//
//  Date+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SwiftDate

extension Date {
  var formatted: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateFormat = "yyyy-MM-dd"
    return  formatter.string(from: self as Date)
  }
    
    var formattedYMDHM: String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
      return  formatter.string(from: self)
    }
  
  var formattedYYYYMMDDHHMMSS: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年MM月dd HH:mm:ss"
    return  formatter.string(from: self)
  }
  var formattedYYYYMMDD: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return  formatter.string(from: self as Date)
  }
  
  var formattedYYMM: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM"
    return  formatter.string(from: self as Date)
  }
  var formatted2: String {
    if isToday() {
      return "今天"
    }
    if isYesterday() {
      return "昨天"
    }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    if isThisYear() {
      formatter.dateFormat = "MM-dd"
      return  formatter.string(from: self as Date)
    }
    formatter.dateFormat = "yyyy-MM-dd"
    return  formatter.string(from: self as Date)
  }
  
  var formatted4: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    if isThisYear() {
      formatter.dateFormat = "MM月dd日"
      return  formatter.string(from: self as Date)
    }
    formatter.dateFormat = "yyyy年MM月dd日"
    return  formatter.string(from: self as Date)
  }
  
  func isToday() -> Bool{
    let calendar = Calendar.current
    let unit: Set<Calendar.Component> = [.day,.month,.year]
    let nowComps = calendar.dateComponents(unit, from: Date())
    let selfCmps = calendar.dateComponents(unit, from: self)
    
    return (selfCmps.year == nowComps.year) &&
      (selfCmps.month == nowComps.month) &&
      (selfCmps.day == nowComps.day)
    
  }
  
  var formatted3: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    if isToday() {
      formatter.dateFormat = "HH:mm"
      let timeStr =  formatter.string(from: self as Date)
      return "今天 \(timeStr)"
    }
    if isYesterday() {
      formatter.dateFormat = "HH:mm"
      let timeStr =  formatter.string(from: self as Date)
      return "昨天 \(timeStr)"
    }
    if isThisYear() {
      formatter.dateFormat = "MM-dd"
      return  formatter.string(from: self as Date)
    }
    formatter.dateFormat = "yyyy-MM-dd"
    return  formatter.string(from: self as Date)
  }
  
  
  
  // x年，x月，x天，
  var dateBetweenNow:String {
    
    func createDate(year: Int, month: Int, day: Int) -> Date {

      var dateComponents = DateComponents()
      dateComponents.timeZone = .current
      dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
      dateComponents.hour = 10
      dateComponents.minute = 10

        let date = Calendar.current.date(from: dateComponents)!
        return date
    }
    
    let calendar = Calendar.current
    let currentDate = createDate(year: calendar.component(.year, from: date), month: calendar.component(.month, from: date), day: calendar.component(.day, from: date))
    
    let now = Date()
    let nowDate = createDate(year: calendar.component(.year, from: now), month: calendar.component(.month, from: now), day: calendar.component(.day, from: now))
    
    let components = Calendar.current.dateComponents([.year,.month,.day], from: currentDate, to: nowDate)
    
    let year = components.year ?? 0
    if year > 0 {
      return "\(year)年"
    }
    let month = components.month ?? 0
    if month > 0 {
      return "\(month)月"
    }
    let day = components.day ?? 0
    return "\(day+1)天"
  }
  

  
  var dateBetweenNow2:String {
    let components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: self, to: Date())
    
    let year = components.year ?? 0
    if year > 0 {
      return "\(year)年"
    }
    let month = components.month ?? 0
    if month > 0 {
      return "\(month)月"
    }
    
    let day = components.day ?? 0
    if day > 0 {
    }
    let hour = components.hour ?? 0
    if hour > 0 {
      return "\(hour)时"
    }
    let minute = components.minute ?? 0
    if minute > 0 {
      return "\(minute)分"
    }
    let second = components.second ?? 0
    return "\(second)秒"
  }
  
  

  
  /**
   *  是否为昨天
   */
  func isYesterday() -> Bool {
    let calendar = Calendar.current
    let unit: Set<Calendar.Component> = [.day,.month,.year]
    let nowComps = calendar.dateComponents(unit, from: Date())
    let selfCmps = calendar.dateComponents(unit, from: self)
    if selfCmps.day == nil || nowComps.day == nil {
      return false
    }
    let count = nowComps.day! - selfCmps.day!
    return (selfCmps.year == nowComps.year) &&
      (selfCmps.month == nowComps.month) &&
      (count == 1)
  }
  
  func isThisYear() -> Bool {
    let calendar = Calendar.current
    let nowCmps = calendar.dateComponents([.year], from: Date())
    let selfCmps = calendar.dateComponents([.year], from: self)
    let result = nowCmps.year == selfCmps.year
    return result
  }
    
    func toSQLDateString() -> String {
        
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter.string(from: self)
    }
  
}

extension Int64 {
  func intToDate(timeInterval:Int64)->Date {
    return Date(timeIntervalSince1970: TimeInterval(timeInterval / 1000))
  }
}


extension String {
  func dateFromSQLiteTime() -> Date? {
    return  self.toDate()?.date
  }
  
  func dateFromSQLiteTime2() -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return dateFormatter.date(from: self)
  }
}


extension Date {
    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}
