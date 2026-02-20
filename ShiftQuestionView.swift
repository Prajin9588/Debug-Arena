import SwiftUI

struct ShiftQuestionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentIndex: Int
    
    // Line Evaluation State
    // Key: Line Number (1-based)
    enum LineVerdict {
        case correct
        case incorrectReasoning // Error exists, but user explanation wrong
        case noError // User claimed error on valid line
        case notEvaluated
    }
    
    @State private var lineVerdicts: [Int: LineVerdict] = [:]
    @State private var selectedLine: Int? = nil
    @State private var showReasoningSheet = false
    
    // Evaluation Result State (for Level Completion)
    @State private var evaluationResult: EvaluationResult? = nil
    
    // Feedback Toast State
    @State private var feedbackMessage: String? = nil
    @State private var showFeedback = false
    @State private var feedbackType: FeedbackType = .neutral
    
    enum FeedbackType {
        case success, error, neutral
    }
    
    init(initialIndex: Int) {
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var currentQuestion: Question {
        if gameManager.currentLevel.questions.indices.contains(currentIndex) {
            return gameManager.currentLevel.questions[currentIndex]
        }
        return gameManager.currentLevel.questions[0]
    }
    
    var currentQuestions: [Question] {
        gameManager.currentLevel.questions
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Replacing old HStack with WorkspaceHeader)
                WorkspaceHeader(
                    levelNumber: currentQuestion.levelNumber,
                    questionNumber: currentQuestion.questionNumber,
                    streak: gameManager.streak,
                    coins: gameManager.coinBalance,
                    onBack: { dismiss() }
                )
                
                // Swipeable Code View
                TabView(selection: $currentIndex) {
                    ForEach(0..<currentQuestions.count, id: \.self) { index in
                        ShiftCodeSnippetView(
                            question: currentQuestions[index],
                            lineVerdicts: lineVerdicts,
                            onLineTap: { lineNum in
                                handleLineTap(lineNum: lineNum)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
                .onChange(of: currentIndex) { _, _ in
                    resetStateForNewQuestion()
                }
                
                // Instruction Footer
                VStack(spacing: 4) {
                    Text("DEBUGGER MODE ENABLED")
                        .font(Theme.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.electricCyan)
                    Text("Tap any line to log an error hypothesis.")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.bottom)
            }
            .blur(radius: showReasoningSheet ? 5 : 0)
            
            // Reasoning Sheet Overlay
            if showReasoningSheet, let line = selectedLine {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { closeSheet() }
                
                ReasoningSheet(
                    lineNumber: line,
                    question: currentQuestion,
                    onSubmit: { reasoning in
                        evaluateReasoning(line: line, text: reasoning)
                    },
                    onClose: closeSheet
                )
                .transition(.move(edge: .bottom))
                .zIndex(10)
            }
            
            // Evaluation Result Overlay (Level Completion)
            if let result = evaluationResult {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    EvaluationResultView(result: result, difficulty: currentQuestion.difficulty)
                        .padding()
                        .onTapGesture {
                            // If passed, dismiss or move on
                            if result.status == .correct {
                                dismiss()
                            } else {
                                evaluationResult = nil
                            }
                        }
                }
                .zIndex(20)
            }
            
            // Feedback Toast
            if showFeedback, let msg = feedbackMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            feedbackType == .success ? Theme.Colors.success :
                            feedbackType == .error ? Theme.Colors.error :
                            Theme.Colors.accent
                        )
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(30)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if showFeedback {
                            withAnimation { showFeedback = false }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Ensure state is clean on load
            resetStateForNewQuestion()
        }
    }
    
    // MARK: - Logic
    
    private func resetStateForNewQuestion() {
        lineVerdicts = [:]
        selectedLine = nil
        showReasoningSheet = false
        evaluationResult = nil
        showFeedback = false
    }
    
    private func handleLineTap(lineNum: Int) {
        // Allow re-evaluating lines unless they are already "Correct"
        if lineVerdicts[lineNum] == .correct { return }
        selectedLine = lineNum
        withAnimation {
            showReasoningSheet = true
        }
    }
    
    private func closeSheet() {
        withAnimation {
            showReasoningSheet = false
            selectedLine = nil
        }
    }
    
    private func evaluateReasoning(line: Int, text: String) {
        guard let data = currentQuestion.shiftData else { return }
        
        let isErrorLine = data.errorLines[line] != nil
        var verdict: LineVerdict = .notEvaluated
        var feedbackMsg = ""
        var type: FeedbackType = .neutral
        
        if isErrorLine {
            // It IS an error line. Check user reasoning against options.
            if let detail = data.errorLines[line] {
                // Find matching option
                let (matchedOption, isCorrectOpt) = findMatchingOption(userText: text, options: detail.options)
                
                if let option = matchedOption {
                    if isCorrectOpt {
                        verdict = .correct
                        feedbackMsg = "✅ LOGIC VERIFIED: Correctly identified the error."
                        type = .success
                        
                        // Mark progress in GameManager
                        gameManager.markShiftOptionFound(questionTitle: currentQuestion.title, optionId: option.id)
                        checkCompletion()
                    } else {
                        verdict = .incorrectReasoning
                        feedbackMsg = "❌ INCORRECT REASONING: Error exists, but your explanation matches a misconception."
                        type = .error
                    }
                } else {
                    // Matches nothing - fallback
                    verdict = .incorrectReasoning
                    feedbackMsg = "⚠️ UNCLEAR REASONING: Try using standard technical terms."
                    type = .error
                }
            }
        } else {
            // It is NOT an error line
            verdict = .noError
            feedbackMsg = "⚠️ NO ERROR: This line is valid. Avoid false positives."
            type = .neutral
        }
        
        // Update State
        lineVerdicts[line] = verdict
        closeSheet()
        
        // Trigger Haptic & Feedback
        let impact = UINotificationFeedbackGenerator()
        if type == .success {
            impact.notificationOccurred(.success)
        } else {
            impact.notificationOccurred(.error)
        }
        
        feedbackMessage = feedbackMsg
        feedbackType = type
        withAnimation { showFeedback = true }
    }
    
    private func findMatchingOption(userText: String, options: [ShiftOption]) -> (ShiftOption?, Bool) {
        // Semantic Matching Logic
        let normalizedUser = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check Correct Option First
        if let correct = options.first(where: { $0.isCorrect }) {
            if isMatch(user: normalizedUser, target: correct.text) {
                return (correct, true)
            }
        }
        
        // Check Distractors
        for opt in options where !opt.isCorrect {
            if isMatch(user: normalizedUser, target: opt.text) {
                return (opt, false)
            }
        }
        
        return (nil, false)
    }
    
    private func isMatch(user: String, target: String) -> Bool {
        let normTarget = target.lowercased()
        
        // Direct containment
        if user.contains(normTarget) || normTarget.contains(user) {
            if user.count > 3 { return true }
        }
        
        // Token overlap
        let userTokens = Set(user.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 })
        let targetTokens = Set(normTarget.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 })
        
        let intersection = userTokens.intersection(targetTokens)
        
        if !targetTokens.isEmpty {
            let ratio = Double(intersection.count) / Double(targetTokens.count)
            return ratio >= 0.5
        }
        
        return false
    }
    
    private func checkCompletion() {
        let progress = gameManager.getShiftProgress(for: currentQuestion)
        if progress >= 1.0 {
            // Level Complete
            gameManager.handleShiftCompletion(for: currentQuestion)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.evaluationResult = EvaluationResult(
                    questionID: currentQuestion.id,
                    status: .correct,
                    score: 100,
                    level: .expert,
                    complexity: .medium,
                    edgeCaseHandling: true,
                    hardcodingDetected: false,
                    feedback: "✅ All errors identified and explained correctly."
                )
            }
        }
    }
}

