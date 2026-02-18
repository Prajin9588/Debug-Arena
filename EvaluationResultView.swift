import SwiftUI

struct EvaluationResultView: View {
    let result: EvaluationResult
    
    var body: some View {
        VStack(spacing: 20) {
            // HEADER
            HStack {
                Text("EVALUATION RESULT")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Image(systemName: result.status == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(result.status.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (result.status == .correct ? Theme.Colors.success : Theme.Colors.error)
                        .opacity(0.1)
                )
                .foregroundColor(result.status == .correct ? Theme.Colors.success : Theme.Colors.error)
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // CARD CONTENT
            HStack(spacing: 20) {
                // Score Ring
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.secondaryBackground.opacity(0.5), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(result.score) / 100.0)
                        .stroke(
                            result.status == .correct ? Theme.Colors.success : Theme.Colors.error,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(result.score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.level.rawValue.uppercased())
                        .font(Theme.Typography.title3)
                        .bold()
                        .foregroundColor(colorForLevel(result.level))
                    
                    Text("Complexity: \(result.complexity.rawValue)")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(16)
            .shadow(color: Theme.Layout.cardShadow, radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            
            // FEEDBACK SECTION
            VStack(alignment: .leading, spacing: 12) {
                Text("FEEDBACK")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(1)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(parseFeedback(result.feedback), id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.isSuccess ? "checkmark.square.fill" : "xmark.square.fill")
                                .foregroundColor(item.isSuccess ? Theme.Colors.success : Theme.Colors.error)
                                .font(.system(size: 16))
                                .padding(.top, 2)
                            
                            Text(item.text)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.02))
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.white.opacity(0.05)),
                            alignment: .bottom
                        )
                    }
                }
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Theme.Colors.background)
    }
    
    // Helper to parse feedback string into list items
    private struct FeedbackItem: Hashable {
        let isSuccess: Bool
        let text: String
    }
    
    private func parseFeedback(_ feedback: String) -> [FeedbackItem] {
        // Assuming feedback items are separated by newlines
        // And maybe prefixed with emojis like ✅, ❌, ⚠️
        
        let lines = feedback.components(separatedBy: .newlines)
        return lines.compactMap { line -> FeedbackItem? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            
            let isSuccess = trimmed.contains("✅") || (!trimmed.contains("❌") && !trimmed.contains("⚠️"))
            // Determine status based on content if not explicit
            // For now simpler:
            return FeedbackItem(isSuccess: isSuccess, text: trimmed)
        }
    }
    
    private func colorForLevel(_ level: UserLevel) -> Color {
        switch level {
        case .failed: return Theme.Colors.error
        case .beginner: return .orange
        case .intermediate: return .yellow
        case .advanced: return .blue
        case .expert: return Theme.Colors.success
        case .passed: return Theme.Colors.success
        }
    }
}
