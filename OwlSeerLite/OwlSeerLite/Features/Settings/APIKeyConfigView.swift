//
//  APIKeyConfigView.swift
//  OwlSeerLite
//
//  API Key Configuration Page
//

import SwiftUI

struct APIKeyConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var selectedProvider: AppSettings.LLMProviderType = .openai
    @State private var selectedModel: String = ""
    @State private var customBaseURL = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        Form {
            // Provider Selection
            Section {
                Picker("apikey.provider".localized, selection: $selectedProvider) {
                    ForEach(AppSettings.LLMProviderType.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .onChange(of: selectedProvider) { _, newValue in
                    selectedModel = newValue.availableModels.first ?? ""
                }
                
                Picker("apikey.model".localized, selection: $selectedModel) {
                    ForEach(selectedProvider.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } header: {
                Text("apikey.service_config".localized)
            }
            
            // API Key Input
            Section {
                SecureField("apikey.key_placeholder".localized, text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                
                if !apiKey.isEmpty {
                    HStack {
                        Image(systemName: keyIsValid ? "checkmark.circle" : "xmark.circle")
                            .foregroundStyle(keyIsValid ? .green : .red)
                        Text(keyIsValid ? "apikey.format_correct".localized : "apikey.format_incorrect".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("apikey.key_placeholder".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(keyFormatHint)
                    Link("apikey.get_key".localized, destination: keyURL)
                }
            }
            
            // Custom Base URL (Optional)
            Section {
                TextField("apikey.base_url_placeholder".localized, text: $customBaseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("apikey.advanced".localized)
            } footer: {
                Text("apikey.base_url_hint".localized(with: selectedProvider.defaultBaseURL))
            }
            
            // Save Button
            Section {
                Button {
                    saveSettings()
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("common.save".localized)
                        }
                        Spacer()
                    }
                }
                .disabled(!canSave || isSaving)
                
                if keychain.hasKey(for: .llmAPIKey) {
                    Button(role: .destructive) {
                        deleteKey()
                    } label: {
                        HStack {
                            Spacer()
                            Text("apikey.delete_key".localized)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("apikey.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("common.hint".localized, isPresented: $showAlert) {
            Button("common.confirm".localized, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var keyIsValid: Bool {
        keychain.validateKeyFormat(apiKey, provider: selectedProvider)
    }
    
    private var canSave: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var keyFormatHint: String {
        switch selectedProvider {
        case .openai:
            return "Format: sk-xxx or sk-proj-xxx"
        case .anthropic:
            return "Format: sk-ant-xxx"
        case .gemini:
            return "Format: AIzaXXX..."
        case .deepseek:
            return "Format: sk-xxx"
        case .kimi:
            return "Format: sk-xxx"
        }
    }
    
    private var keyURL: URL {
        switch selectedProvider {
        case .openai:
            return URL(string: "https://platform.openai.com/api-keys")!
        case .anthropic:
            return URL(string: "https://console.anthropic.com/settings/keys")!
        case .gemini:
            return URL(string: "https://aistudio.google.com/app/apikey")!
        case .deepseek:
            return URL(string: "https://platform.deepseek.com/api_keys")!
        case .kimi:
            return URL(string: "https://platform.moonshot.cn/console/api-keys")!
        }
    }
    
    // MARK: - Methods
    
    private func loadCurrentSettings() {
        let settings = SettingsManager.shared.settings
        selectedProvider = settings.customLLMProvider ?? .openai
        
        // 验证保存的模型是否在当前 provider 的可用模型列表中
        // 如果不在（可能是旧的模型名称），则重置为第一个可用模型
        if let savedModel = settings.selectedModel,
           selectedProvider.availableModels.contains(savedModel) {
            selectedModel = savedModel
        } else {
            selectedModel = selectedProvider.availableModels.first ?? ""
        }
        
        customBaseURL = settings.customBaseURL ?? ""
    }
    
    private func saveSettings() {
        isSaving = true
        
        do {
            // Save to Keychain
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try keychain.save(key: trimmedKey, for: .llmAPIKey)
            
            // Update settings
            var settings = SettingsManager.shared.settings
            settings.customLLMProvider = selectedProvider
            settings.selectedModel = selectedModel
            settings.customBaseURL = customBaseURL.isEmpty ? nil : customBaseURL
            settings.llmMode = .custom
            SettingsManager.shared.settings = settings
            
            alertMessage = "apikey.save_success".localized
            showAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } catch {
            alertMessage = "apikey.save_failed".localized + ": \(error.localizedDescription)"
            showAlert = true
        }
        
        isSaving = false
    }
    
    private func deleteKey() {
        keychain.delete(for: .llmAPIKey)
        apiKey = ""
        
        var settings = SettingsManager.shared.settings
        settings.llmMode = .builtin
        SettingsManager.shared.settings = settings
        
        alertMessage = "apikey.deleted".localized
        showAlert = true
    }
}

// MARK: - Search Key Config View

struct SearchKeyConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        Form {
            Section {
                SecureField("apikey.key_placeholder".localized, text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
            } header: {
                Text("apikey.key_placeholder".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    if SettingsManager.shared.settings.searchProvider == .tavily {
                        Link("apikey.get_tavily_key".localized, destination: URL(string: "https://tavily.com")!)
                    } else {
                        Link("apikey.get_serpapi_key".localized, destination: URL(string: "https://serpapi.com")!)
                    }
                }
            }
            
            Section {
                Button {
                    saveKey()
                } label: {
                    HStack {
                        Spacer()
                        Text("common.save".localized)
                        Spacer()
                    }
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                if keychain.hasKey(for: .searchAPIKey) {
                    Button(role: .destructive) {
                        deleteKey()
                    } label: {
                        HStack {
                            Spacer()
                            Text("apikey.delete_key".localized)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("apikey.search_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("common.hint".localized, isPresented: $showAlert) {
            Button("common.confirm".localized, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveKey() {
        do {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try keychain.save(key: trimmedKey, for: .searchAPIKey)
            alertMessage = "apikey.save_success".localized
            showAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } catch {
            alertMessage = "apikey.save_failed".localized + ": \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func deleteKey() {
        keychain.delete(for: .searchAPIKey)
        apiKey = ""
        alertMessage = "apikey.deleted".localized
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        APIKeyConfigView()
    }
}
