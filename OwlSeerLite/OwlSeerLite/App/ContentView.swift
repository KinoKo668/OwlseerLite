//
//  ContentView.swift
//  OwlSeerLite
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .chat
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    enum Tab {
        case chat
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("tab.chat".localized, systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.chat)
            
            SettingsView()
                .tabItem {
                    Label("tab.settings".localized, systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .id(settingsManager.settings.appLanguage)
    }
}

#Preview {
    ContentView()
}
