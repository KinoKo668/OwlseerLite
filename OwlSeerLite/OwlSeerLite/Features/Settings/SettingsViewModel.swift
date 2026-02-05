//
//  SettingsViewModel.swift
//  OwlSeerLite
//
//  设置 ViewModel
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - LLM Settings
    
    var llmMode: AppSettings.LLMMode {
        get { SettingsManager.shared.settings.llmMode }
        set {
            SettingsManager.shared.settings.llmMode = newValue
            objectWillChange.send()
        }
    }
    
    var customLLMProvider: AppSettings.LLMProviderType? {
        get { SettingsManager.shared.settings.customLLMProvider }
        set {
            SettingsManager.shared.settings.customLLMProvider = newValue
            objectWillChange.send()
        }
    }
    
    var hasCustomLLMKey: Bool {
        KeychainManager.shared.hasKey(for: .llmAPIKey)
    }
    
    // MARK: - Search Settings
    
    var isSearchEnabled: Bool {
        get { SettingsManager.shared.settings.searchProvider != nil }
        set {
            if newValue {
                SettingsManager.shared.settings.searchProvider = .tavily
            } else {
                SettingsManager.shared.settings.searchProvider = nil
            }
            objectWillChange.send()
        }
    }
    
    var searchProvider: AppSettings.SearchProviderType? {
        get { SettingsManager.shared.settings.searchProvider }
        set {
            SettingsManager.shared.settings.searchProvider = newValue
            objectWillChange.send()
        }
    }
    
    var hasSearchKey: Bool {
        KeychainManager.shared.hasKey(for: .searchAPIKey)
    }
    
    // MARK: - Language Settings
    
    var appLanguage: AppSettings.AppLanguage {
        get { SettingsManager.shared.settings.appLanguage }
        set {
            SettingsManager.shared.settings.appLanguage = newValue
            objectWillChange.send()
        }
    }
    
    // MARK: - Usage Statistics
    
    var usedCount: Int {
        DailyUsageManager.shared.limit - DailyUsageManager.shared.remainingCount
    }
    
    var dailyLimit: Int {
        DailyUsageManager.shared.limit
    }
    
    var usageProgress: Double {
        DailyUsageManager.shared.usageProgress
    }
    
    var resetTime: String {
        DailyUsageManager.shared.formattedResetTime
    }
    
    // MARK: - Methods
    
    func showMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
