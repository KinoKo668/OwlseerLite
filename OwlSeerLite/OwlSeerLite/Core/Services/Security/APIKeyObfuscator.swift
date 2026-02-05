//
//  APIKeyObfuscator.swift
//  OwlSeerLite
//
//  预置 API Key 混淆工具 (Kimi 2.5 / 月之暗面)
//
//  ⚠️ 安全说明：
//  这种混淆方式只能增加逆向的成本，无法完全防止 Key 泄露。
//  建议配合以下措施：
//  1. 在月之暗面后台设置消费预算上限
//  2. 配置用量告警
//  3. 发现异常时及时轮换 Key
//

import Foundation

enum APIKeyObfuscator {
    
    // MARK: - Kimi 2.5 API Key (月之暗面)
    
    /// 混淆参数
    private static let shiftValue: UInt8 = 7
    
    /// 使用简单的字节位移混淆
    /// 原始 Key 每个字节 +7 后存储，解码时 -7
    /// Key: sk-8dz4xBU341ONDP9G961KO8srA8UDADffczMWVhs4hukwDGCu (51 chars)
    private static let obfuscatedBytes: [UInt8] = [
        // s  k  -  8  d  z  4  x
        0x7A, 0x72, 0x34, 0x3F, 0x6B, 0x81, 0x3B, 0x7F,
        // B  U  3  4  1  O  N  D
        0x49, 0x5C, 0x3A, 0x3B, 0x38, 0x56, 0x55, 0x4B,
        // P  9  G  9  6  1  K  O
        0x57, 0x40, 0x4E, 0x40, 0x3D, 0x38, 0x52, 0x56,
        // 8  s  r  A  8  U  D  A
        0x3F, 0x7A, 0x79, 0x48, 0x3F, 0x5C, 0x4B, 0x48,
        // D  f  f  c  z  M  W  V
        0x4B, 0x6D, 0x6D, 0x6A, 0x81, 0x54, 0x5E, 0x5D,
        // h  s  4  h  u  k  w  D
        0x6F, 0x7A, 0x3B, 0x6F, 0x7C, 0x72, 0x7E, 0x4B,
        // G  C  u
        0x4E, 0x4A, 0x7C
    ]
    
    // MARK: - Public API
    
    /// 获取预置的 API Key（运行时解混淆）
    static var builtinAPIKey: String {
        guard !obfuscatedBytes.isEmpty else {
            return ""
        }
        
        // 解混淆：每个字节 -7
        let decrypted = obfuscatedBytes.map { byte -> UInt8 in
            byte &- shiftValue  // 使用溢出减法
        }
        
        return String(bytes: decrypted, encoding: .utf8) ?? ""
    }
    
    /// 检查是否配置了预置 Key
    static var hasBuiltinKey: Bool {
        !builtinAPIKey.isEmpty
    }
    
    // MARK: - Development Helper
    
    /// 开发时用于生成混淆数据的辅助方法
    ///
    /// 使用方法：
    /// ```swift
    /// #if DEBUG
    /// APIKeyObfuscator.generateObfuscatedBytes("your-api-key")
    /// #endif
    /// ```
    static func generateObfuscatedBytes(_ key: String) {
        let keyBytes = Array(key.utf8)
        
        // 每个字节 +7
        let obfuscated = keyBytes.map { $0 &+ shiftValue }
        
        // 格式化输出
        var output = "private static let obfuscatedBytes: [UInt8] = [\n"
        
        for (index, byte) in obfuscated.enumerated() {
            if index % 8 == 0 {
                output += "    "
            }
            output += String(format: "0x%02X", byte)
            if index < obfuscated.count - 1 {
                output += ", "
            }
            if (index + 1) % 8 == 0 {
                output += "\n"
            }
        }
        
        output += "\n]"
        
        print("""
        
        ============ API Key 混淆结果 ============
        
        原始 Key 长度: \(key.count) 字符
        
        \(output)
        
        ==========================================
        
        """)
    }
    
    /// 验证混淆/解混淆是否正确（仅开发时使用）
    static func verifyKey() -> Bool {
        let key = builtinAPIKey
        // 基本格式检查：Kimi key 以 sk- 开头
        return key.hasPrefix("sk-") && key.count > 10
    }
}
