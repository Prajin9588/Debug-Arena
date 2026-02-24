import SwiftUI

struct ShiftQuestionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentIndex: Int
    
    // Line Evaluation State
    // Key: Line Number (1-based)
    enum LineVerdict {
        case correct         // All categories found, reasoning good
        case weakReasoning   // Categories correct, but explanation is vague
        case wrongCategory   // Selected incorrect categories
        case noError         // Line is actually valid
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
    @State private var hasTriggeredAppearAnimation = false
    
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
                
                // Expected Output Section
                if let output = displayOutput {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXPECTED OUTPUT")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.leading)
                        
                        Text(output)
                            .font(Theme.Typography.codeFont)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.babyPowder)
                            .cornerRadius(Theme.Layout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
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
                    onSubmit: { reasoning, selectedOptions in
                        evaluateReasoning(line: line, text: reasoning, selectedOptions: selectedOptions)
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
            
            if !hasTriggeredAppearAnimation {
                gameManager.triggerScatter()
                hasTriggeredAppearAnimation = true
            }
        }
    }
    
    // MARK: - Logic
    
    private var displayOutput: String? {
        if let firstTest = currentQuestion.hiddenTests?.first, !firstTest.expectedOutput.isEmpty {
            return firstTest.expectedOutput
        }
        return nil
    }

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
    
    private func evaluateReasoning(line: Int, text: String, selectedOptions: [ShiftOption]) {
        guard let data = currentQuestion.shiftData else { return }
        
        let isErrorLine = data.errorLines[line] != nil
        var verdict: LineVerdict = .notEvaluated
        var feedbackMsg = ""
        var type: FeedbackType = .neutral
        
        if isErrorLine {
            // It IS an error line.
            if let detail = data.errorLines[line], !selectedOptions.isEmpty {
                // Check if any distractors were selected
                let hasIncorrect = selectedOptions.contains(where: { !$0.isCorrect })
                
                // Get all correct options for this line
                let correctOptions = detail.options.filter { $0.isCorrect }
                let allCorrectFound = correctOptions.allSatisfy { correctOpt in
                    selectedOptions.contains(where: { $0.id == correctOpt.id })
                }
                
                if hasIncorrect {
                    verdict = .wrongCategory
                    feedbackMsg = "❌ MISCLASSIFIED: One or more selected categories do not apply to this bug."
                    type = .error
                } else if !allCorrectFound {
                    verdict = .notEvaluated
                    feedbackMsg = "⚠️ INCOMPLETE: You identified some issues, but there are more applicable concepts on this line."
                    type = .neutral
                } else {
                    // CATERGORIES ARE 100% CORRECT (Selected all of them, no distractors)
                    // This is enough to PASS the line investigation in Level 3/4 (80% weight)
                    let isWeightedLevel = currentQuestion.difficulty >= 3
                    
                    let normalizedText = text.lowercased()
                    // Check for semantic match or keywords for EACH correct option
                    let matchResults = correctOptions.map { opt -> Bool in
                        let keywords = opt.text.lowercased().components(separatedBy: " ")
                        return keywords.allSatisfy { normalizedText.contains($0) } || 
                               isMatch(user: normalizedText, target: opt.text) ||
                               isMatch(user: normalizedText, target: opt.explanation)
                    }
                    
                    let allMatched = matchResults.allSatisfy { $0 }
                    
                    if isWeightedLevel {
                        // Mark as correct immediately because categories are correct
                        verdict = allMatched ? .correct : .weakReasoning
                        type = .success
                        
                        let combinedExplanations = selectedOptions.map { "• \($0.explanation)" }.joined(separator: "\n\n")
                        
                        if allMatched {
                            feedbackMsg = "✨ PERFECT: Line Clear!\nExcellent reasoning and classification.\n\n\(combinedExplanations)"
                        } else {
                            feedbackMsg = "✅ LINE CLEAR (80%)\nBug identified correctly! Try using more technical terms like '\(correctOptions.first?.text ?? "")' next time.\n\n\(combinedExplanations)"
                        }
                        
                        // Register options as found to progress the question
                        for opt in selectedOptions {
                            gameManager.markShiftOptionFound(questionTitle: currentQuestion.title, optionId: opt.id)
                        }
                        checkCompletion()
                    } else {
                        // Level 1-2: Strict check
                        if allMatched {
                            verdict = .correct
                            type = .success
                            let combinedExplanations = selectedOptions.map { "• \($0.explanation)" }.joined(separator: "\n\n")
                            feedbackMsg = "✅ VERIFIED\n\n\(combinedExplanations)"
                            for opt in selectedOptions {
                                gameManager.markShiftOptionFound(questionTitle: currentQuestion.title, optionId: opt.id)
                            }
                            checkCompletion()
                        } else {
                            verdict = .weakReasoning
                            feedbackMsg = "⚠️ WEAK REASONING: Please explain the concepts more clearly in your own words."
                            type = .error
                        }
                    }
                }
            } else {
                verdict = .wrongCategory
                feedbackMsg = "⚠️ INCOMPLETE: Please select all applicable reference concepts."
                type = .error
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
        let userLow = user.lowercased()
        let targetLow = target.lowercased()
        
        // Define Synonyms for Core Concepts
        let synonyms: [String: [String]] = [
            "calculation": ["math", "result", "computed", "sum", "value", "multiplied", "arithmetic", "computed", "eval"],
            "reference": ["copy", "pointer", "address", "struct", "class", "memory", "original", "ref", "alloc"],
            "logic": ["check", "missing", "condition", "edge-case", "skip", "mistake", "flaw", "flow", "branch"],
            "trap": ["side-effect", "mutation", "changed", "global", "state", "modified", "broken"]
        ]
        
        // Check for direct keywords or synonyms
        for word in targetLow.components(separatedBy: .whitespaces) {
            if word.count < 3 { continue }
            if userLow.contains(word) { return true }
            
            // Check synonyms if any
            for (key, list) in synonyms {
                if word.contains(key) {
                    if list.contains(where: { userLow.contains($0) }) {
                        return true
                    }
                }
            }
        }
        
        // 1. String similarity check (Levenshtein-ish)
        let userTokens = Set(userLow.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 })
        let targetTokens = Set(targetLow.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 })
        
        let intersection = userTokens.intersection(targetTokens)
        if !targetTokens.isEmpty {
            let ratio = Double(intersection.count) / Double(targetTokens.count)
            if ratio >= 0.4 { return true }
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
        case .weakReasoning: return Color.yellow.opacity(0.2)
        case .wrongCategory: return Theme.Colors.error.opacity(0.2)
        case .noError: return Theme.Colors.textSecondary.opacity(0.1)
        case .notEvaluated: return Color.clear
        }
    }
    
    func borderColor(for verdict: ShiftQuestionView.LineVerdict?) -> Color {
        guard let v = verdict else { return Color.clear }
        switch v {
        case .correct: return Theme.Colors.success
        case .weakReasoning: return Color.yellow
        case .wrongCategory: return Theme.Colors.error
        case .noError: return Theme.Colors.textSecondary
        case .notEvaluated: return Color.clear
        }
    }
    
    func statusIcon(for verdict: ShiftQuestionView.LineVerdict) -> some View {
        switch verdict {
        case .correct:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.success)
        case .weakReasoning:
            return Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.yellow)
        case .wrongCategory:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(Theme.Colors.error)
        case .noError:
            return Image(systemName: "info.circle")
                .foregroundColor(Theme.Colors.textSecondary)
        case .notEvaluated:
            return Image(systemName: "hand.tap")
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.3))
        }
    }
    }


