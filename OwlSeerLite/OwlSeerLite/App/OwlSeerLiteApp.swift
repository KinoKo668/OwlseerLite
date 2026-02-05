//
//  OwlSeerLiteApp.swift
//  OwlSeerLite
//
//  AI Assistant App - TikTok Creator Tool
//

import SwiftUI
import SwiftData

@main
struct OwlSeerLiteApp: App {
    let modelContainer: ModelContainer
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    init() {
        do {
            let schema = Schema([
                Conversation.self,
                Message.self,
                FeedbackRecord.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: settingsManager.settings.appLanguage.rawValue))
        }
        .modelContainer(modelContainer)
    }
}
