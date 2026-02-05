//
//  SearchProvider.swift
//  OwlSeerLite
//
//  搜索服务协议
//

import Foundation

// MARK: - Protocol

protocol SearchProviderProtocol {
    var providerType: AppSettings.SearchProviderType { get }
    func search(query: String, maxResults: Int) async throws -> [SearchResult]
}

// MARK: - Search Result

struct SearchResult: Codable, Identifiable {
    let id: String
    let title: String
    let url: String
    let snippet: String
    
    init(id: String = UUID().uuidString, title: String, url: String, snippet: String) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}

// MARK: - Search Service Factory

enum SearchServiceFactory {
    
    /// 根据当前设置创建搜索 Provider
    static func createProvider() -> SearchProviderProtocol? {
        let settings = SettingsManager.shared.settings
        let keychain = KeychainManager.shared
        
        guard let providerType = settings.searchProvider,
              let apiKey = keychain.retrieve(for: .searchAPIKey) else {
            return nil
        }
        
        switch providerType {
        case .tavily:
            return TavilyProvider(apiKey: apiKey)
        case .serpapi:
            return SerpAPIProvider(apiKey: apiKey)
        }
    }
    
    /// 检查是否已配置搜索服务
    static var isConfigured: Bool {
        let settings = SettingsManager.shared.settings
        return settings.searchProvider != nil &&
               KeychainManager.shared.hasKey(for: .searchAPIKey)
    }
}
