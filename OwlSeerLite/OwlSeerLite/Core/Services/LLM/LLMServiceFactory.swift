//
//  LLMServiceFactory.swift
//  OwlSeerLite
//
//  LLM 服务工厂
//

import Foundation

/// LLM 服务工厂，根据配置创建对应的 Provider
enum LLMServiceFactory {
    
    /// 根据当前设置创建 LLM Provider
    static func createProvider() -> LLMProviderProtocol? {
        let settings = SettingsManager.shared.settings
        let keychain = KeychainManager.shared
        
        switch settings.llmMode {
        case .builtin:
            // 使用预置 Key (Kimi 2.5 API)
            guard APIKeyObfuscator.hasBuiltinKey else {
                return nil
            }
            let apiKey = APIKeyObfuscator.builtinAPIKey
            // 预置 Key 使用 Kimi 2.5 (月之暗面)，兼容 OpenAI 格式
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: "https://api.moonshot.cn/v1",
                model: "moonshot-v1-auto"  // Kimi 2.5 自动选择上下文长度
            )
            
        case .custom:
            // 使用用户自定义 Key
            guard let apiKey = keychain.retrieve(for: .llmAPIKey),
                  let provider = settings.customLLMProvider else {
                return nil
            }
            
            let baseURL = settings.customBaseURL
            let model = settings.selectedModel ?? provider.availableModels.first ?? ""
            
            switch provider {
            case .openai:
                return OpenAIProvider(apiKey: apiKey, baseURL: baseURL, model: model)
            case .anthropic:
                return AnthropicProvider(apiKey: apiKey, baseURL: baseURL, model: model)
            case .gemini:
                return GeminiProvider(apiKey: apiKey, baseURL: baseURL, model: model)
            case .deepseek:
                // DeepSeek uses OpenAI-compatible API format
                return OpenAIProvider(apiKey: apiKey, baseURL: baseURL ?? provider.defaultBaseURL, model: model)
            case .kimi:
                // Kimi/Moonshot uses OpenAI-compatible API format
                return OpenAIProvider(apiKey: apiKey, baseURL: baseURL ?? provider.defaultBaseURL, model: model)
            }
        }
    }
    
    /// 检查是否已配置 LLM 服务
    static var isConfigured: Bool {
        let settings = SettingsManager.shared.settings
        
        switch settings.llmMode {
        case .builtin:
            return APIKeyObfuscator.hasBuiltinKey
        case .custom:
            return KeychainManager.shared.hasKey(for: .llmAPIKey) &&
                   settings.customLLMProvider != nil
        }
    }
    
    /// 获取当前使用的模式描述
    static var currentModeDescription: String {
        let settings = SettingsManager.shared.settings
        
        switch settings.llmMode {
        case .builtin:
            return "免费体验模式"
        case .custom:
            if let provider = settings.customLLMProvider {
                return "\(provider.displayName) (自定义)"
            }
            return "自定义模式"
        }
    }
}
