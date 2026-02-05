//
//  TavilyProvider.swift
//  OwlSeerLite
//
//  Tavily 搜索 API 实现
//

import Foundation

final class TavilyProvider: SearchProviderProtocol {
    let providerType: AppSettings.SearchProviderType = .tavily
    
    private let apiKey: String
    private let baseURL = "https://api.tavily.com"
    private let client = APIClient.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func search(query: String, maxResults: Int) async throws -> [SearchResult] {
        guard let url = URL(string: "\(baseURL)/search") else {
            throw APIError.invalidURL
        }
        
        let request = TavilyRequest(
            apiKey: apiKey,
            query: query,
            searchDepth: "basic",
            maxResults: maxResults
        )
        
        let response: TavilyResponse = try await client.request(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: request
        )
        
        return response.results.map { result in
            SearchResult(
                title: result.title,
                url: result.url,
                snippet: result.content
            )
        }
    }
}

// MARK: - Tavily Request/Response

private struct TavilyRequest: Encodable {
    let apiKey: String
    let query: String
    let searchDepth: String
    let maxResults: Int
    
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case query
        case searchDepth = "search_depth"
        case maxResults = "max_results"
    }
}

private struct TavilyResponse: Decodable {
    let query: String?
    let results: [TavilyResult]
    
    struct TavilyResult: Decodable {
        let title: String
        let url: String
        let content: String
        let score: Double?
    }
}
