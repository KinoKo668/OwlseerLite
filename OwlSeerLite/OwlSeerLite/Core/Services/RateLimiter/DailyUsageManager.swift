//
//  DailyUsageManager.swift
//  OwlSeerLite
//
//  本地限流管理器
//

import Foundation
import Combine

final class DailyUsageManager: ObservableObject {
    static let shared = DailyUsageManager()
    
    // MARK: - Configuration
    
    /// 每日免费消息限额
    private let dailyLimit = 10
    
    // MARK: - Storage Keys
    
    private let userDefaults = UserDefaults.standard
    private let usageCountKey = "daily_usage_count"
    private let lastResetDateKey = "last_reset_date"
    
    // MARK: - Published Properties
    
    @Published private(set) var currentUsage: Int = 0
    
    // MARK: - Computed Properties
    
    /// 剩余可用次数
    var remainingCount: Int {
        resetIfNeeded()
        return max(0, dailyLimit - currentUsage)
    }
    
    /// 每日限额
    var limit: Int {
        dailyLimit
    }
    
    /// 使用进度 (0.0 - 1.0)
    var usageProgress: Double {
        Double(currentUsage) / Double(dailyLimit)
    }
    
    /// 重置时间描述
    var resetTimeDescription: String {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            return "明天"
        }
        let midnight = calendar.startOfDay(for: tomorrow)
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh-Hans")
        
        return formatter.localizedString(for: midnight, relativeTo: now)
    }
    
    /// 格式化的重置时间
    var formattedResetTime: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return "明天 00:00"
        }
        let midnight = calendar.startOfDay(for: tomorrow)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "明天 HH:mm"
        
        return formatter.string(from: midnight)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadCurrentUsage()
    }
    
    // MARK: - Public Methods
    
    /// 检查是否可以发送消息
    func canSendMessage() -> Bool {
        resetIfNeeded()
        return currentUsage < dailyLimit
    }
    
    /// 记录一次使用
    func recordUsage() {
        resetIfNeeded()
        currentUsage += 1
        userDefaults.set(currentUsage, forKey: usageCountKey)
    }
    
    /// 获取使用状态描述
    func getUsageStatusText() -> String {
        if canSendMessage() {
            return "今日剩余 \(remainingCount)/\(dailyLimit) 条消息"
        } else {
            return "今日免费额度已用完，\(resetTimeDescription)重置"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentUsage() {
        resetIfNeeded()
        currentUsage = userDefaults.integer(forKey: usageCountKey)
    }
    
    private func resetIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastReset = userDefaults.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            
            if lastResetDay < today {
                // 新的一天，重置计数
                performReset()
            }
        } else {
            // 首次使用，初始化日期
            userDefaults.set(Date(), forKey: lastResetDateKey)
        }
    }
    
    private func performReset() {
        currentUsage = 0
        userDefaults.set(0, forKey: usageCountKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// 重置使用次数（仅调试用）
    func debugReset() {
        performReset()
    }
    
    /// 设置使用次数（仅调试用）
    func debugSetUsage(_ count: Int) {
        currentUsage = min(count, dailyLimit)
        userDefaults.set(currentUsage, forKey: usageCountKey)
    }
    #endif
}
