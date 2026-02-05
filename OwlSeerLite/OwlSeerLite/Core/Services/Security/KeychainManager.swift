//
//  KeychainManager.swift
//  OwlSeerLite
//
//  Keychain 安全存储封装
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    enum KeyType: String, CaseIterable {
        case llmAPIKey = "com.owlseer.llm.apikey"
        case searchAPIKey = "com.owlseer.search.apikey"
        
        var displayName: String {
            switch self {
            case .llmAPIKey: return "LLM API Key"
            case .searchAPIKey: return "搜索 API Key"
            }
        }
    }
    
    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case encodingFailed
        
        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "保存失败 (错误码: \(status))"
            case .retrieveFailed(let status):
                return "读取失败 (错误码: \(status))"
            case .deleteFailed(let status):
                return "删除失败 (错误码: \(status))"
            case .encodingFailed:
                return "数据编码失败"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 保存 API Key 到 Keychain
    func save(key: String, for type: KeyType) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // 先删除旧值（如果存在）
        delete(for: type)
        
        // 添加新值
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: type.rawValue,
            kSecAttrService as String: "com.owlseer.lite",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// 从 Keychain 读取 API Key
    func retrieve(for type: KeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: type.rawValue,
            kSecAttrService as String: "com.owlseer.lite",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// 删除 Keychain 中的 API Key
    @discardableResult
    func delete(for type: KeyType) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: type.rawValue,
            kSecAttrService as String: "com.owlseer.lite"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// 检查是否存在指定类型的 Key
    func hasKey(for type: KeyType) -> Bool {
        retrieve(for: type) != nil
    }
    
    /// 清除所有存储的 Key
    func clearAll() {
        for type in KeyType.allCases {
            delete(for: type)
        }
    }
    
    /// 验证 Key 格式（基础检查）
    func validateKeyFormat(_ key: String, provider: AppSettings.LLMProviderType) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch provider {
        case .openai:
            // OpenAI Key 格式: sk-xxx 或 sk-proj-xxx
            return trimmed.hasPrefix("sk-") && trimmed.count > 20
        case .anthropic:
            // Anthropic Key 格式: sk-ant-xxx
            return trimmed.hasPrefix("sk-ant-") && trimmed.count > 20
        case .gemini:
            // Gemini Key 格式: AIza...
            return trimmed.hasPrefix("AIza") && trimmed.count > 30
        case .deepseek:
            // DeepSeek Key 格式: sk-xxx
            return trimmed.hasPrefix("sk-") && trimmed.count > 20
        case .kimi:
            // Kimi/Moonshot Key 格式: sk-xxx
            return trimmed.hasPrefix("sk-") && trimmed.count > 20
        }
    }
}
