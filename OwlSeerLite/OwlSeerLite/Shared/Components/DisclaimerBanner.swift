//
//  DisclaimerBanner.swift
//  OwlSeerLite
//
//  Disclaimer Banner (App Store Compliance Required)
//

import SwiftUI

struct DisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.caption2)
            
            Text("disclaimer.short".localized)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
}

// MARK: - Extended Disclaimer

struct ExtendedDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Section {
                        Text("disclaimer.intro".localized)
                    }
                    
                    Section {
                        Text("disclaimer.important".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            disclaimerItem(
                                icon: "exclamationmark.triangle",
                                title: "disclaimer.reference_only".localized,
                                description: "disclaimer.reference_only_desc".localized
                            )
                            
                            disclaimerItem(
                                icon: "person.crop.circle.badge.checkmark",
                                title: "disclaimer.user_responsibility".localized,
                                description: "disclaimer.user_responsibility_desc".localized
                            )
                            
                            disclaimerItem(
                                icon: "shield",
                                title: "disclaimer.data_security".localized,
                                description: "disclaimer.data_security_desc".localized
                            )
                            
                            disclaimerItem(
                                icon: "doc.text",
                                title: "disclaimer.ip".localized,
                                description: "disclaimer.ip_desc".localized
                            )
                        }
                    }
                    
                    Section {
                        Text("disclaimer.usage_tips".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• " + "disclaimer.tip_1".localized)
                            Text("• " + "disclaimer.tip_2".localized)
                            Text("• " + "disclaimer.tip_3".localized)
                            Text("• " + "disclaimer.tip_4".localized)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("disclaimer.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("disclaimer.understood".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func disclaimerItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        DisclaimerBanner()
    }
}

#Preview("Extended") {
    ExtendedDisclaimerView()
}
