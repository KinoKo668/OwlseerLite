//
//  SettingsView.swift
//  OwlSeerLite
//
//  Settings Page
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Language
                languageSection
                
                // LLM Config
                llmSection
                
                // Search Config
                searchSection
                
                // Usage Statistics
                usageSection
                
                // About
                aboutSection
            }
            .navigationTitle("settings.title".localized)
            .alert("common.hint".localized, isPresented: $viewModel.showAlert) {
                Button("common.confirm".localized, role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        Section {
            Picker("settings.language".localized, selection: $viewModel.appLanguage) {
                ForEach(AppSettings.AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
        } header: {
            Text("settings.language".localized)
        }
    }
    
    // MARK: - LLM Section
    
    private var llmSection: some View {
        Section {
            // Mode Selection
            Picker("settings.mode".localized, selection: $viewModel.llmMode) {
                Text("settings.mode_free".localized).tag(AppSettings.LLMMode.builtin)
                Text("settings.mode_custom".localized).tag(AppSettings.LLMMode.custom)
            }
            .pickerStyle(.segmented)
            
            if viewModel.llmMode == .builtin {
                // Free mode description
                VStack(alignment: .leading, spacing: 8) {
                    Label("settings.daily_quota".localized(with: 10), systemImage: "gift")
                        .font(.subheadline)
                    
                    Text("settings.free_mode_desc".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                // Custom Key config
                NavigationLink {
                    APIKeyConfigView()
                } label: {
                    HStack {
                        Label("settings.configure_key".localized, systemImage: "key")
                        Spacer()
                        if viewModel.hasCustomLLMKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        } header: {
            Text("settings.ai_engine".localized)
        } footer: {
            if viewModel.llmMode == .custom && !viewModel.hasCustomLLMKey {
                Text("settings.configure_key_hint".localized)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        Section {
            Toggle(isOn: $viewModel.isSearchEnabled) {
                Label("settings.web_search".localized, systemImage: "globe")
            }
            
            if viewModel.isSearchEnabled {
                Picker("settings.search_feature".localized, selection: $viewModel.searchProvider) {
                    Text("Tavily").tag(AppSettings.SearchProviderType.tavily as AppSettings.SearchProviderType?)
                    Text("SerpAPI").tag(AppSettings.SearchProviderType.serpapi as AppSettings.SearchProviderType?)
                }
                
                NavigationLink {
                    SearchKeyConfigView()
                } label: {
                    HStack {
                        Label("settings.configure_search_key".localized, systemImage: "magnifyingglass")
                        Spacer()
                        if viewModel.hasSearchKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        } header: {
            Text("settings.search_feature".localized)
        } footer: {
            Text("settings.search_enabled_hint".localized)
        }
    }
    
    // MARK: - Usage Section
    
    private var usageSection: some View {
        Section {
            HStack {
                Text("settings.used_today".localized)
                Spacer()
                Text("\(viewModel.usedCount)/\(viewModel.dailyLimit)")
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: viewModel.usageProgress)
                .tint(viewModel.usageProgress > 0.8 ? .orange : .blue)
            
            if viewModel.llmMode == .builtin {
                HStack {
                    Text("settings.reset_time".localized)
                    Spacer()
                    Text(viewModel.resetTime)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("settings.usage_statistics".localized)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings.version".localized)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("settings.privacy_policy".localized, systemImage: "hand.raised")
            }
            
            NavigationLink {
                TermsOfServiceView()
            } label: {
                Label("settings.terms_of_service".localized, systemImage: "doc.text")
            }
            
            NavigationLink {
                FeedbackHistoryView()
            } label: {
                Label("settings.feedback_history".localized, systemImage: "flag")
            }
            
            Link(destination: URL(string: "https://kinoko668.github.io/OwlseerLite/support.html")!) {
                HStack {
                    Label("settings.help_support".localized, systemImage: "questionmark.circle")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("settings.about".localized)
        } footer: {
            VStack(spacing: 4) {
                Text("settings.app_name".localized)
                Text("settings.ai_disclaimer".localized)
            }
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
}

#Preview {
    SettingsView()
}
