//
//  Date+Extensions.swift
//  OwlSeerLite
//
//  日期扩展
//

import Foundation

extension Date {
    /// 格式化为相对时间（如"刚刚"、"5分钟前"）
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh-Hans")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// 格式化为时间字符串（HH:mm）
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 格式化为日期时间字符串
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 格式化为短日期字符串
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: self)
    }
    
    /// 检查是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 检查是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 获取当天开始时间
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天结束时间
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// 智能格式化（今天显示时间，其他显示日期）
    var smartFormatted: String {
        if isToday {
            return timeString
        } else if isYesterday {
            return "昨天 \(timeString)"
        } else {
            return "\(shortDateString) \(timeString)"
        }
    }
}
