import SwiftUI

struct ReportView: View {
    let result: EvaluationResult
    var onDismiss: () -> Void
    
    // Computed props for display
    private var isPassed: Bool { result.status == .correct }
    private var statusColor: Color { isPassed ? Theme.Colors.success : Theme.Colors.error }
    private var statusIcon: String { isPassed ? "checkmark.circle.fill" : "xmark.circle.fill" }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dimiss Indicator
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Status Banner
                statusBanner
                
                // Performance Card
                performanceCard
                
                // Failure Section (Conditional)
                if !isPassed {
                    failureSection
                }
                
                // Action Button
                Button(action: onDismiss) {
                    Text(isPassed ? "CONTINUE" : "TRY AGAIN")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPassed ? Theme.Colors.success : Theme.Colors.action)
                        .cornerRadius(Theme.Layout.cornerRadius)
                        .shadow(color: (isPassed ? Theme.Colors.success : Theme.Colors.action).opacity(0.3), radius: 10, y: 5)
                }
                .padding(.top, 10)
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Components
    
    private var statusBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.system(size: 40))
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isPassed ? "EVALUATION PASSED" : "EVALUATION FAILED")
                    .font(Theme.Typography.title3)
                    .foregroundColor(statusColor)
                
                Text(isPassed ? "Great job! Code compiled successfully." : "Issues found in your code.")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var performanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("PERFORMANCE ANALYSIS")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Score Ring
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.background, lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(result.score) / 100.0)
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(result.score)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                Divider()
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    PerformanceRow(label: "Complexity", value: result.complexity.rawValue, icon: "cube.fill", color: Theme.Colors.electricCyan)
                    PerformanceRow(label: "Level", value: result.level.rawValue.uppercased(), icon: "chart.bar.fill", color: .orange)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
    }
    
    private var failureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DIAGNOSTICS")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 0) {
                // Parse feedback items
                ForEach(parseFeedback(result.feedback), id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(item.isSuccess ? Theme.Colors.success : Theme.Colors.error)
                            .padding(.top, 2)
                        
                        Text(item.text)
                            .font(Theme.Typography.codeFont) // Use code font for error details
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding()
                    .background(item.isSuccess ? Color.white.opacity(0) : Theme.Colors.error.opacity(0.05))
                    
                    Divider()
                }
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // Helpers
    
    struct FeedbackItem: Hashable {
        let isSuccess: Bool
        let text: String
    }
    
    private func parseFeedback(_ feedback: String) -> [FeedbackItem] {
        // Reuse logic from EvaluationResultView roughly
        let lines = feedback.components(separatedBy: "\n")
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            
            // Heuristic detection
            let isSuccess = trimmed.contains("✅") || trimmed.contains("Correct")
            let cleanText = trimmed
                .replacingOccurrences(of: "✅", with: "")
                .replacingOccurrences(of: "❌", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            return FeedbackItem(isSuccess: isSuccess, text: cleanText)
        }
    }
}

// Subcomponent for Performance Card
struct PerformanceRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Text(value)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
    }
}
