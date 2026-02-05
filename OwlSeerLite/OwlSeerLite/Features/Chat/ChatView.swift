//
//  ChatView.swift
//  OwlSeerLite
//
//  聊天主界面
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var showingConversationList = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                messageListView
                
                // 免责声明
                DisclaimerBanner()
                
                // 输入区域
                inputAreaView
            }
            .navigationTitle(viewModel.currentConversation?.title ?? "OwlSeer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        // 历史对话按钮
                        Button {
                            showingConversationList = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        
                        // 新建对话按钮 - 直接创建，无需确认
                        Button {
                            Task {
                                await viewModel.createNewConversation(modelContext: modelContext)
                            }
                        } label: {
                            Image(systemName: "plus.bubble")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    usageStatusView
                }
            }
            .alert("common.hint".localized, isPresented: $viewModel.showError) {
                Button("common.confirm".localized, role: .cancel) {}
                if viewModel.shouldShowSettingsHint {
                    Button("common.go_to_settings".localized) {
                        // 切换到设置 Tab
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingConversationList) {
                ConversationListView(
                    onSelectConversation: { conversation in
                        Task {
                            await viewModel.switchToConversation(conversation, modelContext: modelContext)
                        }
                    },
                    onCreateNew: {
                        Task {
                            await viewModel.createNewConversation(modelContext: modelContext)
                        }
                    }
                )
            }
            .task {
                await viewModel.loadOrCreateConversation(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Message List
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 欢迎消息
                    if viewModel.messages.isEmpty {
                        welcomeView
                    }
                    
                    // 消息列表
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            onFlag: { flaggedMessage in
                                viewModel.flagMessage(flaggedMessage)
                            },
                            onReaction: { reactedMessage, reaction in
                                viewModel.setReaction(reactedMessage, reaction: reaction, modelContext: modelContext)
                            }
                        )
                        .id(message.id)
                    }
                    
                    // 流式响应
                    if viewModel.isStreaming, !viewModel.streamingContent.isEmpty {
                        streamingBubbleView
                    }
                    
                    // 加载状态
                    if viewModel.isProcessing && viewModel.streamingContent.isEmpty {
                        loadingView
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                withAnimation {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image("AIAvatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            Text("chat.welcome".localized)
                .font(.title2.bold())
            
            Text("chat.welcome_subtitle".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                suggestionButton("chat.suggestion_1".localized)
                suggestionButton("chat.suggestion_2".localized)
                suggestionButton("chat.suggestion_3".localized)
            }
            .padding(.top, 20)
        }
        .padding(.vertical, 40)
    }
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            messageText = text
            isInputFocused = true
        } label: {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Streaming Bubble
    
    private var streamingBubbleView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("AIAvatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.streamingContent)
                    .textSelection(.enabled)
                
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("chat.thinking".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
        .id("streaming")
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("AIAvatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            HStack(spacing: 8) {
                ProgressView()
                Text(viewModel.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
    }
    
    // MARK: - Input Area
    
    private var inputAreaView: some View {
        HStack(spacing: 12) {
            TextField("chat.input_placeholder".localized, text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
                .disabled(viewModel.isProcessing)
            
            if viewModel.isProcessing {
                // 停止按钮
                Button {
                    viewModel.stopGenerating()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.red)
                }
            } else {
                // 发送按钮
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? Color.accentColor : Color.gray)
                }
                .disabled(!canSend)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isProcessing
    }
    
    private func sendMessage() {
        guard canSend else { return }
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        Task {
            await viewModel.sendMessage(text, modelContext: modelContext)
        }
    }
    
    // MARK: - Usage Status
    
    private var usageStatusView: some View {
        EmptyView()
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
