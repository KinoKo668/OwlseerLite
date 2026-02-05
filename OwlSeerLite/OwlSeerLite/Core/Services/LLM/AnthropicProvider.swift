//
//  AnthropicProvider.swift
//  OwlSeerLite
//
//  Anthropic (Claude) API 实现
//

import Foundation

final class AnthropicProvider: LLMProviderProtocol {
    let providerType: AppSettings.LLMProviderType = .anthropic
    let model: String
    
    private let apiKey: String
    private let baseURL: String
    private let client = APIClient.shared
    private let maxTokens: Int
    
    init(apiKey: String, baseURL: String? = nil, model: String = "claude-3-5-sonnet-20241022", maxTokens: Int = 4096) {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? "https://api.anthropic.com/v1"
        self.model = model
        self.maxTokens = maxTokens
    }
    
    // MARK: - Chat (Non-streaming)
    
    func chat(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) async throws -> LLMResponse {
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw APIError.invalidURL
        }
        
        let (systemPrompt, conversationMessages) = extractSystemPrompt(from: messages)
        
        let request = AnthropicRequest(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: conversationMessages.map { AnthropicMessage(from: $0) },
            tools: tools?.map { AnthropicTool(from: $0) }
        )
        
        let response: AnthropicResponse = try await client.request(
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
                    guard let url = URL(string: "\(baseURL)/messages") else {
                        throw APIError.invalidURL
                    }
                    
                    let (systemPrompt, conversationMessages) = extractSystemPrompt(from: messages)
                    
                    let request = AnthropicRequest(
                        model: model,
                        maxTokens: maxTokens,
                        system: systemPrompt,
                        messages: conversationMessages.map { AnthropicMessage(from: $0) },
                        tools: tools?.map { AnthropicTool(from: $0) },
                        stream: true
                    )
                    
                    let stream = try await client.streamRequest(
                        url: url,
                        method: .post,
                        headers: buildHeaders(),
                        body: request
                    )
                    
                    var currentToolId: String?
                    
                    for try await data in stream {
                        guard let event = StreamingDecoder.parseAnthropicEvent(data) else {
                            continue
                        }
                        
                        switch event.type {
                        case "content_block_start":
                            if let block = event.contentBlock {
                                if block.type == "tool_use", let id = block.id, let name = block.name {
                                    currentToolId = id
                                    continuation.yield(LLMStreamChunk(type: .toolCallStart(id: id, name: name)))
                                }
                            }
                            
                        case "content_block_delta":
                            if let delta = event.delta {
                                if let text = delta.text {
                                    continuation.yield(LLMStreamChunk(type: .content(text)))
                                }
                                if let partialJson = delta.partialJson, let toolId = currentToolId {
                                    continuation.yield(LLMStreamChunk(type: .toolCallArguments(id: toolId, arguments: partialJson)))
                                }
                            }
                            
                        case "message_delta":
                            if let delta = event.delta, let stopReason = delta.stopReason {
                                continuation.yield(LLMStreamChunk(type: .done(finishReason: stopReason)))
                            }
                            
                        case "message_stop":
                            continuation.yield(LLMStreamChunk(type: .done(finishReason: nil)))
                            
                        default:
                            break
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
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json"
        ]
    }
    
    private func extractSystemPrompt(from messages: [LLMMessage]) -> (String?, [LLMMessage]) {
        var systemPrompt: String?
        var conversationMessages: [LLMMessage] = []
        
        for message in messages {
            if message.role == "system" {
                systemPrompt = message.content
            } else {
                conversationMessages.append(message)
            }
        }
        
        return (systemPrompt, conversationMessages)
    }
}

// MARK: - Anthropic Request/Response Models

private struct AnthropicRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String?
    let messages: [AnthropicMessage]
    let tools: [AnthropicTool]?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system, messages, tools, stream
    }
    
    init(
        model: String,
        maxTokens: Int,
        system: String?,
        messages: [AnthropicMessage],
        tools: [AnthropicTool]?,
        stream: Bool = false
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
        self.tools = tools
        self.stream = stream
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encodeIfPresent(system, forKey: .system)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        if let tools = tools, !tools.isEmpty {
            try container.encode(tools, forKey: .tools)
        }
    }
}

private struct AnthropicMessage: Encodable {
    let role: String
    let content: AnthropicContent
    
    init(from llmMessage: LLMMessage) {
        // Anthropic 需要将 tool 结果作为 user 消息发送
        if llmMessage.role == "tool" {
            self.role = "user"
            self.content = .toolResult(AnthropicToolResult(
                type: "tool_result",
                toolUseId: llmMessage.toolCallId ?? "",
                content: llmMessage.content ?? ""
            ))
        } else if llmMessage.role == "assistant", let toolCalls = llmMessage.toolCalls {
            self.role = "assistant"
            let toolUses = toolCalls.map { toolCall in
                AnthropicToolUse(
                    type: "tool_use",
                    id: toolCall.id,
                    name: toolCall.name,
                    input: Self.parseJSON(toolCall.arguments)
                )
            }
            self.content = .toolUse(toolUses)
        } else {
            self.role = llmMessage.role == "tool" ? "user" : llmMessage.role
            self.content = .text(llmMessage.content ?? "")
        }
    }
    
    private static func parseJSON(_ jsonString: String) -> [String: AnyCodable] {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) else {
            return [:]
        }
        return dict
    }
}

private enum AnthropicContent: Encodable {
    case text(String)
    case toolUse([AnthropicToolUse])
    case toolResult(AnthropicToolResult)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .toolUse(let toolUses):
            try container.encode(toolUses)
        case .toolResult(let result):
            try container.encode([result])
        }
    }
}

private struct AnthropicToolUse: Encodable {
    let type: String
    let id: String
    let name: String
    let input: [String: AnyCodable]
}

private struct AnthropicToolResult: Encodable {
    let type: String
    let toolUseId: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case toolUseId = "tool_use_id"
        case content
    }
}

private struct AnthropicTool: Encodable {
    let name: String
    let description: String
    let inputSchema: InputSchema
    
    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
    
    struct InputSchema: Encodable {
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
        self.name = tool.name
        self.description = tool.description
        
        var properties: [String: PropertyDef] = [:]
        for (key, prop) in tool.parameters.properties {
            properties[key] = PropertyDef(
                type: prop.type,
                description: prop.description,
                enumValues: prop.enumValues
            )
        }
        
        self.inputSchema = InputSchema(
            type: tool.parameters.type,
            properties: properties,
            required: tool.parameters.required
        )
    }
}

private struct AnthropicResponse: Decodable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
    
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
        let input: [String: AnyCodable]?
    }
    
    struct Usage: Decodable {
        let inputTokens: Int
        let outputTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
    
    func toLLMResponse() -> LLMResponse {
        var textContent: String?
        var toolCalls: [LLMToolCall] = []
        
        for block in content {
            switch block.type {
            case "text":
                textContent = block.text
            case "tool_use":
                if let id = block.id, let name = block.name, let input = block.input {
                    let arguments = (try? JSONEncoder().encode(input))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                    toolCalls.append(LLMToolCall(id: id, name: name, arguments: arguments))
                }
            default:
                break
            }
        }
        
        return LLMResponse(
            content: textContent,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            finishReason: stopReason,
            usage: LLMUsage(
                promptTokens: usage.inputTokens,
                completionTokens: usage.outputTokens,
                totalTokens: usage.inputTokens + usage.outputTokens
            )
        )
    }
}
