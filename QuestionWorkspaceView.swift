import SwiftUI

struct QuestionWorkspaceView: View {
    @EnvironmentObject var gameManager: GameManager
    let questionIndex: Int
    @State private var userCode: String = ""
    @State private var showConceptQuestion = false
    @State private var showRevealButton = false // Local state for animation
    @State private var selectedOption: Int? = nil // Level 2: nil means nothing selected
    @State private var showingExplanation: Int? = nil
    @State private var showSelectionWarning = false // For handling Run without selection
    @State private var showLevel2DetailedResult = false

    @Environment(\.dismiss) var dismiss
    
    // Shake animation state
    @State private var shakeSolutionButton = false
    
    var question: Question {
        if gameManager.currentLevel.questions.indices.contains(questionIndex) {
            return gameManager.currentLevel.questions[questionIndex]
        }
        return gameManager.currentLevel.questions[0]
    }
    
    var body: some View {
        if question.shiftData != nil {
            ShiftQuestionView(initialIndex: questionIndex)
        } else {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Theme.Colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        headerView
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                missionBriefView
                                codeEditorView
                            }
                        }
                    }
                    
                    executionButton
                    
                    // OVERLAYS (Results & Progress)
                    // OVERLAYS (Results & Progress)
                    if question.difficulty == 2 {
                        // Level 2 Result is pushed via fullScreenCover/sheet below
                    } else {
                        if case .correct = gameManager.executionState {
                            SuccessOverlay(score: 100) {
                                gameManager.executionState = .idle
                                dismiss() // Back to grid/dashboard
                            }
                        } else if case .error(let message) = gameManager.executionState {
                            ErrorOverlay(message: message) {
                                gameManager.executionState = .idle
                            }
                        }
                    }
                    
                    if case .levelComplete(let next, _) = gameManager.executionState {
                        LevelUnlockOverlay(nextLevel: next, isForced: false) {
                            dismiss()
                        }
                    }
                }
                .overlay(
                    // Concept Question Modal
                    Group {
                        if showConceptQuestion {
                            ConceptQuestionView(question: question, isPresented: $showConceptQuestion) {
                                gameManager.unlockHint()
                            }
                        }
                    }
                )
            }
            .onAppear {
                gameManager.currentQuestionIndex = questionIndex
                // architecture change: Reset state on appear
                gameManager.resetQuestionState(for: question)
                
                userCode = question.initialCode
                selectedOption = nil
                showSelectionWarning = false
            }
            .onChange(of: gameManager.executionState) { _, newState in
                if question.difficulty == 2 {
                    if newState == .correct || (caseError(newState) != nil) {
                         showLevel2DetailedResult = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showLevel2DetailedResult) {
                if let result = gameManager.lastEvaluationResult {
                    DetailedEvaluationScreen(result: result, difficulty: 2) {
                        showLevel2DetailedResult = false
                        if result.status == .correct {
                            dismiss()
                        } else {
                            gameManager.executionState = .idle
                            selectedOption = nil
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func caseError(_ state: GameManager.ExecutionState) -> String? {
        if case .error(let msg) = state { return msg }
        return nil
    }
    private var missionBriefView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Theme.Colors.electricCyan)
                Text(question.difficulty == 2 ? "HIT (RIDDLE)" : "MISSION BRIEF")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(1)
                Spacer()
                
                // Language Badge
                Text(question.language.rawValue.uppercased())
                    .font(Theme.Typography.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.electricCyan.opacity(0.1))
                    .foregroundColor(Theme.Colors.electricCyan)
                    .cornerRadius(6)
            }
            
            if question.difficulty == 2 {
                // Level 2 HIT Section: Always Visible
                Text(question.riddle)
                    .font(Theme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.electricCyan.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.electricCyan.opacity(0.2), lineWidth: 1)
                    )
            } else if gameManager.unlockedHints.contains(question.title) {
                Text(question.riddle)
                    .font(Theme.Typography.body)
                    .italic()
                    .foregroundColor(Theme.Colors.textPrimary)
            } else {
                Button(action: {
                    showConceptQuestion = true
                }) {
                    HStack {
                        Text("Unlock Clue")
                            .font(Theme.Typography.headline)
                        Image(systemName: "lock.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.background)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(Theme.Layout.padding)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        .padding(.horizontal)
    }

    private var codeEditorView: some View {
        VStack(spacing: 0) {
            editorHeader
            
            VStack(alignment: .leading, spacing: 0) {
                if question.difficulty == 2 {
                    level2CodeDisplay
                    Divider().padding(.vertical, 8)
                    level2OptionsList
                } else {
                    standardCodeEditor
                }
            }
            .background(Theme.Colors.codeBackground)
            .cornerRadius(Theme.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
            .padding(.horizontal)
            
            evaluationResultSection
            
            Spacer().frame(height: 80)
        }
    }

    private var editorHeader: some View {
        HStack {
            Text("SOURCE CODE")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading)
            Spacer()
        }
        .padding(.top, 10)
    }

    private var level2CodeDisplay: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(question.initialCode)
                .font(Theme.Typography.codeFont)
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Theme.Colors.codeBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var level2OptionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IDENTIFY THE ERROR TYPE")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.electricCyan)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                ForEach(0..<question.conceptOptions.count, id: \.self) { index in
                    optionRow(index: index)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .sheet(item: Binding(
            get: { showingExplanation.map { IdentifiableInt(value: $0) } },
            set: { showingExplanation = $0?.value }
        )) { item in
            explanationModal(index: item.value)
        }
    }

    private func optionRow(index: Int) -> some View {
        HStack(spacing: 0) {
            Button(action: {
                selectedOption = index
                showSelectionWarning = false
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }) {
                HStack {
                    Text(index < question.conceptOptions.count ? question.conceptOptions[index] : "")
                        .font(Theme.Typography.body)
                        .fontWeight(selectedOption == index ? .bold : .regular)
                        .foregroundColor(selectedOption == index ? Theme.Colors.electricCyan : Theme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if selectedOption == index {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.electricCyan)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                }
                .padding(.vertical, 16)
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            if question.conceptOptionsExplanations != nil {
                Button(action: {
                    showingExplanation = index
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.electricCyan)
                        .padding(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(selectedOption == index ? Theme.Colors.electricCyan.opacity(0.15) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedOption == index ? Theme.Colors.electricCyan : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: selectedOption == index ? Theme.Colors.electricCyan.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
    }

    private func explanationModal(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Explanation")
                    .font(Theme.Typography.title3)
                    .bold()
                Spacer()
                Button(action: { showingExplanation = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            
            Text(index < question.conceptOptions.count ? question.conceptOptions[index] : "")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.electricCyan)
            
            if let explanations = question.conceptOptionsExplanations, index < explanations.count {
                Text(explanations[index])
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(30)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var standardCodeEditor: some View {
        ZStack(alignment: .topLeading) {
            if userCode.isEmpty {
                Text("Enter your code here...")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(Theme.Typography.codeFont)
                    .padding(12)
                    .padding(.top, 8)
            }
            
            TextEditor(text: $userCode)
                .font(Theme.Typography.codeFont)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 200)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onChange(of: userCode) { _, newValue in
                    let filtered = newValue.replacingOccurrences(of: "“", with: "\"")
                        .replacingOccurrences(of: "”", with: "\"")
                        .replacingOccurrences(of: "‘", with: "'")
                        .replacingOccurrences(of: "’", with: "'")
                    
                    if filtered != newValue {
                        userCode = filtered
                    }
                }
        }
    }

    private var evaluationResultSection: some View {
        Group {
            if let result = gameManager.lastEvaluationResult, 
               result.questionID == question.id, // Safety: Only show if matches current question
               !gameManager.executionState.isRunning, 
               question.difficulty != 2 {
                EvaluationResultView(result: result, difficulty: question.difficulty)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if gameManager.executionState.isRunning {
                CompilerConsoleView(gameManager: gameManager)
                    .frame(height: 200)
                    .transition(.opacity)
            }
        }
    }

    private var executionButton: some View {
        VStack {
            Spacer()
            Button(action: {
                if question.difficulty == 2 {
                    guard let selection = selectedOption else {
                        withAnimation { showSelectionWarning = true }
                        return
                    }
                    showSelectionWarning = false
                    let code = "// SELECTED_OPT: \(selection)\n" + question.initialCode
                    gameManager.runCode(userCode: code)
                } else {
                    gameManager.runCode(userCode: userCode)
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }) {
                HStack {
                    if gameManager.executionState.isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(gameManager.executionState.isRunning ? "RUNNING..." : "RUN CODE")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Theme.Colors.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.electricCyan.opacity(0.4), radius: 10, x: 0, y: 5)
                .scaleEffect(gameManager.executionState == .running ? 0.95 : 1.0)
                .animation(.spring(), value: gameManager.executionState)
            }
            .disabled(gameManager.executionState == .running)
            
            if showSelectionWarning {
                Text("⚠️ PLEASE SELECT AN OPTION")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.error)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
            
            Spacer().frame(height: 30)
        }
    }

    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryGradient)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            // Level Goal Pill
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.electricCyan)
                
                Text("LEVEL \(gameManager.currentLevelIndex + 1): \(question.description)")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 8, x: 0, y: 4)
            
            Spacer()
            
            // Stats Pill
            HStack(spacing: 16) {

                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    Text("\(gameManager.streak)")
                    .font(Theme.Typography.statsFont)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(Theme.Colors.gold)
                    Text("\(gameManager.coinBalance)")
                    .font(Theme.Typography.statsFont)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
        }
        .padding()
    }
}

// Helper Structures (ErrorOverlay, SuccessOverlay, etc.) remain the same but styled?
// Assuming they are reusable, I'll keep them as defined in previous file or redefine if they were inside the file.
// In the previous file they were defined at file level. I should include them.

struct ErrorOverlay: View {
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterialDark).ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.error)
                    .neonGlow(color: Theme.Colors.error)
                
                Text("EXECUTION HALTED")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.error)
                    .tracking(2)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal)
                
                Button(action: dismissAction) {
                    Text("REINITIALIZE")
                        .font(Theme.Typography.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.error)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(40)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Theme.Colors.error.opacity(0.5), lineWidth: 2)
            )
            .padding(30)
        }
    }
}

struct SuccessOverlay: View {
    let score: Int
    let continueAction: () -> Void
    
    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterialDark).ignoresSafeArea()
            VStack(spacing: 25) {
                // Circular Score Indicator
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.secondaryBackground.opacity(0.5), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(Theme.Colors.success, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(score)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 10)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.success)
                    .neonGlow(color: Theme.Colors.success)
                
                Text("SOLUTION VERIFIED")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.success)
                    .tracking(2)
                
                HStack(spacing: 20) {
                    achievementBadge(icon: AnyView(BugCoin(size: 16)), label: "+1 COIN")
                    achievementBadge(icon: AnyView(Text("⚡️")), label: "+10 XP")
                }
                
                Button(action: continueAction) {
                    Text("CONTINUE MISSION")
                        .font(Theme.Typography.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.success)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(40)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Theme.Colors.success.opacity(0.5), lineWidth: 2)
            )
            .padding(30)
        }
    }
    
    func achievementBadge(icon: AnyView, label: String) -> some View {
        HStack(spacing: 4) {
            icon
            Text(label)
                .font(Theme.Typography.caption2)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct LevelUnlockOverlay: View {
    let nextLevel: Int
    let isForced: Bool
    let continueAction: () -> Void
    
    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterialDark).ignoresSafeArea()
            VStack(spacing: 30) {
                Text(isForced ? "MILESTONE REACHED" : "NEW SECTOR DETECTED")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.electricCyan)
                    .tracking(3)
                
                Image(systemName: isForced ? "trophy.fill" : "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.gold)
                    .neonGlow(color: Theme.Colors.gold)
                
                VStack(spacing: 10) {
                    Text(isForced ? "MASTERED LEVEL \(nextLevel - 1)" : "LEVEL \(nextLevel) UNLOCKED")
                        .font(Theme.Typography.title3)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(isForced ? "Moving to next execution phase..." : "You have gained access to deeper documentation.")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: continueAction) {
                    Text("PROCEED")
                        .font(Theme.Typography.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.electricCyan)
                        .foregroundColor(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                }
            }
            .padding(40)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Theme.Colors.electricCyan.opacity(0.3), lineWidth: 2)
            )
            .padding(30)
        }
    }
}

// MARK: - Detailed Evaluation Screen (for Level 2 Navigate)
struct DetailedEvaluationScreen: View {
    let result: EvaluationResult
    let difficulty: Int
    let action: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    EvaluationResultView(result: result, difficulty: difficulty)
                    
                    Button(action: action) {
                        Text(result.status == .correct ? "CONTINUE" : "TRY AGAIN")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(result.status == .correct ? Theme.Colors.success : Theme.Colors.action)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}
