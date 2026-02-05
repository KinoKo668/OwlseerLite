//
//  StreamingDecoder.swift
//  OwlSeerLite
//
//  SSE 流式解析器
//

import Foundation

/// Server-Sent Events (SSE) 解析器
final class StreamingDecoder {
    
    // MARK: - OpenAI Format
    
    struct OpenAIStreamChunk: Codable {
        let id: String?
        let object: String?
        let created: Int?
        let model: String?
        let choices: [Choice]?
        
        struct Choice: Codable {
            let index: Int?
            let delta: Delta?
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case index, delta
                case finishReason = "finish_reason"
            }
        }
        
        struct Delta: Codable {
            let role: String?
            let content: String?
            let toolCalls: [ToolCallDelta]?
            
            enum CodingKeys: String, CodingKey {
                case role, content
                case toolCalls = "tool_calls"
            }
        }
        
        struct ToolCallDelta: Codable {
            let index: Int?
            let id: String?
            let type: String?
            let function: FunctionDelta?
        }
        
        struct FunctionDelta: Codable {
            let name: String?
            let arguments: String?
        }
    }
    
    // MARK: - Anthropic Format
    
    struct AnthropicStreamEvent: Codable {
        let type: String
        let message: AnthropicMessage?
        let index: Int?
        let contentBlock: ContentBlock?
        let delta: AnthropicDelta?
        
        enum CodingKeys: String, CodingKey {
            case type, message, index
            case contentBlock = "content_block"
            case delta
        }
        
        struct AnthropicMessage: Codable {
            let id: String?
            let type: String?
            let role: String?
            let content: [ContentBlock]?
            let model: String?
            let stopReason: String?
            let stopSequence: String?
            let usage: Usage?
            
            enum CodingKeys: String, CodingKey {
                case id, type, role, content, model
                case stopReason = "stop_reason"
                case stopSequence = "stop_sequence"
                case usage
            }
        }
        
        struct ContentBlock: Codable {
            let type: String?
            let text: String?
            let id: String?
            let name: String?
            let input: [String: AnyCodable]?
        }
        
        struct AnthropicDelta: Codable {
            let type: String?
            let text: String?
            let partialJson: String?
            let stopReason: String?
            
            enum CodingKeys: String, CodingKey {
                case type, text
                case partialJson = "partial_json"
                case stopReason = "stop_reason"
            }
        }
        
        struct Usage: Codable {
            let inputTokens: Int?
            let outputTokens: Int?
            
            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
    }
    
    // MARK: - Parsing Methods
    
    /// 解析 SSE 数据行
    static func parseSSELine(_ line: String) -> String? {
        // SSE 格式: "data: {...}"
        let prefix = "data: "
        guard line.hasPrefix(prefix) else { return nil }
        
        let jsonString = String(line.dropFirst(prefix.count))
        
        // 跳过 [DONE] 标记
        if jsonString == "[DONE]" { return nil }
        
        return jsonString
    }
    
    /// 解析 OpenAI 流式响应
    static func parseOpenAIChunk(_ data: Data) -> OpenAIStreamChunk? {
        guard let line = String(data: data, encoding: .utf8),
              let jsonString = parseSSELine(line) else {
            return nil
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(OpenAIStreamChunk.self, from: jsonData)
    }
    
    /// 解析 Anthropic 流式响应
    static func parseAnthropicEvent(_ data: Data) -> AnthropicStreamEvent? {
        guard let line = String(data: data, encoding: .utf8),
              let jsonString = parseSSELine(line) else {
            return nil
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(AnthropicStreamEvent.self, from: jsonData)
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable cannot encode value"
                )
            )
        }
    }
}
