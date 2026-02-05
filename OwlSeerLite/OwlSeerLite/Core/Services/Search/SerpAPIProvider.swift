//
//  SerpAPIProvider.swift
//  OwlSeerLite
//
//  SerpAPI 搜索实现
//

import Foundation

final class SerpAPIProvider: SearchProviderProtocol {
    let providerType: AppSettings.SearchProviderType = .serpapi
    
    private let apiKey: String
    private let baseURL = "https://serpapi.com/search.json"
    private let client = APIClient.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func search(query: String, maxResults: Int) async throws -> [SearchResult] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "engine", value: "google"),
            URLQueryItem(name: "num", value: String(maxResults))
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        let response: SerpAPIResponse = try await client.request(
            url: url,
            method: .get
        )
        
        return response.organicResults?.prefix(maxResults).map { result in
            SearchResult(
                title: result.title,
                url: result.link,
                snippet: result.snippet ?? ""
            )
        } ?? []
    }
}

// MARK: - SerpAPI Response

private struct SerpAPIResponse: Decodable {
    let searchMetadata: SearchMetadata?
    let organicResults: [OrganicResult]?
    
    enum CodingKeys: String, CodingKey {
        case searchMetadata = "search_metadata"
        case organicResults = "organic_results"
    }
    
    struct SearchMetadata: Decodable {
        let status: String?
    }
    
    struct OrganicResult: Decodable {
        let position: Int?
        let title: String
        let link: String
        let snippet: String?
    }
}
