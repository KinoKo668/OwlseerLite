//
//  AgentService.swift
//  OwlSeerLite
//
//  Agent 主循环服务
//

import Foundation
import SwiftData
import Combine

@MainActor
final class AgentService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var currentStatus: AgentStatus = .idle
    @Published var streamingContent = ""
    @Published var isCancelled = false
    
    // MARK: - Dependencies
    
    private var llmProvider: LLMProviderProtocol?
    private var toolExecutor: ToolExecutor
    private let usageManager = DailyUsageManager.shared
    private let settingsManager = SettingsManager.shared
    
    // MARK: - Task Management
    
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Configuration
    
    private let maxIterations = 5  // 防止无限循环
    
    // MARK: - Status
    
    enum AgentStatus: Equatable {
        case idle
        case thinking
        case callingTool(String)
        case streaming
        case error(String)
    }
    
    // MARK: - Initialization
    
    init() {
        self.toolExecutor = ToolExecutor(searchService: SearchServiceFactory.createProvider())
        refreshLLMProvider()
    }
    
    /// 刷新 LLM Provider（设置变更时调用）
    func refreshLLMProvider() {
        self.llmProvider = LLMServiceFactory.createProvider()
        self.toolExecutor = ToolExecutor(searchService: SearchServiceFactory.createProvider())
    }
    
    // MARK: - Main Entry Point
    
    /// 处理用户消息
    /// - Parameters:
    ///   - userMessage: 用户输入的消息
    ///   - conversation: 当前会话
    ///   - modelContext: SwiftData 上下文
    /// - Returns: 生成的消息列表
    func processUserMessage(
        _ userMessage: String,
        conversation: Conversation,
        modelContext: ModelContext
    ) async throws -> [Message] {
        
        // 重置状态
        isProcessing = true
        streamingContent = ""
        currentStatus = .thinking
        
        defer {
            isProcessing = false
            currentStatus = .idle
        }
        
        // 1. 检查 LLM 配置
        guard let llmProvider else {
            throw AgentError.noLLMConfigured
        }
        
        // 2. 检查限流（仅对内置模式生效）
        if settingsManager.settings.llmMode == .builtin {
            guard usageManager.canSendMessage() else {
                throw AgentError.rateLimitExceeded(remaining: usageManager.resetTimeDescription)
            }
            usageManager.recordUsage()
        }
        
        // 3. 创建并保存用户消息
        let userMsg = Message.userMessage(conversationID: conversation.id, content: userMessage)
        modelContext.insert(userMsg)
        
        // 4. 构建消息上下文
        var llmMessages = buildContextMessages(conversation: conversation, modelContext: modelContext)
        llmMessages.append(LLMMessage(role: "user", content: userMessage))
        
        // 5. Agent Loop
        var iterations = 0
        var resultMessages: [Message] = [userMsg]
        
        while iterations < maxIterations {
            iterations += 1
            
            // 5.1 调用 LLM
            currentStatus = .thinking
            let response = try await llmProvider.chat(
                messages: llmMessages,
                tools: toolExecutor.availableTools
            )
            
            // 5.2 检查是否有 Tool Calls
            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                // 创建带工具调用的 Assistant 消息
                let assistantMsg = Message(
                    conversationID: conversation.id,
                    role: .assistant,
                    content: response.content ?? "",
                    toolCalls: toolCalls.map {
                        ToolCallRecord(id: $0.id, name: $0.name, arguments: $0.arguments)
                    }
                )
                modelContext.insert(assistantMsg)
                resultMessages.append(assistantMsg)
                
                // 将 assistant 消息添加到上下文
                llmMessages.append(LLMMessage(
                    role: "assistant",
                    content: response.content,
                    toolCalls: toolCalls
                ))
                
                // 5.3 执行每个工具
                for toolCall in toolCalls {
                    currentStatus = .callingTool(toolCall.name)
                    
                    let result = await toolExecutor.execute(toolCall)
                    
                    // 创建工具结果消息
                    let toolMsg = Message.toolMessage(
                        conversationID: conversation.id,
                        toolCallID: toolCall.id,
                        result: result
                    )
                    modelContext.insert(toolMsg)
                    resultMessages.append(toolMsg)
                    
                    // 添加到 LLM 上下文
                    llmMessages.append(LLMMessage(
                        role: "tool",
                        content: result,
                        toolCallId: toolCall.id
                    ))
                }
                
                // 继续循环
                continue
            }
            
            // 5.4 无 Tool Calls，创建最终回复
            let finalMsg = Message.assistantMessage(
                conversationID: conversation.id,
                content: response.content ?? ""
            )
            modelContext.insert(finalMsg)
            resultMessages.append(finalMsg)
            
            break
        }
        
        // 6. 更新会话时间戳
        conversation.updateTimestamp()
        
        // 7. 保存更改
        try modelContext.save()
        
        return resultMessages
    }
    
    // MARK: - Streaming Version
    
    /// 流式处理用户消息
    func processUserMessageStreaming(
        _ userMessage: String,
        conversation: Conversation,
        modelContext: ModelContext,
        onUpdate: @escaping (String) -> Void
    ) async throws -> Message? {
        
        isProcessing = true
        isCancelled = false
        streamingContent = ""
        currentStatus = .streaming
        
        defer {
            isProcessing = false
            currentStatus = .idle
        }
        
        guard let llmProvider else {
            throw AgentError.noLLMConfigured
        }
        
        // 检查限流
        if settingsManager.settings.llmMode == .builtin {
            guard usageManager.canSendMessage() else {
                throw AgentError.rateLimitExceeded(remaining: usageManager.resetTimeDescription)
            }
            usageManager.recordUsage()
        }
        
        // 创建用户消息
        let userMsg = Message.userMessage(conversationID: conversation.id, content: userMessage)
        modelContext.insert(userMsg)
        
        // 构建上下文
        var llmMessages = buildContextMessages(conversation: conversation, modelContext: modelContext)
        llmMessages.append(LLMMessage(role: "user", content: userMessage))
        
        // 流式调用
        var fullContent = ""
        let stream = llmProvider.chatStream(messages: llmMessages, tools: nil)
        
        for try await chunk in stream {
            // Check for cancellation
            if isCancelled {
                break
            }
            
            switch chunk.type {
            case .content(let text):
                fullContent += text
                streamingContent = fullContent
                onUpdate(fullContent)
            case .done:
                break
            default:
                break
            }
        }
        
        // Only save if we have content (even partial content from cancellation)
        guard !fullContent.isEmpty else {
            // If cancelled before any content, don't save assistant message
            try? modelContext.save()
            return nil
        }
        
        // 创建最终消息 (可能是完整的或被中断的)
        let assistantMsg = Message.assistantMessage(
            conversationID: conversation.id,
            content: fullContent
        )
        modelContext.insert(assistantMsg)
        
        conversation.updateTimestamp()
        try modelContext.save()
        
        return assistantMsg
    }
    
    /// 取消当前处理
    func cancelProcessing() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Private Methods
    
    private func buildContextMessages(
        conversation: Conversation,
        modelContext: ModelContext
    ) -> [LLMMessage] {
        var messages: [LLMMessage] = []
        
        // 添加 System Prompt
        let includeSearch = settingsManager.settings.isSearchEnabled
        let systemPrompt = SystemPromptBuilder.build(includeSearchCapability: includeSearch)
        messages.append(LLMMessage(role: "system", content: systemPrompt))
        
        // 获取历史消息
        let conversationID = conversation.id
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.conversationID == conversationID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        if let historyMessages = try? modelContext.fetch(descriptor) {
            // 限制最近 20 条消息
            let recentMessages = historyMessages.suffix(20)
            for msg in recentMessages {
                messages.append(LLMMessage.from(msg))
            }
        }
        
        return messages
    }
}
