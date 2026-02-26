import SwiftUI
import Combine

@MainActor
class GameManager: ObservableObject {
    enum ExecutionState: Equatable {
        case idle
        case running
        case correct
        case error(String)
        case levelComplete(Int, Bool) // Next Level number, Is Forced?
        
        var isIdle: Bool {
            if case .idle = self { return true }
            return false
        }
        
        var isRunning: Bool {
            if case .running = self { return true }
            return false
        }
    }
    
    // Core Data
    @Published var levels: [Level] = []
    @Published var currentLevelIndex: Int = 0
    @Published var currentQuestionIndex: Int = 0 // 0-49
    @Published var selectedLanguage: Language = .python
    @Published var username: String = "Student Developer"
    
    // Game State
    @Published var executionState: ExecutionState = .idle
    @Published var lastEvaluationResult: EvaluationResult?
    @Published var attempts: [String: Int] = [:]
    @Published var completedQuestionIds: Set<String> = []
    
    // Gamification
    @Published var streak: Int = 0
    @Published var dailyStreak: Int = 0
    @Published var lastActiveDate: Date?
    @Published var totalXP: Int = 0
    @Published var lifetimeAttempts: Int = 0
    @Published var history: [HistoryEntry] = []
    
    // Testing Flag
    @Published var isTestingMode: Bool = true
    
    // Premium Features
    @Published var unlockedHints: Set<String> = []
    @Published var revealedSolutions: Set<String> = []
    @Published var shiftThoughts: [String: String] = [:]
    @Published var shiftFoundOptionIds: [String: Set<UUID>] = [:] // QuestionTitle -> Set<OptionID>
    
    // Adaptive Tracking
    @Published var mistakePatterns: [QuestionCategory: Int] = [:]
    
    // Decorative Triggers
    @Published var hasTriggeredLaunchAnimation = false
    @Published var onboardingCompleted: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var onboardingStep: Int = 0
    @Published var levelOnboardingCompleted: Bool = false
    @Published var showLevelOnboarding: Bool = false
    @Published var levelOnboardingStep: Int = 0
    
    // Developer Storage
    @Published var savedCorrectCode: [String: String] = [:]
    
    func triggerPassReward() {
        // Trigger sound specifically for reward
        SoundManager.shared.playSuccess()
    }
    
    @Published var isDarkMode: Bool = false
    
    private let isDarkModeKey = "debug_lab_is_dark_mode"
    private let shiftThoughtsKey = "debug_lab_shift_thoughts"
    private let shiftFoundKey = "debug_lab_shift_found"
    
    
    // Daily Hints
    @Published var dailyFreeHintsUsed: Int = 0
    @Published var lastDailyReset: Date?
    
    // Keys for persistence
    private let attemptsKey = "debug_lab_attempts"
    private let completionKey = "debug_lab_completion"
    private let currentLevelKey = "debug_lab_current_level"
    private let hintsKey = "debug_lab_hints"
    private let solutionsKey = "debug_lab_solutions"
    private let unlockedLevelsKey = "debug_lab_unlocked_levels"
    private let languageKey = "debug_lab_language"
    private let dailyStreakKey = "debug_lab_daily_streak"
    private let lastActiveDateKey = "debug_lab_last_active_date"
    private let livesKey = "debug_lab_lives"
    private let lastLifeRegenKey = "debug_lab_last_life_regen"
    private let dailyHintsKey = "debug_lab_daily_hints_used"
    private let lastDailyResetKey = "debug_lab_last_daily_reset"
    private let onboardingCompletedKey = "debug_lab_onboarding_completed"
    private let levelOnboardingCompletedKey = "debug_lab_level_onboarding_completed"
    private let usernameKey = "debug_lab_username"
    private let progressDataKey = "debug_lab_progress_data"
    
    // Multi-Language Progress Store
    @Published var progressData: [String: LanguageProgress] = [:]
    
