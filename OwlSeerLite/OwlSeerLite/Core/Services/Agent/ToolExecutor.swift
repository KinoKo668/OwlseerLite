//
//  ToolExecutor.swift
//  OwlSeerLite
//
//  工具执行器
//

import Foundation

final class ToolExecutor {
    private let searchService: SearchProviderProtocol?
    
    init(searchService: SearchProviderProtocol? = nil) {
        self.searchService = searchService
    }
    
    /// 可用工具列表
    var availableTools: [AgentTool] {
        var tools = BuiltinTools.all
        if searchService != nil {
            tools.append(BuiltinTools.webSearch)
        }
        return tools
    }
    
    /// 执行工具调用
    func execute(_ toolCall: LLMToolCall) async -> String {
        switch toolCall.name {
        case "generate_hook":
            return executeGenerateHook(arguments: toolCall.arguments)
            
        case "script_formatter":
            return executeScriptFormatter(arguments: toolCall.arguments)
            
        case "trend_analyzer":
            return executeTrendAnalyzer(arguments: toolCall.arguments)
            
        case "web_search":
            guard let searchService else {
                return "⚠️ 错误：未配置搜索 API Key。请在设置中配置 Tavily 或 SerpAPI 的 Key 以启用联网搜索功能。"
            }
            return await executeWebSearch(arguments: toolCall.arguments, service: searchService)
            
        default:
            return "⚠️ 未知工具: \(toolCall.name)"
        }
    }
    
    // MARK: - Built-in Skills (Pure Prompt)
    
    /// 生成 Hook 文案
    private func executeGenerateHook(arguments: String) -> String {
        guard let params = parseParams(HookParams.self, from: arguments) else {
            return "参数解析失败，请提供主题(topic)参数"
        }
        
        let style = params.style ?? "悬念型"
        let count = params.count ?? 5
        
        return """
        【Hook 生成任务】
        
        请为以下内容生成 \(count) 个 TikTok 开头黄金3秒的 Hook 文案：
        
        📌 主题：\(params.topic)
        🎨 风格：\(style)
        
        要求：
        1. 每个 Hook 控制在 15 字以内
        2. 要能在 3 秒内抓住注意力
        3. 引发好奇心或共鸣
        4. 适合口播或字幕展示
        5. 避免过于夸张的标题党
        
        输出格式：
        1. [Hook文案] - 简短说明为什么有效
        2. ...
        
        请开始生成：
        """
    }
    
    /// 脚本格式化
    private func executeScriptFormatter(arguments: String) -> String {
        guard let params = parseParams(ScriptFormatterParams.self, from: arguments) else {
            return "参数解析失败，请提供内容(content)参数"
        }
        
        let duration = params.duration ?? 60
        let format = params.format ?? "标准分镜"
        
        return """
        【分镜脚本生成任务】
        
        请将以下内容转换为 TikTok \(format)格式的分镜脚本：
        
        📝 原始内容：
        \(params.content)
        
        ⏱ 目标时长：约 \(duration) 秒
        
        请按照以下格式输出分镜脚本：
        
        | 序号 | 时间 | 画面描述 | 口播/字幕 | 备注 |
        |-----|------|---------|----------|------|
        | 1 | 0-3s | 开场画面 | Hook文案 | 抓注意力 |
        | 2 | 3-10s | ... | ... | ... |
        
        要求：
        1. 开头3秒必须有强 Hook
        2. 节奏紧凑，信息密度适中
        3. 结尾有明确的 CTA（行动号召）
        4. 标注需要的素材或特效建议
        
        请开始生成：
        """
    }
    
    /// 趋势分析
    private func executeTrendAnalyzer(arguments: String) -> String {
        guard let params = parseParams(TrendAnalyzerParams.self, from: arguments) else {
            return "参数解析失败，请提供类别(category)参数"
        }
        
        let region = params.region ?? "中国"
        
        return """
        【趋势分析任务】
        
        请分析 \(region) 地区 TikTok \(params.category) 领域的当前热门趋势：
        
        请从以下维度进行分析：
        
        ## 1. 热门内容形式
        - 当前流行的视频类型
        - 热门的拍摄手法
        - 流行的剪辑风格
        
        ## 2. 爆款元素
        - 常见的 Hook 套路
        - 热门 BGM 风格
        - 流行的特效或滤镜
        
        ## 3. 创作建议
        - 适合新手的切入点
        - 差异化方向建议
        - 需要避免的雷区
        
        ## 4. 参考方向
        - 3-5 个可模仿的内容方向
        - 每个方向的简要说明
        
        请基于你的知识提供分析（注意：这不是实时数据，仅供参考）：
        """
    }
    
    // MARK: - Web Search Skill
    
    private func executeWebSearch(arguments: String, service: SearchProviderProtocol) async -> String {
        guard let params = parseParams(SearchParams.self, from: arguments) else {
            return "搜索参数解析失败，请提供查询关键词(query)"
        }
        
        let maxResults = params.maxResults ?? 5
        
        do {
            let results = try await service.search(query: params.query, maxResults: maxResults)
            
            if results.isEmpty {
                return "未找到相关搜索结果"
            }
            
            var output = "🔍 搜索结果：\"\(params.query)\"\n\n"
            
            for (index, result) in results.enumerated() {
                output += """
                \(index + 1). **\(result.title)**
                   \(result.snippet)
                   🔗 \(result.url)
                
                """
            }
            
            output += "\n请基于以上搜索结果，为用户提供分析和建议。"
            
            return output
        } catch {
            return "搜索失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseParams<T: Decodable>(_ type: T.Type, from arguments: String) -> T? {
        guard let data = arguments.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
