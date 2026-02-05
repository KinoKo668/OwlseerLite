//
//  OpenAIProvider.swift
//  OwlSeerLite
//
//  OpenAI API 实现
//

import Foundation

final class OpenAIProvider: LLMProviderProtocol {
    let providerType: AppSettings.LLMProviderType = .openai
    let model: String
    
    private let apiKey: String
    private let baseURL: String
    private let client = APIClient.shared
    
    init(apiKey: String, baseURL: String? = nil, model: String = "gpt-4o-mini") {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? "https://api.openai.com/v1"
        self.model = model
    }
    
    // MARK: - Chat (Non-streaming)
    
    func chat(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) async throws -> LLMResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        let request = OpenAIRequest(
            model: model,
            messages: messages.map { OpenAIMessage(from: $0) },
            tools: tools?.map { OpenAITool(from: $0) },
            stream: false
        )
        
        let response: OpenAIResponse = try await client.request(
            url: url,
            method: .post,
            headers: buildHeaders(),
            body: request
        )
        
        return response.toLLMResponse()
    }
    
    // MARK: - Chat (Streaming)
    
    func chatStream(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        throw APIError.invalidURL
                    }
                    
                    let request = OpenAIRequest(
                        model: model,
                        messages: messages.map { OpenAIMessage(from: $0) },
                        tools: tools?.map { OpenAITool(from: $0) },
                        stream: true
                    )
                    
                    let stream = try await client.streamRequest(
                        url: url,
                        method: .post,
                        headers: buildHeaders(),
                        body: request
                    )
                    
                    // 用于累积工具调用
                    var toolCallAccumulators: [String: (id: String, name: String, arguments: String)] = [:]
                    
                    for try await data in stream {
                        guard let chunk = StreamingDecoder.parseOpenAIChunk(data) else {
                            continue
                        }
                        
                        if let choice = chunk.choices?.first {
                            // 处理文本内容
                            if let content = choice.delta?.content {
                                continuation.yield(LLMStreamChunk(type: .content(content)))
                            }
                            
                            // 处理工具调用
                            if let toolCalls = choice.delta?.toolCalls {
                                for toolCall in toolCalls {
                                    let index = "\(toolCall.index ?? 0)"
                                    
                                    if let id = toolCall.id, let name = toolCall.function?.name {
                                        // 新的工具调用开始
                                        toolCallAccumulators[index] = (id: id, name: name, arguments: "")
                                        continuation.yield(LLMStreamChunk(type: .toolCallStart(id: id, name: name)))
                                    }
                                    
                                    if let args = toolCall.function?.arguments,
                                       var accumulator = toolCallAccumulators[index] {
                                        accumulator.arguments += args
                                        toolCallAccumulators[index] = accumulator
                                        continuation.yield(LLMStreamChunk(type: .toolCallArguments(id: accumulator.id, arguments: args)))
                                    }
                                }
                            }
                            
                            // 检查完成原因
                            if let finishReason = choice.finishReason {
                                continuation.yield(LLMStreamChunk(type: .done(finishReason: finishReason)))
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func buildHeaders() -> [String: String] {
        [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
    }
}

// MARK: - OpenAI Request/Response Models

private struct OpenAIRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let tools: [OpenAITool]?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, messages, tools, stream
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        if let tools = tools, !tools.isEmpty {
            try container.encode(tools, forKey: .tools)
        }
    }
}

private struct OpenAIMessage: Encodable {
    let role: String
    let content: String?
    let toolCalls: [OpenAIToolCall]?
    let toolCallId: String?
    
    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }
    
    init(from llmMessage: LLMMessage) {
        self.role = llmMessage.role
        self.content = llmMessage.content
        self.toolCalls = llmMessage.toolCalls?.map { OpenAIToolCall(from: $0) }
        self.toolCallId = llmMessage.toolCallId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        
        // content 对于 tool role 可以为 nil
        if role == "tool" {
            try container.encode(content, forKey: .content)
            try container.encode(toolCallId, forKey: .toolCallId)
        } else {
            try container.encodeIfPresent(content, forKey: .content)
            try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
        }
    }
}

private struct OpenAIToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall
    
    struct FunctionCall: Codable {
        let name: String
        let arguments: String
    }
    
    init(from toolCall: LLMToolCall) {
        self.id = toolCall.id
        self.type = "function"
        self.function = FunctionCall(name: toolCall.name, arguments: toolCall.arguments)
    }
}

private struct OpenAITool: Encodable {
    let type: String
    let function: FunctionDef
    
    struct FunctionDef: Encodable {
        let name: String
        let description: String
        let parameters: ParametersDef
    }
    
    struct ParametersDef: Encodable {
        let type: String
        let properties: [String: PropertyDef]
        let required: [String]
    }
    
    struct PropertyDef: Encodable {
        let type: String
        let description: String
        let enumValues: [String]?
        
        enum CodingKeys: String, CodingKey {
            case type, description
            case enumValues = "enum"
        }
    }
    
    init(from tool: AgentTool) {
        self.type = "function"
        
        var properties: [String: PropertyDef] = [:]
        for (key, prop) in tool.parameters.properties {
            properties[key] = PropertyDef(
                type: prop.type,
                description: prop.description,
                enumValues: prop.enumValues
            )
        }
        
        self.function = FunctionDef(
            name: tool.name,
            description: tool.description,
            parameters: ParametersDef(
                type: tool.parameters.type,
                properties: properties,
                required: tool.parameters.required
            )
        )
    }
}

private struct OpenAIResponse: Decodable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let usage: LLMUsage?
    
    struct Choice: Decodable {
        let index: Int
        let message: ResponseMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct ResponseMessage: Decodable {
        let role: String
        let content: String?
        let toolCalls: [ResponseToolCall]?
        
        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
        }
    }
    
    struct ResponseToolCall: Decodable {
        let id: String
        let type: String
        let function: FunctionCall
        
        struct FunctionCall: Decodable {
            let name: String
            let arguments: String
        }
    }
    
    func toLLMResponse() -> LLMResponse {
        let choice = choices.first
        let toolCalls = choice?.message.toolCalls?.map {
            LLMToolCall(id: $0.id, name: $0.function.name, arguments: $0.function.arguments)
        }
        
        return LLMResponse(
            content: choice?.message.content,
            toolCalls: toolCalls,
            finishReason: choice?.finishReason,
            usage: usage
        )
    }
}
