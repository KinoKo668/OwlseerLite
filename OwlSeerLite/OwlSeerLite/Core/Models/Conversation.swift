//
//  Conversation.swift
//  OwlSeerLite
//
//  会话模型 (SwiftData)
//

import SwiftData
import Foundation

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "新对话",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func updateTimestamp() {
        updatedAt = Date()
    }
}

// MARK: - Conversation Extensions

extension Conversation {
    /// 根据第一条用户消息自动生成标题
    func generateTitle(from firstMessage: String) {
        let maxLength = 20
        if firstMessage.count > maxLength {
            title = String(firstMessage.prefix(maxLength)) + "..."
        } else {
            title = firstMessage
        }
    }
}
