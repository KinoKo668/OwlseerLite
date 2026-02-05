//
//  AlertModifier.swift
//  OwlSeerLite
//
//  通用弹窗修饰器
//

import SwiftUI

// MARK: - Alert State

struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
        
        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }
    }
    
    static func info(title: String = "提示", message: String) -> AlertState {
        AlertState(
            title: title,
            message: message,
            primaryButton: AlertButton(title: "确定"),
            secondaryButton: nil
        )
    }
    
    static func error(message: String) -> AlertState {
        AlertState(
            title: "错误",
            message: message,
            primaryButton: AlertButton(title: "确定"),
            secondaryButton: nil
        )
    }
    
    static func confirm(
        title: String = "确认",
        message: String,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void
    ) -> AlertState {
        AlertState(
            title: title,
            message: message,
            primaryButton: AlertButton(title: confirmTitle, action: onConfirm),
            secondaryButton: AlertButton(title: cancelTitle, role: .cancel)
        )
    }
    
    static func destructive(
        title: String = "确认删除",
        message: String,
        deleteTitle: String = "删除",
        onDelete: @escaping () -> Void
    ) -> AlertState {
        AlertState(
            title: title,
            message: message,
            primaryButton: AlertButton(title: deleteTitle, role: .destructive, action: onDelete),
            secondaryButton: AlertButton(title: "取消", role: .cancel)
        )
    }
}

// MARK: - Alert Modifier

struct AlertModifier: ViewModifier {
    @Binding var alertState: AlertState?
    
    func body(content: Content) -> some View {
        content
            .alert(
                alertState?.title ?? "",
                isPresented: Binding(
                    get: { alertState != nil },
                    set: { if !$0 { alertState = nil } }
                ),
                presenting: alertState
            ) { state in
                if let secondary = state.secondaryButton {
                    Button(secondary.title, role: secondary.role) {
                        secondary.action()
                    }
                }
                
                if let primary = state.primaryButton {
                    Button(primary.title, role: primary.role) {
                        primary.action()
                    }
                }
            } message: { state in
                Text(state.message)
            }
    }
}

extension View {
    func alert(state: Binding<AlertState?>) -> some View {
        modifier(AlertModifier(alertState: state))
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: TimeInterval
    
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message {
                    toastView(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            workItem?.cancel()
                            let task = DispatchWorkItem {
                                withAnimation {
                                    self.message = nil
                                }
                            }
                            workItem = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
                        }
                }
            }
            .animation(.spring(), value: message)
    }
    
    private func toastView(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .cornerRadius(20)
            .shadow(radius: 4)
            .padding(.top, 50)
    }
}

extension View {
    func toast(message: Binding<String?>, duration: TimeInterval = 2) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var alertState: AlertState?
        @State private var toastMessage: String?
        
        var body: some View {
            VStack(spacing: 20) {
                Button("显示提示") {
                    alertState = .info(message: "这是一条提示信息")
                }
                
                Button("显示确认") {
                    alertState = .confirm(
                        message: "确定要执行此操作吗？",
                        onConfirm: { print("Confirmed") }
                    )
                }
                
                Button("显示 Toast") {
                    toastMessage = "操作成功！"
                }
            }
            .alert(state: $alertState)
            .toast(message: $toastMessage)
        }
    }
    
    return PreviewWrapper()
}
