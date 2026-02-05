//
//  LoadingIndicator.swift
//  OwlSeerLite
//
//  加载动画组件
//

import SwiftUI

struct LoadingIndicator: View {
    let message: String
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 动画点
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .offset(y: offsetFor(index: index))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                phase = 1
            }
        }
    }
    
    private func offsetFor(index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let adjustedPhase = (phase + delay).truncatingRemainder(dividingBy: 1.0)
        return -4 * sin(adjustedPhase * .pi)
    }
}

// MARK: - Pulse Loader

struct PulseLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
            
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            
            Image(systemName: "bird")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingIndicator(message: "正在思考...")
        
        TypingIndicator()
        
        PulseLoader()
    }
    .padding()
}