    init() {
        self.levels = Question.levels
        populateQuestionMetadata()
        loadProgress()
        Theme.isDarkMode = self.isDarkMode
        Theme.selectedLanguage = self.selectedLanguage
        
        // Onboarding logic
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        if !onboardingCompleted {
            self.showOnboarding = true
        }
        
        self.levelOnboardingCompleted = UserDefaults.standard.bool(forKey: levelOnboardingCompletedKey)
        
        setupInitialState()
        // Check streak on launch to see if it was broken
        // Check streak on launch to see if it was broken
        checkDailyStreakOnLaunch()
        checkDailyHintReset()
        debugUnlockAllLevels() // Enabled for testing
        // enforceStrictLevelLocks()
        auditExpectedOutputs()
    }
    
    private func auditExpectedOutputs() {
        print("--- MISSING EXPECTED OUTPUTS ---")
        for language in [Language.swift, Language.c] {
            print("Language: \(language.rawValue)")
            for level in Question.levels(for: language) {
                for (index, question) in level.questions.enumerated() {
                    if question.isMissingExpectedOutput {
                        print("Level \(level.number) – Question \(index + 1)")
                    }
                }
            }
        }
        print("--------------------------------")
    }
    
    private func populateQuestionMetadata() {
        for lIdx in 0..<levels.count {
            for qIdx in 0..<levels[lIdx].questions.count {
                levels[lIdx].questions[qIdx].levelNumber = levels[lIdx].number
                levels[lIdx].questions[qIdx].questionNumber = qIdx + 1
            }
        }
    }
    
    private func debugUnlockAllLevels() {
        guard isTestingMode else { return }
        for i in 0..<levels.count {
            levels[i].unlocked = true
        }
        // Save to current progress as well
        var currentProgress = progressData[selectedLanguage.rawValue] ?? LanguageProgress()
        currentProgress.unlockedLevels = Set(0..<levels.count)
        progressData[selectedLanguage.rawValue] = currentProgress
        saveProgress()
    }
    
    private func enforceStrictLevelLocks() {
        // Ensure Level 1 is always unlocked
        if !levels.isEmpty { levels[0].unlocked = true }
        
        // Check subsequent levels
        for i in 1..<levels.count {
            let prevLevel = levels[i-1]
            let completedInPrev = prevLevel.questions.filter { completedQuestionIds.contains($0.title) }.count
            
            if completedInPrev < prevLevel.totalQuestions {
                levels[i].unlocked = false
            } else {
                // Determine if it WAS unlocked or should be? 
                // Using the persistent state is fine, but if we want to AUTO unlock if complete:
                // levels[i].unlocked = true
                // But usually we just want to LOCK if NOT complete.
                // If they completed Level 1, Level 2 might still be locked if they haven't triggered the unlock event.
                // But let's assume if they finished Level 1, Level 2 *should* be open.
                levels[i].unlocked = true 
            }
        }
        saveProgress()
    }

    var currentLevel: Level {
        if levels.indices.contains(currentLevelIndex) {
            return levels[currentLevelIndex]
        }
        return levels[0]
    }
    
    var currentQuestion: Question {
        if currentLevel.questions.indices.contains(currentQuestionIndex) {
            return currentLevel.questions[currentQuestionIndex]
        }
        return currentLevel.questions[0]
    }
    
    var currentAttempts: Int {
        attempts[currentQuestion.title, default: 0]
    }
    
    // MARK: - Level & Language Selection
    
    func selectLevel(_ index: Int) {
        if index < levels.count && levels[index].unlocked {
            currentLevelIndex = index
            // Data is ready, UI should navigate to Language Select then Dashboard
        }
    }
    
