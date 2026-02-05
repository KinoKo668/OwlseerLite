//
//  ChatViewModel.swift
//  OwlSeerLite
//
//  聊天 ViewModel
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var currentConversation: Conversation?
    @Published var isProcessing = false
    @Published var isStreaming = false
    @Published var streamingContent = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var shouldShowSettingsHint = false
    @Published var showFeedbackSheet = false
    @Published var messageToFlag: Message?
    
    // MARK: - Private Properties
    
    private let agentService = AgentService()
    private var processingTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var statusText: String {
        switch agentService.currentStatus {
        case .idle:
            return ""
        case .thinking:
            return "chat.thinking".localized
        case .callingTool(let name):
            return "tool.calling".localized(with: toolDisplayName(name))
        case .streaming:
            return "chat.streaming".localized
        case .error(let message):
            return "common.error".localized + ": " + message
        }
    }
    
    // MARK: - Public Methods
    
    /// 加载或创建会话
    func loadOrCreateConversation(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let conversations = try modelContext.fetch(descriptor)
            if let latest = conversations.first {
                currentConversation = latest
                await loadMessages(for: latest, modelContext: modelContext)
            } else {
                await createNewConversation(modelContext: modelContext)
            }
        } catch {
            showError(message: "加载会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 创建新会话
    func createNewConversation(modelContext: ModelContext) async {
        let conversation = Conversation()
        modelContext.insert(conversation)
        
        do {
            try modelContext.save()
            currentConversation = conversation
            messages = []
        } catch {
            showError(message: "创建会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 发送消息 (使用流式输出)
    func sendMessage(_ text: String, modelContext: ModelContext) async {
        guard let conversation = currentConversation else {
            await createNewConversation(modelContext: modelContext)
            guard currentConversation != nil else { return }
            await sendMessage(text, modelContext: modelContext)
            return
        }
        
        // 更新会话标题（如果是第一条消息）
        if messages.isEmpty {
            conversation.generateTitle(from: text)
        }
        
        isProcessing = true
        isStreaming = true
        streamingContent = ""
        
        do {
            _ = try await agentService.processUserMessageStreaming(
                text,
                conversation: conversation,
                modelContext: modelContext
            ) { [weak self] content in
                Task { @MainActor in
                    self?.streamingContent = content
                }
            }
            
            // 更新消息列表
            await loadMessages(for: conversation, modelContext: modelContext)
            
        } catch let error as AgentError {
            handleAgentError(error)
        } catch let error as APIError {
            handleAPIError(error)
        } catch {
            if !Task.isCancelled {
                showError(message: error.localizedDescription)
            }
        }
        
        isProcessing = false
        isStreaming = false
        streamingContent = ""
    }
    
    /// 停止当前生成
    func stopGenerating() {
        agentService.cancelProcessing()
        isProcessing = false
        isStreaming = false
    }
    
    /// 标记消息
    func flagMessage(_ message: Message) {
        messageToFlag = message
        showFeedbackSheet = true
    }
    
    /// 设置消息反应（点赞/点踩）
    func setReaction(_ message: Message, reaction: MessageReaction?, modelContext: ModelContext) {
        message.messageReaction = reaction
        try? modelContext.save()
        objectWillChange.send()
    }
    
    /// 切换到指定对话
    func switchToConversation(_ conversation: Conversation, modelContext: ModelContext) async {
        currentConversation = conversation
        await loadMessages(for: conversation, modelContext: modelContext)
    }
    
    /// 删除当前对话并切换到最近的对话
    func deleteCurrentConversation(modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }
        
        // 删除该对话的所有消息
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
        try? modelContext.save()
        
        // 加载最近的对话或创建新对话
        await loadOrCreateConversation(modelContext: modelContext)
    }
    
    // MARK: - Private Methods
    
    private func loadMessages(for conversation: Conversation, modelContext: ModelContext) async {
        let conversationID = conversation.id
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.conversationID == conversationID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            let fetchedMessages = try modelContext.fetch(descriptor)
            // Filter to show only user and assistant messages
            // Exclude assistant messages that only contain tool calls (empty content)
            messages = fetchedMessages.filter { msg in
                if msg.messageRole == .user {
                    return true
                }
                if msg.messageRole == .assistant {
                    // Only show assistant messages with actual content
                    // Skip those with tool calls but empty content (intermediate tool call messages)
                    let hasToolCalls = msg.toolCalls != nil && !msg.toolCalls!.isEmpty
                    let hasContent = !msg.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    return hasContent || !hasToolCalls
                }
                return false
            }
        } catch {
            showError(message: "chat.load_error".localized)
        }
    }
    
    private func handleAgentError(_ error: AgentError) {
        switch error {
        case .rateLimitExceeded(let remaining):
            errorMessage = "今日免费额度已用完，\(remaining)后重置。\n\n配置自定义 API Key 可解除限制。"
            shouldShowSettingsHint = true
            showError = true
        case .noLLMConfigured:
            errorMessage = "未配置 AI 服务，请先在设置中配置 API Key。"
            shouldShowSettingsHint = true
            showError = true
        default:
            showError(message: error.localizedDescription)
        }
    }
    
    private func handleAPIError(_ error: APIError) {
        switch error {
        case .authenticationFailed:
            errorMessage = "API Key 无效，请检查设置。"
            shouldShowSettingsHint = true
            showError = true
        case .rateLimitExceeded:
            errorMessage = "API 调用频率过高，请稍后重试。"
            showError = true
        default:
            showError(message: error.localizedDescription)
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        shouldShowSettingsHint = false
        showError = true
    }
    
    private func toolDisplayName(_ name: String) -> String {
        switch name {
        case "generate_hook": return "Hook 生成器"
        case "script_formatter": return "脚本格式化"
        case "trend_analyzer": return "趋势分析"
        case "web_search": return "联网搜索"
        default: return name
        }
    }
}
