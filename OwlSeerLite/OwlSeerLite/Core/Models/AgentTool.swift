//
//  AgentTool.swift
//  OwlSeerLite
//
//  Agent 工具定义
//

import Foundation

struct AgentTool: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let parameters: ToolParameters
    let skillType: SkillType
    
    enum SkillType: String, Codable {
        case builtinPrompt    // 纯 Prompt 技能
        case webSearch        // 需要配置 Key 的搜索技能
    }
}

struct ToolParameters: Codable {
    let type: String  // "object"
    let properties: [String: ParameterProperty]
    let required: [String]
}

struct ParameterProperty: Codable {
    let type: String
    let description: String
    let enumValues: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case description
        case enumValues = "enum"
    }
}

// MARK: - Built-in Tools Definition

enum BuiltinTools {
    /// 所有内置工具
    static var all: [AgentTool] {
        [generateHook, scriptFormatter, trendAnalyzer]
    }
    
    /// 生成 Hook 文案
    static let generateHook = AgentTool(
        id: "generate_hook",
        name: "generate_hook",
        description: "为 TikTok 视频生成吸引人的开头黄金3秒 Hook 文案，帮助提高视频完播率",
        parameters: ToolParameters(
            type: "object",
            properties: [
                "topic": ParameterProperty(
                    type: "string",
                    description: "视频主题或核心内容",
                    enumValues: nil
                ),
                "style": ParameterProperty(
                    type: "string",
                    description: "Hook 风格",
                    enumValues: ["悬念型", "痛点型", "数据型", "反问型", "故事型"]
                ),
                "count": ParameterProperty(
                    type: "integer",
                    description: "生成数量，默认5个",
                    enumValues: nil
                )
            ],
            required: ["topic"]
        ),
        skillType: .builtinPrompt
    )
    
    /// 脚本格式化工具
    static let scriptFormatter = AgentTool(
        id: "script_formatter",
        name: "script_formatter",
        description: "将文案或创意转换为 TikTok 分镜脚本格式，包含画面描述、口播文案、时长建议",
        parameters: ToolParameters(
            type: "object",
            properties: [
                "content": ParameterProperty(
                    type: "string",
                    description: "需要格式化的原始文案或创意内容",
                    enumValues: nil
                ),
                "duration": ParameterProperty(
                    type: "integer",
                    description: "目标视频时长（秒），默认60秒",
                    enumValues: nil
                ),
                "format": ParameterProperty(
                    type: "string",
                    description: "输出格式",
                    enumValues: ["标准分镜", "简洁版", "详细版"]
                )
            ],
            required: ["content"]
        ),
        skillType: .builtinPrompt
    )
    
    /// 趋势分析工具
    static let trendAnalyzer = AgentTool(
        id: "trend_analyzer",
        name: "trend_analyzer",
        description: "分析 TikTok 热门趋势，提供内容创作建议",
        parameters: ToolParameters(
            type: "object",
            properties: [
                "category": ParameterProperty(
                    type: "string",
                    description: "内容类别",
                    enumValues: ["美食", "时尚", "科技", "搞笑", "教程", "生活", "游戏", "其他"]
                ),
                "region": ParameterProperty(
                    type: "string",
                    description: "目标地区",
                    enumValues: ["中国", "美国", "东南亚", "欧洲", "全球"]
                )
            ],
            required: ["category"]
        ),
        skillType: .builtinPrompt
    )
    
    /// 网络搜索工具（需要用户配置 API Key）
    static let webSearch = AgentTool(
        id: "web_search",
        name: "web_search",
        description: "搜索互联网获取实时信息，用于查询最新趋势、热点事件、竞品分析等",
        parameters: ToolParameters(
            type: "object",
            properties: [
                "query": ParameterProperty(
                    type: "string",
                    description: "搜索关键词",
                    enumValues: nil
                ),
                "max_results": ParameterProperty(
                    type: "integer",
                    description: "最大返回结果数，默认5",
                    enumValues: nil
                )
            ],
            required: ["query"]
        ),
        skillType: .webSearch
    )
}

// MARK: - Tool Parameter Models

struct HookParams: Codable {
    let topic: String
    let style: String?
    let count: Int?
}

struct ScriptFormatterParams: Codable {
    let content: String
    let duration: Int?
    let format: String?
}

struct TrendAnalyzerParams: Codable {
    let category: String
    let region: String?
}

struct SearchParams: Codable {
    let query: String
    let maxResults: Int?
    
    enum CodingKeys: String, CodingKey {
        case query
        case maxResults = "max_results"
    }
}