    func selectLanguage(_ language: Language) {
        guard language != selectedLanguage else { return }
        
        // 1. Save current language state
        saveCurrentToProgressData()
        
        // 2. Switch language
        selectedLanguage = language
        Theme.selectedLanguage = language
        
        // 3. Load new language state
        loadFromProgressData()
        
        // 4. Refresh content
        refreshQuestions()
        
        // 5. Persist the switch
        saveProgress()
        
        // 6. Trigger level onboarding if not completed
        if onboardingCompleted && !levelOnboardingCompleted {
            showLevelOnboarding = true
            levelOnboardingStep = 0
        }
    }
    
    private func refreshQuestions() {
        var updatedLevels = Question.levels(for: selectedLanguage)
        
        for i in 0..<updatedLevels.count {
            if isTestingMode {
                updatedLevels[i].unlocked = true
            } else if i < levels.count {
                // If not in testing mode, preserve existing unlock state if available
                updatedLevels[i].unlocked = levels[i].unlocked
            }
            
            if i < levels.count {
                levels[i] = updatedLevels[i]
            } else {
                levels.append(updatedLevels[i])
            }
        }
        
        populateQuestionMetadata()
    }
    
    func unlockThresholdReached(for levelIndex: Int) -> Bool {
        let level = levels[levelIndex]
        let completedInLevel = level.questions.filter { completedQuestionIds.contains($0.title) }.count
        return completedInLevel >= 15
    }
    

    
    func resetQuestionState(for question: Question) {
        lastEvaluationResult = nil
        executionState = .idle
    }

    // MARK: - Daily Streak Logic
    
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func checkDailyStreakOnLaunch() {
        guard let lastDate = lastActiveDate else { return }
        
        let today = normalizeDate(Date())
        let last = normalizeDate(lastDate)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: last, to: today)
        
