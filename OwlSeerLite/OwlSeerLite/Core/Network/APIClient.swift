//
//  APIClient.swift
//  OwlSeerLite
//
//  轻量级网络层
//

import Foundation

/// 轻量级 API 客户端
final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Standard Request
    
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Encodable? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // 设置默认 headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 添加自定义 headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 设置 body
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // 检查状态码
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.authenticationFailed
            case 429:
                throw APIError.httpError(statusCode: 429, message: "请求过于频繁，请稍后重试")
            case 500...599:
                let message = String(data: data, encoding: .utf8)
                throw APIError.serverError(message ?? "服务器内部错误")
            default:
                let message = String(data: data, encoding: .utf8)
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
            }
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw APIError.timeout
            case .cancelled:
                throw APIError.cancelled
            default:
                throw APIError.networkError(error)
            }
        } catch {
            throw APIError.unknown(error)
        }
    }
    
    // MARK: - Streaming Request
    
    func streamRequest(
        url: URL,
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        body: Encodable? = nil
    ) async throws -> AsyncThrowingStream<Data, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8) {
                            continuation.yield(data)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
