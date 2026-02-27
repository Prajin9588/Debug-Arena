import SwiftUI

struct EvaluationResultView: View {
    let result: EvaluationResult
    var difficulty: Int? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        renderDetailedEvaluation()
            .padding(.vertical, 24)
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
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (result.status == .correct ? Theme.Colors.softGreen : Theme.Colors.mutedRed)
                        .opacity(0.12)
                )
                .foregroundColor(result.status == .correct ? Theme.Colors.softGreen : Theme.Colors.mutedRed)
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 2. Score & Feedback Summary
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // Circular Progress (Subtler)
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.secondaryBackground.opacity(0.8), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(result.score) / 100.0)
                            .stroke(
                                result.status == .correct ? Theme.Colors.softGreen : Theme.Colors.mutedRed,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(result.score)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.status == .correct ? "PASSED" : "FAILED")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(result.status == .correct ? Theme.Colors.softGreen : Theme.Colors.mutedRed)
                        
                        Text("Complexity: \(result.complexity.rawValue)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
                
                if result.status == .incorrect {
                    compilerErrorMessage
                }
                
                adaptiveExplanationBlock
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 12)
            
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
                                if !test.input.isEmpty && test.input != "Main execution" {
                                    feedbackRow(label: "Input", value: test.input)
                                }
                                if !test.expected.isEmpty {
                                    feedbackRow(label: "Expected", value: test.expected)
                                }
                                if !test.actual.isEmpty {
                                    feedbackRow(label: "Actual", value: test.actual, color: test.passed ? Theme.Colors.textSecondary : Theme.Colors.error)
                                }
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
                    rewardItem(icon: AnyView(Text("⚡️").font(.system(size: 14))), label: "+\(result.xpEarned) XP")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.success.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 12)
            }
        }
    }
    
    
    // MARK: - Subcomponents
    
    private var compilerErrorMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Error:")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.mutedRed)
                .bold()
            
            let messageParts = result.feedback.components(separatedBy: ":")
            let errorType = messageParts.count > 1 ? messageParts[0].trimmingCharacters(in: .whitespaces) : "Execution Error"
            let errorDetail = messageParts.count > 1 ? messageParts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces) : result.feedback
            
            Text("\(errorType): \(errorDetail)")
                .font(Theme.Typography.codeFont)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.background.opacity(Theme.isDarkMode ? 0.3 : 0.05))
                .cornerRadius(8)
        }
        .padding(.top, 4)
    }
    
    private var adaptiveExplanationBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if result.status == .correct {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.Colors.softGreen)
                    Text(reinforcementMessage)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, 4)
            } else {
                HStack {
                    Text("🔍 Understanding the Error")
                        .font(Theme.Typography.headline)
                        .font(.system(size: 15))
                    Spacer()
                }
                
                Text(failureExplanation)
                    .font(Theme.Typography.body)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineSpacing(4)
                
                Text("Suggested check: Review the variable scopes and type declarations.")
                    .font(Theme.Typography.caption)
                    .italic()
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.8))
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(result.status == .correct ? Theme.Colors.success.opacity(0.05) : Theme.Colors.mutedRed.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var reinforcementMessage: String {
        let options = [
            "You correctly identified the core logical flaw.",
            "Great job navigating the type system constraints.",
            "All tests passed successfully.",
            "Your implementation handles the edge cases perfectly.",
            "Excellent understanding of the memory model used here."
        ]
        return options[Int(result.questionID.uuidString.first?.asciiValue ?? 0) % options.count]
    }
    
    private var failureExplanation: String {
        if let category = result.userSelectedCategory {
            let catLower = category.lowercased()
            if catLower.contains("type") {
                return "This mismatch happens because the type system expects values to be strictly compatible. You selected a type that doesn't align with the variables declared in the code, causing a conflict in assignment or function calls."
            } else if catLower.contains("pointer") || catLower.contains("reference") {
                return "The issue lies in how memory is referenced. You're attempting to access data through a pointer that isn't pointing to the correct address or type, leading to an invalid memory read."
            } else if catLower.contains("logic") || catLower.contains("condition") {
                return "The logical evaluation order or the condition itself is flawed. The branch you selected doesn't actually handle the input values according to the mission requirements."
            } else if catLower.contains("boundary") || catLower.contains("index") {
                return "This is likely a boundary logic error (Off-by-one). The current index access or loop range goes beyond the allocated space of the structure."
            } else if catLower.contains("null") || catLower.contains("safety") {
                return "Safety checks were bypassed here. Accessing a value that hasn't been initialized or is explicitly nil/null leads to a crash in this environment."
            }
        }
        
        return "The current implementation encountered a logical roadblock. The specific choice you made doesn't resolve the underlying issue in the code execution flow. Re-examine the code structure and the riddle for clues."
    }

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
                .foregroundColor(Theme.Colors.softGreen)
        }
    }
}
