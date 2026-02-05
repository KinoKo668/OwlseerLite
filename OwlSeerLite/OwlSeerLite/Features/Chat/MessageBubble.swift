//
//  MessageBubble.swift
//  OwlSeerLite
//
//  消息气泡组件
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let onFlag: (Message) -> Void
    let onReaction: (Message, MessageReaction?) -> Void
    
    @State private var showFlagMenu = false
    @State private var showCopiedToast = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.messageRole == .user {
                Spacer()
                userBubble
            } else {
                assistantBubble
                Spacer()
            }
        }
    }
    
    // MARK: - User Bubble
    
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .textSelection(.enabled)
                .padding(12)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(16)
                .cornerRadius(4, corners: .topRight)
            
            Text(formattedTime)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Assistant Bubble
    
    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Image("AIAvatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 消息内容
                MarkdownRenderer(content: message.content)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .cornerRadius(4, corners: .topLeft)
                
                // 底部操作栏
                HStack(spacing: 12) {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // 点赞按钮
                    Button {
                        let newReaction: MessageReaction? = message.messageReaction == .like ? nil : .like
                        onReaction(message, newReaction)
                    } label: {
                        Image(systemName: message.messageReaction == .like ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                    }
                    .foregroundStyle(message.messageReaction == .like ? .green : .secondary)
                    
                    // 点踩按钮
                    Button {
                        let newReaction: MessageReaction? = message.messageReaction == .dislike ? nil : .dislike
                        onReaction(message, newReaction)
                    } label: {
                        Image(systemName: message.messageReaction == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.caption)
                    }
                    .foregroundStyle(message.messageReaction == .dislike ? .red : .secondary)
                    
                    // 复制按钮
                    Button {
                        UIPasteboard.general.string = message.content
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    // 举报按钮 (App Store 合规必需)
                    Button {
                        onFlag(message)
                    } label: {
                        Image(systemName: message.isFlagged ? "flag.fill" : "flag")
                            .font(.caption)
                    }
                    .foregroundStyle(message.isFlagged ? .red : .secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Helper
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.createdAt)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageBubble(
            message: Message(
                conversationID: UUID(),
                role: .user,
                content: "帮我写一个美食视频的开头"
            ),
            onFlag: { _ in },
            onReaction: { _, _ in }
        )
        
        MessageBubble(
            message: Message(
                conversationID: UUID(),
                role: .assistant,
                content: """
                好的！这里有几个美食视频开头的 Hook：
                
                1. **悬念型**: "这家店藏在巷子里，却让我排了2小时队..."
                2. **数据型**: "抖音200万点赞的神仙小店，我终于打卡了！"
                3. **反问型**: "你敢相信吗？这碗面只要15块！"
                """
            ),
            onFlag: { _ in },
            onReaction: { _, _ in }
        )
    }
    .padding()
}