// MARK: - Components

struct ShiftCodeSnippetView: View {
    let question: Question
    let lineVerdicts: [Int: ShiftQuestionView.LineVerdict]
    let onLineTap: (Int) -> Void
    
    var lines: [String] {
        guard let code = question.shiftData?.code else { return ["// No code available"] }
        return code.components(separatedBy: "\n")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let lineNum = index + 1
                    let verdict = lineVerdicts[lineNum]
                    
                    HStack(alignment: .top, spacing: 10) {
                        // Line Number
                        Text("\(lineNum)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                            .frame(width: 30, alignment: .trailing)
                        
                        // Code Content
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(backgroundColor(for: verdict))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(borderColor(for: verdict), lineWidth: 1)
                            )
                        
                        // Status Icon
                        if let v = verdict {
                            statusIcon(for: v)
                        } else {
                            Image(systemName: "hand.tap")
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.3))
                        }
                    }
                    .contentShape(Rectangle()) // Make full row tappable
                    .onTapGesture {
                        onLineTap(lineNum)
                    }
                }
            }
            .padding()
        }
    }
    
    func backgroundColor(for verdict: ShiftQuestionView.LineVerdict?) -> Color {
        guard let v = verdict else { return Color.clear }
        switch v {
        case .correct: return Theme.Colors.success.opacity(0.2)
        case .incorrectReasoning: return Theme.Colors.error.opacity(0.2)
        case .noError: return Theme.Colors.textSecondary.opacity(0.1)
        case .notEvaluated: return Color.clear
        }
    }
    
    func borderColor(for verdict: ShiftQuestionView.LineVerdict?) -> Color {
        guard let v = verdict else { return Color.clear }
        switch v {
        case .correct: return Theme.Colors.success
        case .incorrectReasoning: return Theme.Colors.error
        case .noError: return Theme.Colors.textSecondary
        case .notEvaluated: return Color.clear
        }
    }
    
    func statusIcon(for verdict: ShiftQuestionView.LineVerdict) -> some View {
        switch verdict {
        case .correct:
            return AnyView(Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.Colors.success))
        case .incorrectReasoning:
            return AnyView(Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.Colors.error))
        case .noError:
            return AnyView(Image(systemName: "xmark.circle").foregroundColor(Theme.Colors.textSecondary))
        case .notEvaluated:
            return AnyView(Image(systemName: "circle").foregroundColor(.clear))
        }
    }
}

