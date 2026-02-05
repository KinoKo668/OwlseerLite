//
//  APIError.swift
//  OwlSeerLite
//
//  API 错误定义
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case rateLimitExceeded(resetTime: String)
    case authenticationFailed
    case serverError(String)
    case timeout
    case cancelled
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidRequest:
            return "请求格式错误"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .httpError(let statusCode, let message):
            return "HTTP 错误 (\(statusCode)): \(message ?? "未知错误")"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .rateLimitExceeded(let resetTime):
            return "已达到今日免费额度上限，\(resetTime)后重置。或配置自定义 API Key 继续使用。"
        case .authenticationFailed:
            return "API Key 无效或已过期"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .timeout:
            return "请求超时，请稍后重试"
        case .cancelled:
            return "请求已取消"
        case .unknown(let error):
            return "未知错误: \(error?.localizedDescription ?? "无详情")"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded:
            return "前往设置页配置您自己的 API Key"
        case .authenticationFailed:
            return "请检查您的 API Key 是否正确"
        case .networkError, .timeout:
            return "请检查网络连接后重试"
        default:
            return nil
        }
    }
}

// MARK: - Agent Errors

enum AgentError: LocalizedError {
    case rateLimitExceeded(remaining: String)
    case noLLMConfigured
    case toolExecutionFailed(toolName: String, reason: String)
    case maxIterationsReached
    case invalidToolResponse
    case conversationNotFound
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded(let remaining):
            return "已达到今日免费额度上限，\(remaining)后重置"
        case .noLLMConfigured:
            return "未配置 LLM 服务"
        case .toolExecutionFailed(let toolName, let reason):
            return "工具 \(toolName) 执行失败: \(reason)"
        case .maxIterationsReached:
            return "Agent 已达到最大迭代次数"
        case .invalidToolResponse:
            return "工具返回了无效的响应"
        case .conversationNotFound:
            return "会话不存在"
        }
    }
}
