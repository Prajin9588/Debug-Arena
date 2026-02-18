import SwiftUI

struct CompilerConsoleView: View {
    @ObservedObject var gameManager: GameManager
    
    @State private var consoleOutput: [String] = []
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("EVALUATION RESULT")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(1)
                Spacer()
                
                if gameManager.executionState == .running {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("ANALYZING...")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.action)
                    }
                } else if case .correct = gameManager.executionState {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.success)
                        Text("PASSED")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.success)
                            .bold()
                    }
                } else if case .error = gameManager.executionState {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.Colors.error)
                        Text("FAILED")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.error)
                            .bold()
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            
            Divider()
            
            // Console/Result Area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Detailed Evaluation Report
                    if let result = gameManager.lastEvaluationResult, !gameManager.executionState.isIdle && gameManager.executionState != .running {
                        
                        // Score & Status Card
                        HStack(alignment: .center, spacing: 16) {
                            // Score Chart
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 6)
                                    .frame(width: 60, height: 60)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(result.score) / 100.0)
                                    .stroke(
                                        colorForLevel(result.level),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                    )
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(result.score)")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.level.rawValue.uppercased())
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(colorForLevel(result.level))
                                
                                Text("Complexity: \(result.complexity.rawValue)")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                if result.hardcodingDetected {
                                    Text("⚠️ Hardcoding Detected")
                                        .font(Theme.Typography.caption2)
                                        .foregroundColor(Theme.Colors.warning)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.background)
                        .cornerRadius(12)
                        
                        // Feedback Section
                        if !result.feedback.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FEEDBACK")
                                    .font(Theme.Typography.caption2)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Text(result.feedback)
                                    .font(Theme.Typography.subheadline) // Cleaner font
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.Colors.codeBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    } else {
                        // Standard Logs (e.g. compiling...)
                        ForEach(consoleOutput, id: \.self) { line in
                            Text(line)
                                .font(Theme.Typography.terminalCodeFont)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 250)
        }
        .background(Color.white)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .onChange(of: gameManager.executionState) { _, newState in
            handleStateChange(newState)
        }
    }
    
    // MARK: - Logic
    
    private var borderColor: Color {
        switch gameManager.executionState {
        case .correct: return Theme.Colors.success
        case .error: return Theme.Colors.error
        case .running: return Theme.Colors.accent
        default: return Color.gray.opacity(0.3)
        }
    }
    
    private func colorForLine(_ line: String) -> Color {
        if line.contains("❌") || line.contains("Error") || line.contains("Failed") {
            return Theme.Colors.error
        } else if line.contains("✅") || line.contains("Success") {
            return Theme.Colors.success
        } else if line.contains("Running") || line.contains("Compiling") || line.contains("Linking") {
            return Theme.Colors.electricCyan
        } else if line.contains("⚠️") {
            return .orange
        }
        return Theme.Colors.textPrimary
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
    
    private func handleStateChange(_ state: GameManager.ExecutionState) {
        switch state {
        case .running:
            consoleOutput = []
            isAnimating = true
            simulateBuildProcess()
            
        case .correct:
            isAnimating = false
            if !consoleOutput.contains(where: { $0.contains("Success") }) {
                consoleOutput.append("✅ Build Succeeded. Analysis Complete.")
            }
            
        case .error:
            isAnimating = false
            if !consoleOutput.contains(where: { $0.contains("Failed") }) {
                consoleOutput.append("❌ Build Failed. Analysis Complete.")
            }
            // Message is in the detailed report, but we can add a summary here if needed
            
        case .idle:
            consoleOutput = ["Waiting for input..."]
            
        case .levelComplete(_, _):
             consoleOutput.append("🎉 Level Complete!")
        }
    }
    
    private func simulateBuildProcess() {
        let steps = [
            "Compiling sources...",
            "Linking objects...",
            "Running strict evaluation engine...",
            "Analyzing complexity...",
            "Scoring logic..."
        ]
        
        var delay = 0.0
        for step in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if gameManager.executionState == .running {
                    consoleOutput.append(step)
                }
            }
            delay += 0.25
        }
    }
}
