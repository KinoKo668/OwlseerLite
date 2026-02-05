//
//  GeminiProvider.swift
//  OwlSeerLite
//
//  Google Gemini API 实现
//

import Foundation

final class GeminiProvider: LLMProviderProtocol {
    let providerType: AppSettings.LLMProviderType = .gemini
    let model: String
    
    private let apiKey: String
    private let baseURL: String
    private let client = APIClient.shared
    
    init(apiKey: String, baseURL: String? = nil, model: String = "gemini-1.5-flash") {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? "https://generativelanguage.googleapis.com/v1beta"
        self.model = model
    }
    
    // MARK: - Chat (Non-streaming)
    
    func chat(
        messages: [LLMMessage],
        tools: [AgentTool]?
    ) async throws -> LLMResponse {
        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let (systemInstruction, contents) = convertMessages(messages)
        
        let request = GeminiRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            tools: tools.map { [GeminiToolDeclaration(functionDeclarations: $0.map { GeminiFunctionDeclaration(from: $0) })] }
        )
        
        let response: GeminiResponse = try await client.request(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
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
                    guard let url = URL(string: "\(baseURL)/models/\(model):streamGenerateContent?key=\(apiKey)&alt=sse") else {
                        throw APIError.invalidURL
                    }
                    
                    let (systemInstruction, contents) = convertMessages(messages)
                    
                    let request = GeminiRequest(
                        contents: contents,
                        systemInstruction: systemInstruction,
                        tools: tools.map { [GeminiToolDeclaration(functionDeclarations: $0.map { GeminiFunctionDeclaration(from: $0) })] }
                    )
                    
                    let stream = try await client.streamRequest(
                        url: url,
                        method: .post,
                        headers: ["Content-Type": "application/json"],
                        body: request
                    )
                    
                    for try await data in stream {
                        guard let line = String(data: data, encoding: .utf8) else { continue }
                        
                        // Gemini SSE 格式
                        let prefix = "data: "
                        guard line.hasPrefix(prefix) else { continue }
                        
                        let jsonString = String(line.dropFirst(prefix.count))
                        guard let jsonData = jsonString.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(GeminiResponse.self, from: jsonData) else {
                            continue
                        }
                        
                        if let candidate = chunk.candidates?.first {
                            for part in candidate.content?.parts ?? [] {
                                if let text = part.text {
                                    continuation.yield(LLMStreamChunk(type: .content(text)))
                                }
                                if let functionCall = part.functionCall {
                                    let id = UUID().uuidString
                                    continuation.yield(LLMStreamChunk(type: .toolCallStart(id: id, name: functionCall.name)))
                                    if let args = functionCall.args {
                                        let argsString = (try? JSONEncoder().encode(args))
                                            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                                        continuation.yield(LLMStreamChunk(type: .toolCallArguments(id: id, arguments: argsString)))
                                    }
                                }
                            }
                            
                            if candidate.finishReason != nil {
                                continuation.yield(LLMStreamChunk(type: .done(finishReason: candidate.finishReason)))
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
    
    private func convertMessages(_ messages: [LLMMessage]) -> (GeminiContent?, [GeminiContent]) {
        var systemInstruction: GeminiContent?
        var contents: [GeminiContent] = []
        
        for message in messages {
            switch message.role {
            case "system":
                systemInstruction = GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: message.content)]
                )
            case "user":
                contents.append(GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: message.content)]
                ))
            case "assistant":
                if let toolCalls = message.toolCalls {
                    var parts: [GeminiPart] = []
                    if let content = message.content, !content.isEmpty {
                        parts.append(GeminiPart(text: content))
                    }
                    for toolCall in toolCalls {
                        let args = (try? JSONDecoder().decode([String: AnyCodable].self, from: toolCall.arguments.data(using: .utf8)!)) ?? [:]
                        parts.append(GeminiPart(functionCall: GeminiFunctionCall(name: toolCall.name, args: args)))
                    }
                    contents.append(GeminiContent(role: "model", parts: parts))
                } else {
                    contents.append(GeminiContent(
                        role: "model",
                        parts: [GeminiPart(text: message.content)]
                    ))
                }
            case "tool":
                if let toolCallId = message.toolCallId {
                    contents.append(GeminiContent(
                        role: "user",
                        parts: [GeminiPart(functionResponse: GeminiFunctionResponse(
                            name: toolCallId,
                            response: ["result": AnyCodable(message.content ?? "")]
                        ))]
                    ))
                }
            default:
                break
            }
        }
        
        return (systemInstruction, contents)
    }
}

// MARK: - Gemini Request/Response Models

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiContent?
    let tools: [GeminiToolDeclaration]?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case tools
    }
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String?
    let functionCall: GeminiFunctionCall?
    let functionResponse: GeminiFunctionResponse?
    
    init(text: String? = nil, functionCall: GeminiFunctionCall? = nil, functionResponse: GeminiFunctionResponse? = nil) {
        self.text = text
        self.functionCall = functionCall
        self.functionResponse = functionResponse
    }
    
    enum CodingKeys: String, CodingKey {
        case text
        case functionCall = "function_call"
        case functionResponse = "function_response"
    }
}

private struct GeminiFunctionCall: Codable {
    let name: String
    let args: [String: AnyCodable]?
}

private struct GeminiFunctionResponse: Codable {
    let name: String
    let response: [String: AnyCodable]
}

private struct GeminiToolDeclaration: Encodable {
    let functionDeclarations: [GeminiFunctionDeclaration]
    
    enum CodingKeys: String, CodingKey {
        case functionDeclarations = "function_declarations"
    }
}

private struct GeminiFunctionDeclaration: Encodable {
    let name: String
    let description: String
    let parameters: GeminiParameters
    
    init(from tool: AgentTool) {
        self.name = tool.name
        self.description = tool.description
        
        var properties: [String: GeminiPropertyDef] = [:]
        for (key, prop) in tool.parameters.properties {
            properties[key] = GeminiPropertyDef(
                type: prop.type.uppercased(),
                description: prop.description,
                enumValues: prop.enumValues
            )
        }
        
        self.parameters = GeminiParameters(
            type: "OBJECT",
            properties: properties,
            required: tool.parameters.required
        )
    }
}

private struct GeminiParameters: Encodable {
    let type: String
    let properties: [String: GeminiPropertyDef]
    let required: [String]
}

private struct GeminiPropertyDef: Encodable {
    let type: String
    let description: String
    let enumValues: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    let usageMetadata: UsageMetadata?
    
    struct Candidate: Decodable {
        let content: GeminiContent?
        let finishReason: String?
    }
    
    struct UsageMetadata: Decodable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let totalTokenCount: Int?
    }
    
    func toLLMResponse() -> LLMResponse {
        guard let candidate = candidates?.first else {
            return LLMResponse(content: nil, toolCalls: nil, finishReason: nil, usage: nil)
        }
        
        var textContent: String?
        var toolCalls: [LLMToolCall] = []
        
        for part in candidate.content?.parts ?? [] {
            if let text = part.text {
                textContent = (textContent ?? "") + text
            }
            if let functionCall = part.functionCall {
                let id = UUID().uuidString
                let args = (try? JSONEncoder().encode(functionCall.args))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                toolCalls.append(LLMToolCall(id: id, name: functionCall.name, arguments: args))
            }
        }
        
        return LLMResponse(
            content: textContent,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            finishReason: candidate.finishReason,
            usage: usageMetadata.map {
                LLMUsage(
                    promptTokens: $0.promptTokenCount,
                    completionTokens: $0.candidatesTokenCount,
                    totalTokens: $0.totalTokenCount
                )
            }
        )
    }
}