struct ReasoningSheet: View {
    let lineNumber: Int
    let question: Question
    let onSubmit: (String) -> Void
    let onClose: () -> Void
    
    @State private var reasoningText: String = ""
    @FocusState private var isFocused: Bool
    
    var isErrorLine: Bool {
        question.shiftData?.errorLines[lineNumber] != nil
    }
    
    var hints: [String] {
        guard isErrorLine, let detail = question.shiftData?.errorLines[lineNumber] else { return [] }
        return detail.options.map { $0.text }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("LINE \(lineNumber) INVESTIGATION")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.electricCyan)
                        .tracking(1)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(isErrorLine ? "Why did you choose this line as the error?" : "Why do you think this line is incorrect?")
                    .font(Theme.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Hints (Only for actual errors)
                if isErrorLine {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THINKING SUPPORT (Reference Concepts)")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        ForEach(hints, id: \.self) { hint in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.gold)
                                Text(hint)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Input Area
                VStack(alignment: .leading) {
                    Text("YOUR REASONING")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    TextEditor(text: $reasoningText)
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.electricCyan.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .focused($isFocused)
                }
                
                Button(action: {
                    if !reasoningText.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSubmit(reasoningText)
                    }
                }) {
                    Text("VERIFY HYPOTHESIS")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.electricCyan)
                        .cornerRadius(12)
                }
                .disabled(reasoningText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(reasoningText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                
            }
            .padding(30)
            .background(BlurView(style: .systemThinMaterialDark))
            .cornerRadius(30)
            .padding(.bottom, 20)
        }
        .onAppear {
            isFocused = true
        }
    }
}
