//
//  LLMProvider.swift
//  OwlSeerLite
//
//  LLM 提供商协议
//

import Foundation

// MARK: - LLM Provider Protocol

protocol LLMProviderProtocol {
    /// 提供商类型
    var providerType: AppSettings.LLMProviderType { get }
    
    /// 当前使用的模型
    var model: String { get }
    
    /// 发送聊天请求（非流式）
    func chat(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) async throws -> LLMResponse
    
    /// 发送聊天请求（流式）
    func chatStream(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) -> AsyncThrowingStream<LLMStreamChunk, Error>
}

// MARK: - LLM Data Types

/// 统一的消息格式
struct LLMMessage: Codable {
    let role: String
    let content: String?
    let toolCalls: [LLMToolCall]?
    let toolCallId: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case role, content, name
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }
    
    init(
        role: String,
        content: String? = nil,
        toolCalls: [LLMToolCall]? = nil,
        toolCallId: String? = nil,
        name: String? = nil
    ) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
        self.name = name
    }
    
    /// 从 Message 模型转换
    static func from(_ message: Message) -> LLMMessage {
        LLMMessage(
            role: message.role,
            content: message.content,
            toolCalls: message.toolCalls?.map {
                LLMToolCall(id: $0.id, name: $0.name, arguments: $0.arguments)
            },
            toolCallId: message.toolResults?.first?.toolCallID
        )
    }
}

/// 工具调用
struct LLMToolCall: Codable, Identifiable {
    let id: String
    let type: String
    let function: FunctionCall
    
    var name: String { function.name }
    var arguments: String { function.arguments }
    
    init(id: String, name: String, arguments: String) {
        self.id = id
        self.type = "function"
        self.function = FunctionCall(name: name, arguments: arguments)
    }
    
    struct FunctionCall: Codable {
        let name: String
        let arguments: String
    }
}

/// LLM 响应
struct LLMResponse {
    let content: String?
    let toolCalls: [LLMToolCall]?
    let finishReason: String?
    let usage: LLMUsage?
    
    var hasToolCalls: Bool {
        toolCalls != nil && !toolCalls!.isEmpty
    }
}

/// Token 使用统计
struct LLMUsage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// 流式响应块
struct LLMStreamChunk {
    enum ChunkType {
        case content(String)
        case toolCallStart(id: String, name: String)
        case toolCallArguments(id: String, arguments: String)
        case done(finishReason: String?)
    }
    
    let type: ChunkType
}

// MARK: - Tool Conversion

extension AgentTool {
    /// 转换为 OpenAI 格式的工具定义
    func toOpenAIFormat() -> [String: Any] {
        var properties: [String: Any] = [:]
        for (key, prop) in parameters.properties {
            var propDict: [String: Any] = [
                "type": prop.type,
                "description": prop.description
            ]
            if let enumValues = prop.enumValues {
                propDict["enum"] = enumValues
            }
            properties[key] = propDict
        }
        
        return [
            "type": "function",
            "function": [
                "name": name,
                "description": description,
                "parameters": [
                    "type": parameters.type,
                    "properties": properties,
                    "required": parameters.required
                ]
            ]
        ]
    }
    
    /// 转换为 Anthropic 格式的工具定义
    func toAnthropicFormat() -> [String: Any] {
        var properties: [String: Any] = [:]
        for (key, prop) in parameters.properties {
            var propDict: [String: Any] = [
                "type": prop.type,
                "description": prop.description
            ]
            if let enumValues = prop.enumValues {
                propDict["enum"] = enumValues
            }
            properties[key] = propDict
        }
        
        return [
            "name": name,
            "description": description,
            "input_schema": [
                "type": parameters.type,
                "properties": properties,
                "required": parameters.required
            ]
        ]
    }
}
