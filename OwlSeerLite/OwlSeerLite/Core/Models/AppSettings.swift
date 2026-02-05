//
//  AppSettings.swift
//  OwlSeerLite
//
//  App Configuration Model
//

import Foundation
import Combine

struct AppSettings: Codable {
    // LLM Config
    var llmMode: LLMMode
    var customLLMProvider: LLMProviderType?
    var customBaseURL: String?
    var selectedModel: String?
    
    // Search Config
    var searchProvider: SearchProviderType?
    
    // Language Config
    var appLanguage: AppLanguage
    
    // Computed Properties
    var isSearchEnabled: Bool { searchProvider != nil }
    var isCustomMode: Bool { llmMode == .custom }
    
    // Default Configuration
    static let `default` = AppSettings(
        llmMode: .builtin,
        customLLMProvider: nil,
        customBaseURL: nil,
        selectedModel: nil,
        searchProvider: nil,
        appLanguage: .english
    )
    
    enum LLMMode: String, Codable {
        case builtin   // 使用预置 Key
        case custom    // BYOK (Bring Your Own Key)
    }
    
    enum LLMProviderType: String, Codable, CaseIterable, Identifiable {
        case openai
        case anthropic
        case gemini
        case deepseek
        case kimi
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .openai: return "OpenAI"
            case .anthropic: return "Anthropic"
            case .gemini: return "Google Gemini"
            case .deepseek: return "DeepSeek"
            case .kimi: return "Kimi (Moonshot)"
            }
        }
        
        var defaultBaseURL: String {
            switch self {
            case .openai: return "https://api.openai.com/v1"
            case .anthropic: return "https://api.anthropic.com/v1"
            case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
            case .deepseek: return "https://api.deepseek.com/v1"
            case .kimi: return "https://api.moonshot.cn/v1"
            }
        }
        
        var availableModels: [String] {
            switch self {
            case .openai: return [
                "gpt-5.2",
                "gpt-5-pro",
                "gpt-5",
                "gpt-5-mini",
                "o3",
                "o4-mini",
                "gpt-4o",
                "gpt-4o-mini"
            ]
            case .anthropic: return [
                "claude-opus-4",
                "claude-sonnet-4",
                "claude-3-5-sonnet-20241022",
                "claude-3-haiku-20240307"
            ]
            case .gemini: return [
                "gemini-3-pro",
                "gemini-3-flash",
                "gemini-2.5-pro",
                "gemini-2.5-flash",
                "gemini-2.0-flash"
            ]
            case .deepseek: return [
                "deepseek-chat",
                "deepseek-reasoner"
            ]
            case .kimi: return [
                "kimi-k2.5",
                "kimi-k2-0905",
                "kimi-k2-thinking",
                "moonshot-v1-128k",
                "moonshot-v1-32k"
            ]
            }
        }
    }
    
    enum SearchProviderType: String, Codable, CaseIterable, Identifiable {
        case tavily
        case serpapi
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .tavily: return "Tavily"
            case .serpapi: return "SerpAPI"
            }
        }
    }
    
    enum AppLanguage: String, Codable, CaseIterable, Identifiable {
        case english = "en"
        case chinese = "zh-Hans"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "简体中文"
            }
        }
    }
}

// MARK: - Settings Manager

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "app_settings"
    
    private init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = .default
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func reset() {
        settings = .default
    }
}