struct ReasoningSheet: View {
    let lineNumber: Int
    let question: Question
    let onSubmit: (String, [ShiftOption]) -> Void
    let onClose: () -> Void
    
    @State private var reasoningText: String = ""
    @State private var selectedOptionIds: Set<UUID> = []
    @FocusState private var isFocused: Bool
    
    var isErrorLine: Bool {
        question.shiftData?.errorLines[lineNumber] != nil
    }
    
    // The specific concepts requested by the user
    let referenceConcepts = [
        "Wrong calculation",
        "Value vs Reference",
        "Logic oversight",
        "Side-effect trap"
    ]
    
    var availableOptions: [ShiftOption] {
        if let detail = question.shiftData?.errorLines[lineNumber] {
            return detail.options
        }
        return referenceConcepts.map { ShiftOption(text: $0, explanation: "", isCorrect: false) }
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
                
                Text("Analyze this line and select ALL concepts that apply.")
                    .font(Theme.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Reasoning Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR REASONING (Explain each selected concept)")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    TextEditor(text: $reasoningText)
                        .frame(height: 100)
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
                
                // Concept Selection (Multiple interactive options)
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT HYPOTHESIS CATEGORIES (Multi-Select)")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableOptions, id: \.id) { option in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        if selectedOptionIds.contains(option.id) {
                                            selectedOptionIds.remove(option.id)
                                        } else {
                                            selectedOptionIds.insert(option.id)
                                        }
                                    }
                                }) {
                                    let isSelected = selectedOptionIds.contains(option.id)
                                    HStack {
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                        Text(option.text)
                                    }
                                    .font(Theme.Typography.caption)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(isSelected ? Theme.Colors.electricCyan : Color.white.opacity(0.05))
                                    .foregroundColor(isSelected ? .black : .white)
                                    .cornerRadius(20)
                                    .overlay(
                                        Capsule()
                                            .stroke(Theme.Colors.electricCyan.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    if canSubmit {
                        let selected = availableOptions.filter { selectedOptionIds.contains($0.id) }
                        onSubmit(reasoningText, selected)
                    }
                }) {
                    Text("VERIFY HYPOTHESIS")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Theme.Colors.electricCyan : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canSubmit)
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
    
    private var canSubmit: Bool {
        !reasoningText.trimmingCharacters(in: .whitespaces).isEmpty && !selectedOptionIds.isEmpty
    }
}
