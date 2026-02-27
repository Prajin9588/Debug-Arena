import SwiftUI

struct ShiftQuestionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
    
    private var isAdvanced: Bool {
        currentQuestion.difficulty >= 3 && (currentQuestion.language == .swift || currentQuestion.language == .c)
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Replacing old HStack with WorkspaceHeader)
                WorkspaceHeader(
                    levelNumber: currentQuestion.levelNumber,
                    questionNumber: currentQuestion.questionNumber,
                    streak: gameManager.currentStreak,
                    onBack: { dismiss() }
                )
                
                // Debugger Mode Banner
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.caption2)
                        Text("DEBUGGER MODE ENABLED")
                            .font(Theme.Typography.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.codeBackground)
                    
                    Divider()
                        .background(Theme.Colors.textSecondary.opacity(0.1))
                }
                
                // Swipeable Code View
                TabView(selection: $currentIndex) {
                    ForEach(0..<currentQuestions.count, id: \.self) { index in
                        ShiftCodeSnippetView(
                            question: currentQuestions[index],
                            isAdvanced: isAdvanced,
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
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(Theme.Layout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                                    .stroke(Theme.isDarkMode ? Color.white.opacity(0.12) : Color(hex: "E5E5E5"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(Theme.isDarkMode ? 0.4 : 0.08), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
            .frame(maxWidth: .infinity)
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
                .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
            
            // Evaluation Result Overlay (Level Completion)
            if let result = evaluationResult {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 20) {
                            EvaluationResultView(result: result, difficulty: currentQuestion.difficulty)
                            
                            if result.status == .correct {
                                Button(action: { dismiss() }) {
                                    HStack {
                                        Image(systemName: "terminal.fill")
                                        Text("COMMIT FIX")
                                    }
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.primaryGradient)
                                    .cornerRadius(12)
                                }
                            } else {
                                Button(action: { evaluationResult = nil }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                        Text("TRY AGAIN")
                                    }
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.failureGradient)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(horizontalSizeClass == .regular ? 40 : 20)
                        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                        .padding(.horizontal)
                        .padding(.vertical, 40)
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
            resetStateForNewQuestion()
            if !hasTriggeredAppearAnimation {
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
        
        let isAdvancedLevel = currentQuestion.difficulty >= 3
        let isSwiftOrC = currentQuestion.language == .swift || currentQuestion.language == .c
        
        var overrideMessage: String? = nil
        if isAdvancedLevel && isSwiftOrC {
            let validation = validateReasoningIntent(text: text, question: currentQuestion)
            if !validation.isValid {
                feedbackMessage = "🔍 \(validation.message)"
                feedbackType = .error
                withAnimation { showFeedback = true }
                return
            }
            if validation.isOverride {
                overrideMessage = "🔍 \(validation.message)"
            }
        }

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
                    
                    let normalizedText = text.lowercased()
                    // Check for semantic match or keywords for EACH correct option
                    let matchResults = correctOptions.map { opt -> Bool in
                        let keywords = opt.text.lowercased().components(separatedBy: " ")
                        return keywords.allSatisfy { normalizedText.contains($0) } || 
                               isMatch(user: normalizedText, target: opt.text) ||
                               isMatch(user: normalizedText, target: opt.explanation)
                    }
                    
                    let allMatched = matchResults.allSatisfy { $0 }
                    
                if isAdvancedLevel {
                    // Advanced Levels: Correct Line + Correct Categories = Pass (80%)
                    if allMatched {
                        verdict = .correct
                        feedbackMsg = overrideMessage != nil ? "🔍 Reasoning accepted for investigation." : "✨ PERFECT: Line Clear!"
                    } else {
                        verdict = .weakReasoning
                        feedbackMsg = "🔍 An issue exists, but the explanation does not match the behavior."
                    }
                    type = .success
                    
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
                            feedbackMsg = "✅ VERIFIED"
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
            feedbackMsg = "🔍 No error occurs on this line."
            type = .error
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
    
    private func validateReasoningIntent(text: String, question: Question) -> (isValid: Bool, message: String, isOverride: Bool) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Reasoning Must Exist
        if normalized.isEmpty {
            return (false, "Reasoning cannot be empty.", false)
        }
        
        // 2. Meaningful sentenceish (Blabbering Check)
        if normalized.components(separatedBy: .whitespaces).count < 2 || normalized.count < 5 {
            return (false, "Please explain the behavior or issue observed on this line.", false)
        }
        
        let isAdvanced = question.difficulty >= 3
        let isSwiftOrC = question.language == .swift || question.language == .c
        let hasError = normalized.contains("error")
        
        // 3. SPECIAL OVERRIDE RULE (Swift & C — Level 3 & 4 ONLY)
        if isAdvanced && isSwiftOrC && hasError {
            return (true, "Reasoning accepted for investigation.", true)
        }
        
        // 4. Intent Indicators
        let causeEffect = ["because", "due to", "leads to", "results in", "causes"]
        let behavior = ["execution", "runtime", "compile", "assign", "compare", "mutate"]
        let technical = ["variable", "value", "reference", "function", "memory", "condition", "loop", "output"]
        
        let allIndicators = causeEffect + behavior + technical
        let hasIntent = allIndicators.contains { normalized.contains($0) }
        
        if hasIntent {
            return (true, "Reasoning accepted.", false)
        } else {
            return (false, "Reasoning lacks technical intent.", false)
        }
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
                    feedback: "✅ All logical errors identified.",
                    testResults: [
                        TestCaseResult(input: "(Standard Execution)", expected: currentQuestion.hiddenTests?.first?.expectedOutput ?? "Resolved", actual: currentQuestion.hiddenTests?.first?.expectedOutput ?? "Resolved", passed: true)
                    ],
                    xpEarned: 10
                )
            }
        }
    }
}
// MARK: - Components

struct ShiftCodeSnippetView: View {
    let question: Question
    let isAdvanced: Bool
    let lineVerdicts: [Int: ShiftQuestionView.LineVerdict]
    let onLineTap: (Int) -> Void
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
                    
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        // 1. Line Number Column - Fixed width, high contrast, matched font
                        Text("\(lineNum)")
                            .font(Theme.Typography.codeFont)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 45, alignment: .trailing)
                            .padding(.vertical, 6) // Match code content padding
                        
                        // 2. Flexible Code Content Column - Matched font
                        Text(line)
                            .font(Theme.Typography.codeFont)
                            .foregroundColor(line.trimmingCharacters(in: .whitespaces).hasPrefix("//") ? Color(hex: "6B7280") : Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(backgroundColor(for: verdict))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(borderColor(for: verdict), lineWidth: 1)
                            )
                        
                        // 3. Status Icon Column
                        ZStack {
                            if let v = verdict {
                                statusIcon(for: v)
                            } else {
                                Image(systemName: "hand.tap")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                        .frame(width: 24)
                    }
                    .contentShape(Rectangle()) // Make full row tappable
                    .onTapGesture {
                        onLineTap(lineNum)
                    }
                }
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(isAdvanced ? 0.4 : 0.08), radius: Theme.isDarkMode ? 20 : 8)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(Theme.isDarkMode ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
            )
            .padding()
        }
    }
    
    func backgroundColor(for verdict: ShiftQuestionView.LineVerdict?) -> Color {
        guard let v = verdict else { return Color.clear }
        let opacity = Theme.isDarkMode ? 0.25 : 0.15
        switch v {
        case .correct: return Theme.Colors.success.opacity(opacity)
        case .weakReasoning: return Color.yellow.opacity(opacity)
        case .wrongCategory: return Theme.Colors.error.opacity(opacity)
        case .noError: return Theme.Colors.textSecondary.opacity(0.1)
        case .notEvaluated: return Color.clear
        }
    }
    
    func borderColor(for verdict: ShiftQuestionView.LineVerdict?) -> Color {
        guard let v = verdict else { return Color.clear }
        let opacity = Theme.isDarkMode ? 0.6 : 1.0
        switch v {
        case .correct: return Theme.Colors.success.opacity(opacity)
        case .weakReasoning: return Color.yellow.opacity(opacity)
        case .wrongCategory: return Theme.Colors.error.opacity(opacity)
        case .noError: return Theme.Colors.textSecondary.opacity(opacity)
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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
            
            VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 30 : 20) {
                // Header
                HStack {
                    Text("LINE \(lineNumber) INVESTIGATION")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.electricCyan)
                        .tracking(1)
                    Spacer()
                    if isAdvancedFlow && isReasoningUnlocked {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(Theme.Colors.success)
                            .font(.caption)
                    }
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                
                Text("Defend your decision, Debugger.")
                    .font(Theme.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                // Reasoning Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR REASONING (Explain each selected concept)")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    TextEditor(text: $reasoningText)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .background(Theme.isDarkMode ? Theme.Colors.background : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.electricCyan.opacity(Theme.isDarkMode ? 0.3 : 0.5), lineWidth: 1.5)
                        )
                        .foregroundColor(Theme.Colors.textPrimary)
                        .focused($isFocused)
                }
                
                // Concept Selection (Multiple interactive options)
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT HYPOTHESIS CATEGORIES (Multi-Select)")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(lockCategories ? Theme.Colors.textSecondary.opacity(0.3) : Theme.Colors.textSecondary)
                    
                    if lockCategories {
                        Text("Explain in at least 13 words to unlock hypothesis categories.")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.electricCyan.opacity(0.8))
                            .padding(.bottom, 2)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableOptions, id: \.id) { option in
                                Button(action: {
                                    if !lockCategories {
                                        withAnimation(.spring()) {
                                            if selectedOptionIds.contains(option.id) {
                                                selectedOptionIds.remove(option.id)
                                            } else {
                                                selectedOptionIds.insert(option.id)
                                            }
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
                                    .background(isSelected ? Theme.Colors.electricCyan : (Theme.isDarkMode ? Theme.Colors.background : Color.white))
                                    .foregroundColor(isSelected ? .black : (lockCategories ? Theme.Colors.textSecondary.opacity(0.3) : Theme.Colors.textPrimary))
                                    .cornerRadius(20)
                                    .opacity(lockCategories ? 0.4 : 1.0)
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Theme.Colors.electricCyan : Theme.Colors.electricCyan.opacity(lockCategories ? 0.1 : 0.4), lineWidth: 1.5)
                                    )
                                }
                                .disabled(lockCategories)
                            }
                        }
                    }
                    .grayscale(lockCategories ? 1.0 : 0.0)
                }
                
                Button(action: {
                    if canSubmit {
                        let selected = availableOptions.filter { selectedOptionIds.contains($0.id) }
                        onSubmit(reasoningText, selected)
                    }
                }) {
                    Text(buttonLabel)
                        .font(Theme.Typography.headline)
                        .foregroundColor(canSubmit ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Theme.Colors.electricCyan : Theme.Colors.textSecondary.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(!canSubmit)
            }
            .padding(horizontalSizeClass == .regular ? 50 : 30)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Theme.isDarkMode ? Color.white.opacity(0.15) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(Theme.isDarkMode ? 0.5 : 0.15), radius: 30, x: 0, y: 15)
            .padding(horizontalSizeClass == .regular ? 40 : 20)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private var canSubmit: Bool {
        if isAdvancedFlow {
            return isReasoningUnlocked && !selectedOptionIds.isEmpty
        }
        return !reasoningText.trimmingCharacters(in: .whitespaces).isEmpty && !selectedOptionIds.isEmpty
    }
    
    private var isAdvancedFlow: Bool {
        question.difficulty >= 3 && (question.language == .swift || question.language == .c)
    }
    
    private var lockCategories: Bool {
        isAdvancedFlow && !isReasoningUnlocked
    }
    
    private var isReasoningUnlocked: Bool {
        let normalized = reasoningText.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = normalized.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.count >= 13
    }
    
    private var buttonLabel: String {
        if isAdvancedFlow && !isReasoningUnlocked {
            return "EXPLAIN BEFORE INVESTIGATING"
        }
        return "VERIFY HYPOTHESIS"
    }
}
