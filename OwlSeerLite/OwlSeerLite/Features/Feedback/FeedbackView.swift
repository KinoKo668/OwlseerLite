//
//  FeedbackView.swift
//  OwlSeerLite
//
//  Feedback/Report Sheet
//

import SwiftUI
import SwiftData

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let message: Message
    
    @State private var selectedReason: FeedbackReason = .inaccurate
    @State private var additionalInfo = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                } header: {
                    Text("feedback.content".localized)
                }
                
                Section {
                    ForEach(FeedbackReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(reason.displayName)
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("feedback.reason".localized)
                }
                
                Section {
                    TextField("feedback.additional_placeholder".localized, text: $additionalInfo, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("feedback.additional_info".localized)
                }
            }
            .navigationTitle("feedback.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("feedback.submit".localized) {
                        submitFeedback()
                    }
                }
            }
            .alert("feedback.thank_you".localized, isPresented: $showConfirmation) {
                Button("common.confirm".localized) {
                    dismiss()
                }
            } message: {
                Text("feedback.thank_you_message".localized)
            }
        }
    }
    
    private func submitFeedback() {
        // Create feedback record
        let feedback = FeedbackRecord(
            messageID: message.id,
            reason: selectedReason,
            additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
        )
        
        modelContext.insert(feedback)
        
        // Mark message as flagged
        message.isFlagged = true
        
        do {
            try modelContext.save()
            showConfirmation = true
        } catch {
            print("Save feedback failed: \(error)")
            dismiss()
        }
    }
}

// MARK: - Feedback History View

struct FeedbackHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedbackRecord.createdAt, order: .reverse) private var feedbacks: [FeedbackRecord]
    
    var body: some View {
        List {
            if feedbacks.isEmpty {
                ContentUnavailableView(
                    "feedback.no_records".localized,
                    systemImage: "flag",
                    description: Text("feedback.no_records_hint".localized)
                )
            } else {
                ForEach(feedbacks) { feedback in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(feedback.feedbackReason.displayName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formattedDate(feedback.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let additionalInfo = feedback.additionalInfo {
                            Text(additionalInfo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteFeedbacks)
            }
        }
        .navigationTitle("feedback.history".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteFeedbacks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(feedbacks[index])
        }
    }
}

#Preview {
    FeedbackView(
        message: Message(
            conversationID: UUID(),
            role: .assistant,
            content: "This is a test message to demonstrate the feedback feature."
        )
    )
}
