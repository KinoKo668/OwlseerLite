//
//  PrivacyPolicyView.swift
//  OwlSeerLite
//
//  Privacy Policy - Industry Best Practices
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.largeTitle.bold())
                    
                    Text("Last Updated: February 2025")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Introduction
                sectionView(title: "Introduction") {
                    Text("""
                    OwlSeer Lite ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

                    Please read this Privacy Policy carefully. By using the application, you agree to the collection and use of information in accordance with this policy.
                    """)
                }
                
                // Information We Collect
                sectionView(title: "Information We Collect") {
                    VStack(alignment: .leading, spacing: 12) {
                        subsectionView(title: "Information You Provide") {
                            Text("""
                            • **Chat Messages**: Your conversations with the AI assistant are stored locally on your device only.
                            • **API Keys**: If you choose to use custom API keys, they are securely stored in iOS Keychain on your device.
                            • **Feedback**: When you submit feedback about AI-generated content, the feedback content and related message are stored locally.
                            """)
                        }
                        
                        subsectionView(title: "Automatically Collected Information") {
                            Text("""
                            • **Usage Data**: Basic usage statistics such as daily message count are stored locally to manage free tier limits.
                            • **Device Information**: We do not collect device identifiers or hardware information.
                            """)
                        }
                    }
                }
                
                // How We Use Your Information
                sectionView(title: "How We Use Your Information") {
                    Text("""
                    We use the information we collect to:

                    • Provide and maintain the application functionality
                    • Process your requests to the AI assistant
                    • Manage your usage within free tier limits
                    • Improve our services based on aggregated, anonymized feedback
                    • Comply with legal obligations
                    """)
                }
                
                // Data Storage and Security
                sectionView(title: "Data Storage and Security") {
                    Text("""
                    **Local Storage**: All your data, including chat history, settings, and feedback, is stored locally on your device using iOS secure storage mechanisms.

                    **API Keys**: Custom API keys are stored in iOS Keychain, Apple's secure credential storage system.

                    **No Cloud Sync**: We do not upload your personal data to any cloud servers. Your data remains on your device.

                    **Data Encryption**: All locally stored sensitive data is encrypted using iOS native encryption.
                    """)
                }
                
                // Third-Party Services
                sectionView(title: "Third-Party Services") {
                    Text("""
                    Our application may use the following third-party services:

                    **AI Service Providers**:
                    • Moonshot AI (Kimi) - for free tier users
                    • OpenAI, Anthropic, Google - if you configure custom API keys

                    When you send messages, they are transmitted to these AI providers for processing. Please review their respective privacy policies:
                    • Moonshot AI: https://www.moonshot.cn/privacy
                    • OpenAI: https://openai.com/privacy
                    • Anthropic: https://www.anthropic.com/privacy
                    • Google: https://policies.google.com/privacy

                    **Search Services** (Optional):
                    • Tavily or SerpAPI - only if you enable and configure web search functionality
                    """)
                }
                
                // Your Rights
                sectionView(title: "Your Rights") {
                    Text("""
                    You have the following rights regarding your data:

                    • **Access**: View all your data stored in the app
                    • **Delete**: Delete your chat history, feedback records, and stored API keys at any time
                    • **Export**: Your data is stored locally and accessible on your device
                    • **Opt-out**: You can disable optional features like web search at any time

                    To exercise these rights, use the settings and management features within the app, or contact us directly.
                    """)
                }
                
                // Children's Privacy
                sectionView(title: "Children's Privacy") {
                    Text("""
                    Our application is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.
                    """)
                }
                
                // Changes to This Policy
                sectionView(title: "Changes to This Privacy Policy") {
                    Text("""
                    We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

                    You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.
                    """)
                }
                
                // Contact Us
                sectionView(title: "Contact Us") {
                    Text("""
                    If you have any questions about this Privacy Policy, please contact us:

                    • Email: support@owlseer.app
                    • In-App: Settings > Feedback
                    """)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    
    private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
            
            content()
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
    
    private func subsectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            content()
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
