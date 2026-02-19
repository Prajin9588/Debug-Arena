import SwiftUI

struct ShiftQuestionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentIndex: Int
    
    // Selection State
    @State private var selectedLineInfo: (questionIndex: Int, lineNumber: Int)? = nil
    @State private var showOptions = false
    
    // Analysis/Notes State
    @State private var showThoughtPad = false
    @State private var currentThought = ""
    @State private var editingContext: (line: Int, optionText: String)? = nil
    
    // Evaluation Result State
    @State private var evaluationResult: EvaluationResult? = nil
    
    // Explanation State
    @State private var showExplanation = false
    @State private var activeExplanation: String = ""
    
    init(initialIndex: Int) {
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var currentQuestions: [Question] {
        gameManager.currentLevel.questions
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(Theme.Colors.accent)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    
                    Text("LEVEL \(currentQuestions[currentIndex].levelNumber) : Question \(currentQuestions[currentIndex].questionNumber)")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1)/\(currentQuestions.count)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding()
                
                // Swipeable Code View
                TabView(selection: $currentIndex) {
                    ForEach(0..<currentQuestions.count, id: \.self) { index in
                        ShiftCodeSnippetView(
                            question: currentQuestions[index],
                            onLineTap: { lineNum in
                                handleLineTap(questionIndex: index, lineNum: lineNum)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
                .onChange(of: currentIndex) { _, _ in
                    // architecture change: Reset state on swipe
                    evaluationResult = nil
                    selectedLineInfo = nil
                    showOptions = false
                }
                
                // Instruction Footer
                Text("Swipe to navigate • Tap flagged lines to inspect")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.bottom)
            }
            .blur(radius: showOptions ? 5 : 0)
            
            // Options Modal
            if showOptions, let info = selectedLineInfo, let detail = getLineDetail(info) {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { closeOptions() }
                
                VStack {
                    Spacer()
                    ShiftOptionsSheet(
                        detail: detail,
                        currentQuestion: currentQuestions[currentIndex],
                        onExplanation: { option in
                            activeExplanation = option.explanation
                            showExplanation = true
                        },
                        onThought: { option in
                            editingContext = (detail.lineNumber, option.text)
                            currentThought = gameManager.getThought(
                                questionTitle: currentQuestions[currentIndex].title,
                                lineNum: detail.lineNumber,
                                optionText: option.text
                            )
                            showThoughtPad = true
                        },
                        onEvaluate: { result in
                            // Close options sheet first
                            closeOptions()
                            // Show result after small delay to allow transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                evaluationResult = result
                            }
                        },
                        onComplete: {
                            dismiss()
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                .zIndex(10)
            }
            
            // Explanation Modal
            if showExplanation {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { showExplanation = false }
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(Theme.Colors.accent)
                        Text("INSIGHT")
                            .font(Theme.Typography.subheadline)
                            .tracking(2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text(activeExplanation)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                        
                        Button("GOT IT") {
                            showExplanation = false
                        }
                        .font(Theme.Typography.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.accent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .padding(30)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding()
                }
                .zIndex(20)
            }
            
            if showThoughtPad {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture {
                     if let context = editingContext {
                        gameManager.saveThought(
                            questionTitle: currentQuestions[currentIndex].title,
                            lineNum: context.line,
                            optionText: context.optionText,
                            thought: currentThought
                        )
                     }
                     showThoughtPad = false
                }
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(Theme.Colors.textSecondary)
                            Text("MY THOUGHTS")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            Spacer()
                            Button("Save") {
                                if let context = editingContext {
                                    gameManager.saveThought(
                                        questionTitle: currentQuestions[currentIndex].title,
                                        lineNum: context.line,
                                        optionText: context.optionText,
                                        thought: currentThought
                                    )
                                }
                                showThoughtPad = false
                            }
                            .foregroundColor(Theme.Colors.accent)
                        }
                        
                        TextEditor(text: $currentThought)
                            .frame(height: 150)
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(20)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(20)
                    .keyboardAwarePadding()
                }
                .zIndex(30)
            }
            
            // Evaluation Result Overlay
            if let result = evaluationResult {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            evaluationResult = nil
                            // If passed/completed, maybe we should check if we need to dismiss? 
                            // Rely on user flow or check progress again?
                            let progress = gameManager.getShiftProgress(for: currentQuestions[currentIndex])
                            if progress >= 1.0 {
                                dismiss() // Or show level complete
                            }
                        }
                    
                    VStack {
                        Spacer()
                        EvaluationResultView(result: result, difficulty: currentQuestions[currentIndex].difficulty)
                            .padding()
                            .transition(.move(edge: .bottom))
                        Spacer()
                    }
                }
                .zIndex(40)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func handleLineTap(questionIndex: Int, lineNum: Int) {
        let question = currentQuestions[questionIndex]
        // Only open if line has details (error line) – verified by dataset
        if let data = question.shiftData, data.errorLines[lineNum] != nil {
            selectedLineInfo = (questionIndex, lineNum)
            withAnimation(.spring()) {
                showOptions = true
            }
        }
    }
    
    private func getLineDetail(_ info: (questionIndex: Int, lineNumber: Int)) -> ShiftLineDetail? {
        let question = currentQuestions[info.questionIndex]
        return question.shiftData?.errorLines[info.lineNumber]
    }
    
    private func closeOptions() {
        withAnimation {
            showOptions = false
            selectedLineInfo = nil
        }
    }
}

// MARK: - Components

struct ShiftCodeSnippetView: View {
    let question: Question
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
                    let isInteractive = question.shiftData?.errorLines[lineNum] != nil
                    
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(lineNum)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(isInteractive ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isInteractive ? Theme.Colors.accent.opacity(0.05) : Color.clear)
                            .cornerRadius(4)
                        
                        if isInteractive {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(isInteractive ? Color.white.opacity(0.03) : Color.clear)
                    .onTapGesture {
                        if isInteractive {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onLineTap(lineNum)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ShiftOptionsSheet: View {
    let detail: ShiftLineDetail
    let currentQuestion: Question
    let onExplanation: (ShiftOption) -> Void
    let onThought: (ShiftOption) -> Void
    let onEvaluate: (EvaluationResult) -> Void
    let onComplete: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    @State private var attemptedOptionIds: Set<UUID> = []
    @State private var isEvaluated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Line \(detail.lineNumber) Analysis")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.accent)
                .padding(.bottom, 5)
            
            ForEach(detail.options, id: \.id) { option in
                let isAlreadyFound = gameManager.shiftFoundOptionIds[currentQuestion.title]?.contains(option.id) ?? false
                let isSelected = attemptedOptionIds.contains(option.id)
                let isCorrect = option.isCorrect
                
                // Visual State Logic
                var showSuccess: Bool {
                    isAlreadyFound || (isEvaluated && isSelected && isCorrect)
                }
                
                var showError: Bool {
                    isEvaluated && isSelected && !isCorrect
                }
                
                var showSelected: Bool {
                    !isEvaluated && isSelected && !isAlreadyFound
                }
                
                Button(action: {
                    if !isEvaluated && !isAlreadyFound {
                        withAnimation {
                            if attemptedOptionIds.contains(option.id) {
                                attemptedOptionIds.remove(option.id)
                            } else {
                                attemptedOptionIds.insert(option.id)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }) {
                    HStack {
                        Text(option.text)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        
                        // Status Icon
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.success)
                        } else if showError {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.error)
                        } else if showSelected {
                            Image(systemName: "circle.circle.fill") // Custom "Radio/Check" look
                                .font(.title2)
                                .foregroundColor(Theme.Colors.accent)
                        } else if !isAlreadyFound {
                             Image(systemName: "circle")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { onExplanation(option) }) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(Theme.Colors.electricCyan)
                            }
                            
                            Button(action: { onThought(option) }) {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(Theme.Colors.gold)
                            }
                        }
                    }
                    .padding()
                    .background(
                        Group {
                            if showSuccess {
                                Theme.Colors.success.opacity(0.1)
                            } else if showError {
                                Theme.Colors.error.opacity(0.1)
                            } else if showSelected {
                                Theme.Colors.accent.opacity(0.1)
                            } else {
                                Theme.Colors.secondaryBackground
                            }
                        }
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                showSuccess ? Theme.Colors.success :
                                showError ? Theme.Colors.error :
                                showSelected ? Theme.Colors.accent :
                                Color.white.opacity(0.1),
                                lineWidth: (showSuccess || showError || showSelected) ? 2 : 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isEvaluated || isAlreadyFound)
            }
            
            if !isEvaluated {
                Button(action: {
                    withAnimation {
                        isEvaluated = true
                        
                        // Process Results
                        var hasCorrect = false
                        var hasIncorrect = false
                        
                        for optionId in attemptedOptionIds {
                            if let option = detail.options.first(where: { $0.id == optionId }) {
                                if option.isCorrect {
                                    hasCorrect = true
                                    gameManager.markShiftOptionFound(questionTitle: currentQuestion.title, optionId: optionId)
                                } else {
                                    hasIncorrect = true
                                }
                            }
                        }
                        
                        // Completion Check
                        if hasCorrect {
                            let progress = gameManager.getShiftProgress(for: currentQuestion)
                            if progress >= 1.0 {
                                if !gameManager.completedQuestionIds.contains(currentQuestion.title) {
                                    gameManager.handleShiftCompletion(for: currentQuestion)
                                }
                                // Delay dismissal to show success feedback
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    onComplete()
                                }
                            }
                        }
                        
                        // Feedback
                        let generator = UINotificationFeedbackGenerator()
                        if hasIncorrect {
                            generator.notificationOccurred(.error)
                        } else if hasCorrect {
                            generator.notificationOccurred(.success)
                        }
                        
                        // Generate Evaluation Result
                        let status: EvaluationStatus = (hasCorrect && !hasIncorrect) ? .correct : .incorrect
                        let score = (hasCorrect && !hasIncorrect) ? 100 : 0
                        let level: UserLevel = (status == .correct) ? .passed : .failed
                        
                        var feedbackString = ""
                        if status == .correct {
                            feedbackString = "✅ Correctly identified logical flaws.\nCode analysis successful."
                        } else {
                            feedbackString = "❌ Incorrect analysis.\n"
                            if hasIncorrect {
                                feedbackString += "Some selected options were false positives.\n"
                            }
                            if !hasCorrect {
                                feedbackString += "Missed the actual error."
                            }
                        }
                        
                        let result = EvaluationResult(
                            questionID: currentQuestion.id,
                            status: status,
                            score: score,
                            level: level,
                            complexity: .medium,
                            edgeCaseHandling: true,
                            hardcodingDetected: false,
                            feedback: feedbackString
                        )
                        
                        onEvaluate(result)
                    }
                }) {
                    Text("DONE")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            attemptedOptionIds.isEmpty ? Color.gray.opacity(0.5) : Theme.Colors.accent
                        )
                        .cornerRadius(12)
                }
                .disabled(attemptedOptionIds.isEmpty)
            }
            
            Text("Select options and tap Done to verify.")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
        }
        .padding(30)
        .background(BlurView(style: .systemThinMaterialDark))
        .cornerRadius(30)
        .shadow(radius: 20)
    }
}

extension View {
    func keyboardAwarePadding() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAwareModifier())
    }
}

struct KeyboardAwareModifier: ViewModifier {
    @State private var bottomPadding: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomPadding)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
                    if let value = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                        let height = value.cgRectValue.height
                        self.bottomPadding = height
                    }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    self.bottomPadding = 0
                }
            }
    }
}
