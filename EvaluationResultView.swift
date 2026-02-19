import SwiftUI

struct EvaluationResultView: View {
    let result: EvaluationResult
    var difficulty: Int? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        renderDetailedEvaluation()
            .padding(.vertical)
            .background(Theme.Colors.background)
            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Level 2 Detailed Evaluation
    private func renderDetailedEvaluation() -> some View {
        VStack(spacing: 24) {
            // 1. Header Section
            HStack {
                Text("EVALUATION RESULT")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(2)
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Image(systemName: result.status == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(result.status.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (result.status == .correct ? Theme.Colors.success : Theme.Colors.error)
                        .opacity(0.1)
                )
                .foregroundColor(result.status == .correct ? Theme.Colors.success : Theme.Colors.error)
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 2. Score Card Section
            VStack(spacing: 20) {
                HStack(spacing: 25) {
                    // Circular Progress Arc
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.secondaryBackground.opacity(0.5), lineWidth: 10)
                            .frame(width: 90, height: 90)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(result.score) / 100.0)
                            .stroke(
                                result.status == .correct ? Theme.Colors.success : Theme.Colors.error,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0), value: result.score)
                        
                        Text("\(result.score)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.status == .correct ? "PASSED" : "FAILED")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(result.status == .correct ? Theme.Colors.success : Theme.Colors.error)
                        
                        Text("Complexity: \(result.complexity.rawValue)")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(20)
            .shadow(color: Theme.Layout.cardShadow, radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            
            // 3. Feedback Section
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("FEEDBACK")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .tracking(2)
                    Spacer()
                    
                    let passedCount = result.testResults.filter { $0.passed }.count
                    Text("Passed \(passedCount)/\(result.testResults.count) tests")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(result.testResults.indices, id: \.self) { index in
                        let test = result.testResults[index]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: test.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(test.passed ? Theme.Colors.success : Theme.Colors.error)
                                Text("Test \(index + 1) \(test.passed ? "Passed" : "Failed")")
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                feedbackRow(label: "Input", value: test.input)
                                feedbackRow(label: "Expected", value: test.expected)
                                feedbackRow(label: "Actual", value: test.actual, color: test.passed ? Theme.Colors.textSecondary : Theme.Colors.error)
                            }
                            .padding(.leading, 28)
                        }
                        .padding()
                        .background(Theme.Colors.secondaryBackground.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(test.passed ? Theme.Colors.success.opacity(0.2) : Theme.Colors.error.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Inline Rewards
            if result.status == .correct {
                HStack(spacing: 20) {
                    rewardItem(icon: AnyView(BugCoin(size: 16)), label: "+\(result.coinsEarned) Coin")
                    rewardItem(icon: AnyView(Text("⚡️").font(.system(size: 14))), label: "+\(result.xpEarned) XP")
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.success.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    
    // MARK: - Subcomponents
    private func feedbackRow(label: String, value: String, color: Color = Theme.Colors.textSecondary) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 70, alignment: .leading)
            
            Text(value)
                .font(Theme.Typography.codeFont)
                .font(.system(size: 13))
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func rewardItem(icon: AnyView, label: String) -> some View {
        HStack(spacing: 6) {
            icon
            Text(label)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.success)
        }
    }
}
