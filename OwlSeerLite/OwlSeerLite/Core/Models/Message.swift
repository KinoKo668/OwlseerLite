//
//  Message.swift
//  OwlSeerLite
//
//  聊天消息模型 (SwiftData)
//

import SwiftData
import Foundation

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var conversationID: UUID
    var role: String  // "user", "assistant", "system", "tool"
    var content: String
    var toolCallsData: Data?  // JSON encoded [ToolCallRecord]
    var toolResultsData: Data?  // JSON encoded [ToolResultRecord]
    var createdAt: Date
    var isFlagged: Bool
    var reaction: String?  // "like", "dislike", or nil
    
    init(
        id: UUID = UUID(),
        conversationID: UUID,
        role: MessageRole,
        content: String,
        toolCalls: [ToolCallRecord]? = nil,
        toolResults: [ToolResultRecord]? = nil,
        createdAt: Date = Date(),
        isFlagged: Bool = false,
        reaction: MessageReaction? = nil
    ) {
        self.id = id
        self.conversationID = conversationID
        self.role = role.rawValue
        self.content = content
        self.toolCallsData = toolCalls.flatMap { try? JSONEncoder().encode($0) }
        self.toolResultsData = toolResults.flatMap { try? JSONEncoder().encode($0) }
        self.createdAt = createdAt
        self.isFlagged = isFlagged
        self.reaction = reaction?.rawValue
    }
    
    var messageRole: MessageRole {
        MessageRole(rawValue: role) ?? .user
    }
    
    var toolCalls: [ToolCallRecord]? {
        guard let data = toolCallsData else { return nil }
        return try? JSONDecoder().decode([ToolCallRecord].self, from: data)
    }
    
    var toolResults: [ToolResultRecord]? {
        guard let data = toolResultsData else { return nil }
        return try? JSONDecoder().decode([ToolResultRecord].self, from: data)
    }
    
    var messageReaction: MessageReaction? {
        get {
            guard let reaction else { return nil }
            return MessageReaction(rawValue: reaction)
        }
        set {
            reaction = newValue?.rawValue
        }
    }
}

// MARK: - Message Reaction

enum MessageReaction: String, Codable {
    case like
    case dislike
}

// MARK: - Supporting Types

enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
    case tool
}

struct ToolCallRecord: Codable, Identifiable {
    let id: String
    let name: String
    let arguments: String  // JSON string
    
    init(id: String, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

struct ToolResultRecord: Codable {
    let toolCallID: String
    let result: String
}

// MARK: - Convenience Extensions

extension Message {
    static func userMessage(conversationID: UUID, content: String) -> Message {
        Message(conversationID: conversationID, role: .user, content: content)
    }
    
    static func assistantMessage(conversationID: UUID, content: String) -> Message {
        Message(conversationID: conversationID, role: .assistant, content: content)
    }
    
    static func systemMessage(conversationID: UUID, content: String) -> Message {
        Message(conversationID: conversationID, role: .system, content: content)
    }
    
    static func toolMessage(conversationID: UUID, toolCallID: String, result: String) -> Message {
        Message(
            conversationID: conversationID,
            role: .tool,
            content: result,
            toolResults: [ToolResultRecord(toolCallID: toolCallID, result: result)]
        )
    }
}
