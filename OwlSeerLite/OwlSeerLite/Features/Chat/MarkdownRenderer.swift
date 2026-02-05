//
//  MarkdownRenderer.swift
//  OwlSeerLite
//
//  Markdown 渲染组件
//

import SwiftUI

struct MarkdownRenderer: View {
    let content: String
    
    var body: some View {
        Text(attributedContent)
            .textSelection(.enabled)
    }
    
    private var attributedContent: AttributedString {
        do {
            let attributed = try AttributedString(markdown: content, options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))
            return attributed
        } catch {
            return AttributedString(content)
        }
    }
}

// MARK: - Advanced Markdown View (for complex content)

struct AdvancedMarkdownView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseBlocks(), id: \.id) { block in
                blockView(for: block)
            }
        }
    }
    
    // MARK: - Block Parsing
    
    private struct MarkdownBlock: Identifiable {
        let id = UUID()
        let type: BlockType
        let content: String
        
        enum BlockType {
            case paragraph
            case heading(Int)
            case codeBlock(String?)
            case bulletList
            case numberedList
            case blockquote
        }
    }
    
    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: "\n")
        var currentBlock = ""
        var inCodeBlock = false
        var codeLanguage: String?
        
        for line in lines {
            // 代码块
            if line.hasPrefix("```") {
                if inCodeBlock {
                    blocks.append(MarkdownBlock(type: .codeBlock(codeLanguage), content: currentBlock))
                    currentBlock = ""
                    inCodeBlock = false
                    codeLanguage = nil
                } else {
                    if !currentBlock.isEmpty {
                        blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                        currentBlock = ""
                    }
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3))
                    if codeLanguage?.isEmpty == true { codeLanguage = nil }
                }
                continue
            }
            
            if inCodeBlock {
                currentBlock += (currentBlock.isEmpty ? "" : "\n") + line
                continue
            }
            
            // 标题
            if line.hasPrefix("# ") {
                if !currentBlock.isEmpty {
                    blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                    currentBlock = ""
                }
                blocks.append(MarkdownBlock(type: .heading(1), content: String(line.dropFirst(2))))
                continue
            }
            if line.hasPrefix("## ") {
                if !currentBlock.isEmpty {
                    blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                    currentBlock = ""
                }
                blocks.append(MarkdownBlock(type: .heading(2), content: String(line.dropFirst(3))))
                continue
            }
            if line.hasPrefix("### ") {
                if !currentBlock.isEmpty {
                    blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                    currentBlock = ""
                }
                blocks.append(MarkdownBlock(type: .heading(3), content: String(line.dropFirst(4))))
                continue
            }
            
            // 引用
            if line.hasPrefix("> ") {
                if !currentBlock.isEmpty {
                    blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                    currentBlock = ""
                }
                blocks.append(MarkdownBlock(type: .blockquote, content: String(line.dropFirst(2))))
                continue
            }
            
            // 普通段落
            if line.isEmpty {
                if !currentBlock.isEmpty {
                    blocks.append(MarkdownBlock(type: .paragraph, content: currentBlock))
                    currentBlock = ""
                }
            } else {
                currentBlock += (currentBlock.isEmpty ? "" : "\n") + line
            }
        }
        
        if !currentBlock.isEmpty {
            blocks.append(MarkdownBlock(type: inCodeBlock ? .codeBlock(codeLanguage) : .paragraph, content: currentBlock))
        }
        
        return blocks
    }
    
    // MARK: - Block Views
    
    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block.type {
        case .paragraph:
            MarkdownRenderer(content: block.content)
            
        case .heading(let level):
            Text(block.content)
                .font(headingFont(level: level))
                .fontWeight(.bold)
            
        case .codeBlock:
            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.content)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
            }
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
        case .blockquote:
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3)
                
                Text(block.content)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
            
        default:
            MarkdownRenderer(content: block.content)
        }
    }
    
    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        case 3: return .headline
        default: return .body
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading) {
            MarkdownRenderer(content: """
            这是一段 **加粗** 和 *斜体* 文本。
            
            还有 `行内代码` 和 [链接](https://example.com)。
            
            1. 第一项
            2. 第二项
            3. 第三项
            """)
        }
        .padding()
    }
}