        if let days = components.day, days > 1 {
            // Missed at least one full calendar day (e.g., solved Mon, today is Wed)
            dailyStreak = 0
            saveProgress()
        }
    }

    private func checkDailyHintReset() {
        let now = Date()
        if let lastReset = lastDailyReset, Calendar.current.isDateInToday(lastReset) {
            return
        }
        // It's a new day (or first launch)
        dailyFreeHintsUsed = 0
        lastDailyReset = now
        saveProgress()
    }
    

    
    func registerActivity() {
        let today = normalizeDate(Date())
        
        if let lastDate = lastActiveDate {
            let last = normalizeDate(lastDate)
            
            if today == last {
                // Case B: Same Day Activity - Do nothing
                return
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: last, to: today)
            
            if components.day == 1 {
                // Case C: Consecutive Day
                dailyStreak += 1
            } else {
                // Case D: Missed One Or More Days (or clock went backwards)
                dailyStreak = 1
            }
        } else {
            // Case A: First Ever Activity
            dailyStreak = 1
        }
        
        lastActiveDate = today
        saveProgress()
    }
    
    // MARK: - Gameplay Logic
    
    func runCode(userCode: String) {
        guard executionState != .running else { return }
        
        let title = currentQuestion.title
        let currentAttempts = attempts[title, default: 0]
        let maxAttempts = 5
        
        // Check if locked
        if currentAttempts >= maxAttempts && !completedQuestionIds.contains(title) {
             self.lastEvaluationResult = EvaluationResult(
                questionID: currentQuestion.id,
                status: .incorrect,
                score: 0,
                level: .failed,
                complexity: .low,
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "❌ Question Locked\nYou have exceeded the maximum of \(maxAttempts) attempts for this question.",
                difficulty: currentQuestion.difficulty,
                testResults: [TestCaseResult(input: "Status", expected: "Unlocked", actual: "Locked", passed: false)],
                xpEarned: 0
            )
            self.executionState = .error("Question Locked")
            return
        }

        // Increment attempts
        attempts[title, default: 0] += 1
        lifetimeAttempts += 1
        executionState = .running
        
        let newAttemptCount = attempts[title, default: 0]
        
        // Immediate execution on next run loop to allow UI update
        DispatchQueue.main.async {
            let result = CompilerEngine.shared.evaluate(code: userCode, for: self.currentQuestion, attempts: newAttemptCount)
            self.lastEvaluationResult = result
            
            if result.isSuccess {
                self.handleCorrectSubmission(code: userCode)
            } else {
                // Adaptive Tracking: Log the mistake
                if let selectedCategory = result.userSelectedCategory {
                    // Level 2 direct selection mapping
                    for category in QuestionCategory.allCases {
                        if selectedCategory.lowercased().contains(category.rawValue.lowercased()) {
                            self.mistakePatterns[category, default: 0] += 1
                            break
                        }
                    }
                } else {
                    // Generic question category tracking
                    self.mistakePatterns[self.currentQuestion.category, default: 0] += 1
                }
                
                // Trigger reordering immediately on failure detection
                self.applyAdaptiveReordering()
                
                let errorMessage = result.message
                self.executionState = .error(errorMessage)
                self.streak = 0
                
                // Live Activity Failure
                Task { @MainActor in
                    LiveActivityManager.shared.endWithFailure(error: result.errorType?.rawValue ?? "Compilation Fail")
                }
                
                self.saveProgress()
            }
        }
    }
    
    private func handleCorrectSubmission(code: String) {
        // Save the correct code for developer history
        savedCorrectCode[currentQuestion.title] = code
        
        // Clear pattern on success to allow progression
        if let weakness = getWeakness(), currentQuestion.category == weakness {
            mistakePatterns[weakness] = 0
        }
        
        // Only reward if not already completed
        if !completedQuestionIds.contains(currentQuestion.title) {
            completedQuestionIds.insert(currentQuestion.title)
            streak += 1
            registerActivity() // Update Daily Streak
            captureHistorySnapshot() // Capture progress for graph
            totalXP += 10 // Fixed XP per question
            
            attempts[currentQuestion.title] = 0
            
            // Live Activity Success
            Task { @MainActor in
                LiveActivityManager.shared.endWithSuccess(xp: 50, streak: self.streak)
            }
            
            checkLevelUnlock()
            
            // Adaptive Injection
            applyAdaptiveReordering()
            
            // Decorative Success Feedback
            triggerPassReward()
        }
        
        executionState = .correct
        saveProgress()
    }
    
    private func getWeakness() -> QuestionCategory? {
        let sorted = mistakePatterns.sorted { $0.value > $1.value }
        if let top = sorted.first, top.value >= 2 { // Pattern detected after 2 mistakes
            return top.key
        }
        return nil
    }
    
    private func applyAdaptiveReordering() {
        guard let weakness = getWeakness() else { return }
        
        let nextIdx = currentQuestionIndex + 1
        guard nextIdx < levels[currentLevelIndex].questions.count else { return }
        
        // Find a future question that matches the weakness
        for i in (nextIdx + 1)..<levels[currentLevelIndex].questions.count {
            if levels[currentLevelIndex].questions[i].category == weakness {
                // Swap but maintain same difficulty tier (metadata check would go here)
                let temp = levels[currentLevelIndex].questions[nextIdx]
                levels[currentLevelIndex].questions[nextIdx] = levels[currentLevelIndex].questions[i]
                levels[currentLevelIndex].questions[i] = temp
                break
            }
        }
    }
    
    private func captureHistorySnapshot() {
        // Calculate Accuracy
        let solved = completedQuestionIds.count
        let accuracy = lifetimeAttempts > 0 ? (Double(solved) / Double(lifetimeAttempts)) * 100.0 : 0.0
        
        let entry = HistoryEntry(
            date: Date(),
            xp: totalXP,
            solvedCount: solved,
            accuracy: accuracy
        )
        history.append(entry)
    }
    
    private func checkLevelUnlock() {
        let completedCount = levelProgress(for: currentLevelIndex)
        let nextLevelIndex = currentLevelIndex + 1
        
        guard nextLevelIndex < levels.count else { return }
        
        // Threshold Logic
        var threshold = levels[currentLevelIndex].totalQuestions
        
        if currentLevelIndex == 0 { // Level 1 -> Level 2
            threshold = 25
        } else if currentLevelIndex == 2 { // Level 3 -> Level 4
            threshold = 15
        }
        
        if completedCount >= threshold {
            if !levels[nextLevelIndex].unlocked {
                levels[nextLevelIndex].unlocked = true
                executionState = .levelComplete(nextLevelIndex + 1, false)
            }
        }
    }
    
    
    func levelProgress(for index: Int) -> Int {
        guard index < levels.count else { return 0 }
        let level = levels[index]
        let levelQuestionIds = level.questions.map { $0.title }
        let solvedCount = completedQuestionIds.intersection(levelQuestionIds).count
        return solvedCount
    }

    func questionsRequiredForNextLevel(levelIndex: Int) -> Int {
        guard levelIndex < levels.count else { return 0 }
        return levels[levelIndex].totalQuestions
    }
    
    
    func unlockHint() {
        guard !unlockedHints.contains(currentQuestion.title) else { return }
        
        unlockedHints.insert(currentQuestion.title)
        saveProgress()
    }
    
    func revealSolution() {
        guard !revealedSolutions.contains(currentQuestion.title) else { return }
        
        revealedSolutions.insert(currentQuestion.title)
        // Also unlock the hint (Decrypted Concept) so the user understands the answer
        unlockedHints.insert(currentQuestion.title)
        saveProgress()
    }
    
    func getGenreQuestions(for genre: Genre) -> [GenreQuestion] {
        return Question.genreQuestions.filter { $0.genre == genre }
    }
    
    func unlockHintWithGenreQuiz() {
        // This is called AFTER successful quiz completion
        unlockHint()
    }
    
    func updateUsername(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            self.username = trimmed
            saveProgress()
        }
    }
    
    func saveThought(questionTitle: String, lineNum: Int, optionText: String, thought: String) {
        let key = "\(questionTitle)_\(lineNum)_\(optionText)"
        if thought.isEmpty {
            shiftThoughts.removeValue(forKey: key)
        } else {
            shiftThoughts[key] = thought
        }
        saveProgress()
    }
    
    func getThought(questionTitle: String, lineNum: Int, optionText: String) -> String {
        let key = "\(questionTitle)_\(lineNum)_\(optionText)"
        return shiftThoughts[key] ?? ""
    }
    
    // MARK: - Shift Progress Logic
    
    func markShiftOptionFound(questionTitle: String, optionId: UUID) {
        var found = shiftFoundOptionIds[questionTitle] ?? []
        found.insert(optionId)
        shiftFoundOptionIds[questionTitle] = found
        saveProgress()
    }
    
    func getShiftProgress(for question: Question) -> Double {
        guard let data = question.shiftData else { return 0 }
        
        let errorLines = data.errorLines
        guard !errorLines.isEmpty else { return 0 }
        
        // Count how many of the "Real Errors" (error lines) are successfully cleared.
        // A line is cleared if ALL its correct options are found.
        let foundIds = shiftFoundOptionIds[question.title] ?? []
        
        var clearedLinesCount = 0
        for (_, detail) in errorLines {
            let correctOptionIds = detail.options.filter { $0.isCorrect }.map { $0.id }
            if !correctOptionIds.isEmpty && correctOptionIds.allSatisfy({ foundIds.contains($0) }) {
                clearedLinesCount += 1
            }
        }
        
        return Double(clearedLinesCount) / Double(errorLines.count)
    }
    
    func handleShiftCompletion(for question: Question) {
        if !completedQuestionIds.contains(question.title) {
            completedQuestionIds.insert(question.title)
            streak += 1
            registerActivity()
            totalXP += 10
            
            checkLevelUnlock()
            saveProgress()
            
            // Live Activity Success
            Task { @MainActor in
                LiveActivityManager.shared.endWithSuccess(xp: 50, streak: self.streak)
            }

            // Decorative Success Feedback
            triggerPassReward()
        }
    }
    
    // MARK: - Progress State Management
    
    private func saveCurrentToProgressData() {
        let currentKey = selectedLanguage.rawValue
        var progress = progressData[currentKey] ?? LanguageProgress()
        
        progress.currentLevelIndex = currentLevelIndex
        progress.completedQuestionIds = completedQuestionIds
        progress.streak = streak
        progress.totalXP = totalXP
        progress.unlockedHints = unlockedHints
        progress.revealedSolutions = revealedSolutions
        progress.dailyFreeHintsUsed = dailyFreeHintsUsed
        progress.lastDailyReset = lastDailyReset
        progress.shiftFoundOptionIds = shiftFoundOptionIds
        progress.shiftThoughts = shiftThoughts
        progress.attempts = attempts
        progress.lifetimeAttempts = lifetimeAttempts
        progress.history = history
        progress.isDarkMode = isDarkMode
        
        // Unlocked Levels
        let unlockedSet = Set(levels.filter { $0.unlocked }.map { $0.number })
        progress.unlockedLevels = unlockedSet
        
        progressData[currentKey] = progress
    }
    
    private func loadFromProgressData() {
        let currentKey = selectedLanguage.rawValue
        let progress = progressData[currentKey] ?? LanguageProgress()
        
        unlockedHints = progress.unlockedHints
        revealedSolutions = progress.revealedSolutions
        dailyFreeHintsUsed = progress.dailyFreeHintsUsed
        lastDailyReset = progress.lastDailyReset
        shiftThoughts = progress.shiftThoughts
        shiftFoundOptionIds = progress.shiftFoundOptionIds
        attempts = progress.attempts
        lifetimeAttempts = progress.lifetimeAttempts
        history = progress.history
        isDarkMode = progress.isDarkMode
        Theme.isDarkMode = isDarkMode
        
        // Restore Level Unlock State
        // First lock all except level 1 (unless strict mode logic overrides)
        // But strictly follow persistence
        for i in 0..<levels.count {
            if progress.unlockedLevels.contains(levels[i].number) {
                levels[i].unlocked = true
            } else {
                levels[i].unlocked = false // Lock unless in set
            }
        }
        // Ensure Level 1 is always unlocked
        if !levels.isEmpty { levels[0].unlocked = true }
    }
    
    // MARK: - Persistence
    
    func saveProgress() {
        // 1. Snapshot current state into the dictionary
        saveCurrentToProgressData()
        
        // 2. Persist the dictionary
        if let encoded = try? JSONEncoder().encode(progressData) {
            UserDefaults.standard.set(encoded, forKey: progressDataKey)
        }
        
        // 3. Persist global settings (shared)
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageKey)
        UserDefaults.standard.set(username, forKey: usernameKey)
        
        // Persist Daily Streak (Global)
        UserDefaults.standard.set(dailyStreak, forKey: dailyStreakKey)
        if let lastDate = lastActiveDate {
            UserDefaults.standard.set(lastDate.timeIntervalSince1970, forKey: lastActiveDateKey)
        }
        UserDefaults.standard.set(onboardingCompleted, forKey: onboardingCompletedKey)
        UserDefaults.standard.set(levelOnboardingCompleted, forKey: levelOnboardingCompletedKey)
    }
    private func loadProgress() {
        // 1. Shared Data
        if let savedUsername = UserDefaults.standard.string(forKey: usernameKey) {
            username = savedUsername
        }
        
        if let languageRaw = UserDefaults.standard.string(forKey: languageKey),
           let language = Language(rawValue: languageRaw) {
            selectedLanguage = language
        }
        
        // 2. Load Progress Dictionary
        if let data = UserDefaults.standard.data(forKey: progressDataKey),
           let decoded = try? JSONDecoder().decode([String: LanguageProgress].self, from: data) {
            progressData = decoded
        } else {
            // Migration: If no new data, try to load legacy data into current language slot
            migrateLegacyData()
        }
        
        // 3. Load Global Streak Data (Overrides per-language if any existed)
        self.dailyStreak = UserDefaults.standard.integer(forKey: dailyStreakKey)
        if let t = UserDefaults.standard.object(forKey: lastActiveDateKey) as? TimeInterval {
            self.lastActiveDate = Date(timeIntervalSince1970: t)
        }
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        self.levelOnboardingCompleted = UserDefaults.standard.bool(forKey: levelOnboardingCompletedKey)
        
        // 3. Apply to Published Properties
        loadFromProgressData()
        
        // 4. Ensure Content Matches Language
        refreshQuestions()
        Theme.selectedLanguage = self.selectedLanguage
    }
    
    private func migrateLegacyData() {
        // Create a progress object based on legacy keys
        var legacy = LanguageProgress()
        
        if let val = UserDefaults.standard.dictionary(forKey: attemptsKey) as? [String: Int] { legacy.attempts = val }
        legacy.dailyFreeHintsUsed = UserDefaults.standard.integer(forKey: dailyHintsKey)
        if let t = UserDefaults.standard.object(forKey: lastDailyResetKey) as? TimeInterval { legacy.lastDailyReset = Date(timeIntervalSince1970: t) }
        if let ids = UserDefaults.standard.stringArray(forKey: completionKey) { legacy.completedQuestionIds = Set(ids) }
        legacy.currentLevelIndex = UserDefaults.standard.integer(forKey: currentLevelKey)
        
        if let h = UserDefaults.standard.stringArray(forKey: hintsKey) { legacy.unlockedHints = Set(h) }
        if let s = UserDefaults.standard.stringArray(forKey: solutionsKey) { legacy.revealedSolutions = Set(s) }
        
        if let u = UserDefaults.standard.array(forKey: unlockedLevelsKey) as? [Int] { legacy.unlockedLevels = Set(u) }
        
        legacy.streak = UserDefaults.standard.integer(forKey: "debug_lab_streak")
        legacy.dailyStreak = UserDefaults.standard.integer(forKey: dailyStreakKey)
        if let t = UserDefaults.standard.object(forKey: lastActiveDateKey) as? TimeInterval { legacy.lastActiveDate = Date(timeIntervalSince1970: t) }
        legacy.totalXP = UserDefaults.standard.integer(forKey: "debug_lab_total_xp")
        
        if let d = UserDefaults.standard.dictionary(forKey: shiftThoughtsKey) as? [String: String] { legacy.shiftThoughts = d }
        if let d = UserDefaults.standard.dictionary(forKey: shiftFoundKey) as? [String: [String]] {
            var restored: [String: Set<UUID>] = [:]
            for (k, v) in d {
                restored[k] = Set(v.compactMap { UUID(uuidString: $0) })
            }
            legacy.shiftFoundOptionIds = restored
        }
        
        // Store into current language slot
        progressData[selectedLanguage.rawValue] = legacy
    }
    private func setupInitialState() {
        if !levels.isEmpty {
            levels[0].unlocked = true
        }
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
        showOnboarding = false
        saveProgress()
        
        // Trigger level onboarding immediately after if language is already selected
        if !levelOnboardingCompleted {
            showLevelOnboarding = true
            levelOnboardingStep = 0
        }
    }
    
    func completeLevelOnboarding() {
        levelOnboardingCompleted = true
        showLevelOnboarding = false
        saveProgress()
    }
    
    func replayLevelOnboarding() {
        levelOnboardingStep = 0
        showLevelOnboarding = true
    }
    
    func replayOnboarding() {
        showOnboarding = true
        // We don't necessarily reset onboardingCompleted until they finish it again or we can just leave it true
    }
}
