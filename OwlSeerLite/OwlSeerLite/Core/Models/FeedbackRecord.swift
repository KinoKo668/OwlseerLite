//
//  FeedbackRecord.swift
//  OwlSeerLite
//
//  Feedback Record Model (SwiftData)
//

import SwiftData
import Foundation

@Model
final class FeedbackRecord {
    @Attribute(.unique) var id: UUID
    var messageID: UUID
    var reason: String
    var additionalInfo: String?
    var createdAt: Date
    var isSent: Bool  // Whether feedback email has been sent
    
    init(
        id: UUID = UUID(),
        messageID: UUID,
        reason: FeedbackReason,
        additionalInfo: String? = nil,
        createdAt: Date = Date(),
        isSent: Bool = false
    ) {
        self.id = id
        self.messageID = messageID
        self.reason = reason.rawValue
        self.additionalInfo = additionalInfo
        self.createdAt = createdAt
        self.isSent = isSent
    }
    
    var feedbackReason: FeedbackReason {
        FeedbackReason(rawValue: reason) ?? .other
    }
}

enum FeedbackReason: String, Codable, CaseIterable, Identifiable {
    case harmful = "harmful"
    case inaccurate = "inaccurate"
    case inappropriate = "inappropriate"
    case spam = "spam"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .harmful: return "feedback.reason.harmful".localized
        case .inaccurate: return "feedback.reason.inaccurate".localized
        case .inappropriate: return "feedback.reason.inappropriate".localized
        case .spam: return "feedback.reason.spam".localized
        case .other: return "feedback.reason.other".localized
        }
    }
    
    var description: String {
        switch self {
        case .harmful: return "feedback.reason.harmful_desc".localized
        case .inaccurate: return "feedback.reason.inaccurate_desc".localized
        case .inappropriate: return "feedback.reason.inappropriate_desc".localized
        case .spam: return "feedback.reason.spam_desc".localized
        case .other: return "feedback.reason.other_desc".localized
        }
    }
}
