//
//  String+Extensions.swift
//  OwlSeerLite
//
//  字符串扩展
//

import Foundation

extension String {
    /// 去除首尾空白字符
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 检查是否为空（忽略空白字符）
    var isBlank: Bool {
        trimmed.isEmpty
    }
    
    /// 截断字符串
    func truncated(to maxLength: Int, trailing: String = "...") -> String {
        if count > maxLength {
            return String(prefix(maxLength)) + trailing
        }
        return self
    }
    
    /// 移除 Markdown 格式
    var withoutMarkdown: String {
        var result = self
        
        // 移除粗体
        result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        // 移除斜体
        result = result.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
        // 移除行内代码
        result = result.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
        // 移除链接
        result = result.replacingOccurrences(of: "\\[(.+?)\\]\\(.+?\\)", with: "$1", options: .regularExpression)
        // 移除标题标记
        result = result.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
        
        return result
    }
    
    /// 安全的 Base64 编码
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }
    
    /// 安全的 Base64 解码
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Localization

extension String {
    /// Localized string based on app settings
    var localized: String {
        let languageCode = SettingsManager.shared.settings.appLanguage.rawValue
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    /// Localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
