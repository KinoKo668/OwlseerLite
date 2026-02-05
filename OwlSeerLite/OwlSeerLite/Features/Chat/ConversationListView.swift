//
//  ConversationListView.swift
//  OwlSeerLite
//
//  历史对话列表视图
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    
    let onSelectConversation: (Conversation) -> Void
    let onCreateNew: () -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
                }
            }
            .navigationTitle("conversation.history".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onCreateNew()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("conversation.empty".localized)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button {
                onCreateNew()
                dismiss()
            } label: {
                Label("conversation.start_new".localized, systemImage: "plus.bubble")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Conversation List
    
    private var conversationListView: some View {
        List {
            ForEach(conversations) { conversation in
                ConversationRowView(conversation: conversation)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectConversation(conversation)
                        dismiss()
                    }
            }
            .onDelete(perform: deleteConversations)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Delete
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            
            // 先删除该对话的所有消息
            let conversationID = conversation.id
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { $0.conversationID == conversationID }
            )
            
            if let messages = try? modelContext.fetch(messageDescriptor) {
                for message in messages {
                    modelContext.delete(message)
                }
            }
            
            // 删除对话
            modelContext.delete(conversation)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Conversation Row

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(formattedDate)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
}

#Preview {
    ConversationListView(
        onSelectConversation: { _ in },
        onCreateNew: { }
    )
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
