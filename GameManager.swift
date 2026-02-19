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
    @Published var coinBalance: Int = 10 // Starting bonus
    @Published var unlockedHints: Set<String> = []
    @Published var revealedSolutions: Set<String> = []
    @Published var shiftThoughts: [String: String] = [:]
    @Published var shiftFoundOptionIds: [String: Set<UUID>] = [:] // QuestionTitle -> Set<OptionID>
    
    private let shiftThoughtsKey = "debug_lab_shift_thoughts"
    private let shiftFoundKey = "debug_lab_shift_found"
    
    
    // Daily Hints
    @Published var dailyFreeHintsUsed: Int = 0
    @Published var lastDailyReset: Date?
    
    // Keys for persistence
    private let attemptsKey = "debug_lab_attempts"
    private let completionKey = "debug_lab_completion"
    private let currentLevelKey = "debug_lab_current_level"
    private let coinsKey = "debug_lab_coins"
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
    private let usernameKey = "debug_lab_username"
    private let progressDataKey = "debug_lab_progress_data"
    
    // Multi-Language Progress Store
    @Published var progressData: [String: LanguageProgress] = [:]
    
    init() {
        self.levels = Question.levels
        loadProgress()
        setupInitialState()
        // Check streak on launch to see if it was broken
        // Check streak on launch to see if it was broken
        checkDailyStreakOnLaunch()
        checkDailyHintReset()
        debugUnlockAllLevels() // Enabled for testing
        // enforceStrictLevelLocks()
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
        
        // 3. Load new language state
        loadFromProgressData()
        
        // 4. Refresh content
        refreshQuestions()
        
        // 5. Persist the switch
        saveProgress()
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
    }
    
    func unlockThresholdReached(for levelIndex: Int) -> Bool {
        let level = levels[levelIndex]
        let completedInLevel = level.questions.filter { completedQuestionIds.contains($0.title) }.count
        return completedInLevel >= 15
    }
    

    
    func resetQuestionState(for question: Question) {
        lastEvaluationResult = nil
        executionState = .idle
        // Reset attempts for this question as requested
        attempts[question.title] = 0
    }

    // MARK: - Daily Streak Logic
    
    private func checkDailyStreakOnLaunch() {
        guard let lastDate = lastActiveDate else { return }
        
        let calendar = Calendar.current
        if calendar.isDateInYesterday(lastDate) {
            // Streak continues, do nothing until activity
        } else if calendar.isDateInToday(lastDate) {
            // Already active today
        } else {
            // Missed a day (or more), reset
            let difference = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if difference > 1 {
                dailyStreak = 0
            }
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
        let now = Date()
        let calendar = Calendar.current
        
        if let lastDate = lastActiveDate {
            if calendar.isDateInToday(lastDate) {
                // Already counted for today
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Consecutive day
                dailyStreak += 1
            } else {
                // Broken streak
                dailyStreak = 1
            }
        } else {
            // First time ever
            dailyStreak = 1
        }
        
        lastActiveDate = now
        saveProgress()
    }
    
    // MARK: - Gameplay Logic
    
    func runCode(userCode: String) {
        guard executionState != .running else { return }
        
        // Increment attempts
        attempts[currentQuestion.title, default: 0] += 1
        lifetimeAttempts += 1
        executionState = .running
        
        // Immediate execution on next run loop to allow UI update
        DispatchQueue.main.async {
            let result = CompilerEngine.shared.evaluate(code: userCode, for: self.currentQuestion)
            self.lastEvaluationResult = result
            
            if result.isSuccess {
                self.handleCorrectSubmission()
            } else {
                let errorMessage = result.message
                self.executionState = .error(errorMessage)
                // self.deductLife() // Removed
                self.streak = 0
                
                // Live Activity Failure
                Task { @MainActor in
                    LiveActivityManager.shared.endWithFailure(error: result.errorType?.rawValue ?? "Compilation Fail")
                }
                
                self.saveProgress()
            }
        }
    }
    
    private func handleCorrectSubmission() {
        // Only reward if not already completed
        if !completedQuestionIds.contains(currentQuestion.title) {
            completedQuestionIds.insert(currentQuestion.title)
            earnCoins(1)
            streak += 1
            registerActivity() // Update Daily Streak
            captureHistorySnapshot() // Capture progress for graph
            totalXP += 10 // Fixed XP per question
            
            // Contract: "Attempts reset only after correct solution"
            // We'll keep the history but maybe reset for display if re-entering? 
            // The requirement says "Reset Attempts". I will set it to 0.
            attempts[currentQuestion.title] = 0
            
            // Live Activity Success
            Task { @MainActor in
                LiveActivityManager.shared.endWithSuccess(xp: 50, coins: 5, streak: self.streak)
            }
            
            checkLevelUnlock()
        }
        
        executionState = .correct
        saveProgress()
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
    
    // MARK: - Coin System
    
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
    
    func earnCoins(_ amount: Int) {
        coinBalance += amount
        saveProgress()
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if coinBalance >= amount {
            coinBalance -= amount
            saveProgress()
            return true
        }
        return false
    }
    
    func unlockHint() {
        guard !unlockedHints.contains(currentQuestion.title) else { return }
        
        // Logic: 2 Free hints per day, then cost 5 coins
        if dailyFreeHintsUsed < 2 {
            dailyFreeHintsUsed += 1
            unlockedHints.insert(currentQuestion.title)
            saveProgress()
        } else {
            if spendCoins(5) {
                unlockedHints.insert(currentQuestion.title)
                saveProgress()
            }
        }
    }
    
    func revealSolution() {
        guard !revealedSolutions.contains(currentQuestion.title) else { return }
        
        if spendCoins(5) {
            revealedSolutions.insert(currentQuestion.title)
            // Also unlock the hint (Decrypted Concept) so the user understands the answer
            unlockedHints.insert(currentQuestion.title)
            saveProgress()
        }
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
        
        var totalCorrect = 0
        for (_, detail) in data.errorLines {
            totalCorrect += detail.options.filter { $0.isCorrect }.count
        }
        
        guard totalCorrect > 0 else { return 0 }
        
        let foundIds = shiftFoundOptionIds[question.title] ?? []
        // We only store found CORRECT option IDs, so count is enough
        // But to be safe, filter against the question's actual correct IDs
        let foundCount = foundIds.count 
        
        return Double(foundCount) / Double(totalCorrect)
    }
    
    func handleShiftCompletion(for question: Question) {
        if !completedQuestionIds.contains(question.title) {
            completedQuestionIds.insert(question.title)
            earnCoins(1)
            streak += 1
            registerActivity()
            totalXP += 10
            
            checkLevelUnlock()
            saveProgress()
            
            // Live Activity Success
            Task { @MainActor in
                LiveActivityManager.shared.endWithSuccess(xp: 50, coins: 5, streak: self.streak)
            }
        }
    }
    
    // MARK: - Progress State Management
    
    private func saveCurrentToProgressData() {
        let currentKey = selectedLanguage.rawValue
        var progress = progressData[currentKey] ?? LanguageProgress()
        
        progress.currentLevelIndex = currentLevelIndex
        progress.completedQuestionIds = completedQuestionIds
        progress.streak = streak
        progress.dailyStreak = dailyStreak
        progress.lastActiveDate = lastActiveDate
        progress.totalXP = totalXP
        progress.coinBalance = coinBalance
        progress.unlockedHints = unlockedHints
        progress.revealedSolutions = revealedSolutions
        progress.dailyFreeHintsUsed = dailyFreeHintsUsed
        progress.lastDailyReset = lastDailyReset
        progress.shiftFoundOptionIds = shiftFoundOptionIds
        progress.shiftThoughts = shiftThoughts
        progress.attempts = attempts
        progress.lifetimeAttempts = lifetimeAttempts
        progress.history = history
        
        // Unlocked Levels
        let unlockedSet = Set(levels.filter { $0.unlocked }.map { $0.number })
        progress.unlockedLevels = unlockedSet
        
        progressData[currentKey] = progress
    }
    
    private func loadFromProgressData() {
        let currentKey = selectedLanguage.rawValue
        let progress = progressData[currentKey] ?? LanguageProgress()
        
        // If it's a fresh language (empty progress), maybe give default coins?
        // LanguageProgress init already gives 10 coins.
        
        currentLevelIndex = progress.currentLevelIndex
        completedQuestionIds = progress.completedQuestionIds
        streak = progress.streak
        dailyStreak = progress.dailyStreak
        lastActiveDate = progress.lastActiveDate
        totalXP = progress.totalXP
        coinBalance = progress.coinBalance
        unlockedHints = progress.unlockedHints
        revealedSolutions = progress.revealedSolutions
        dailyFreeHintsUsed = progress.dailyFreeHintsUsed
        lastDailyReset = progress.lastDailyReset
        shiftThoughts = progress.shiftThoughts
        shiftFoundOptionIds = progress.shiftFoundOptionIds
        attempts = progress.attempts
        lifetimeAttempts = progress.lifetimeAttempts
        history = progress.history
        
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
    
    private func saveProgress() {
        // 1. Snapshot current state into the dictionary
        saveCurrentToProgressData()
        
        // 2. Persist the dictionary
        if let encoded = try? JSONEncoder().encode(progressData) {
            UserDefaults.standard.set(encoded, forKey: progressDataKey)
        }
        
        // 3. Persist global settings (shared)
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageKey)
        UserDefaults.standard.set(username, forKey: usernameKey)
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
        
        // 3. Apply to Published Properties
        loadFromProgressData()
        
        // 4. Ensure Content Matches Language
        refreshQuestions()
    }
    
    private func migrateLegacyData() {
        // Create a progress object based on legacy keys
        var legacy = LanguageProgress()
        
        if let val = UserDefaults.standard.dictionary(forKey: attemptsKey) as? [String: Int] { legacy.attempts = val }
        legacy.dailyFreeHintsUsed = UserDefaults.standard.integer(forKey: dailyHintsKey)
        if let t = UserDefaults.standard.object(forKey: lastDailyResetKey) as? TimeInterval { legacy.lastDailyReset = Date(timeIntervalSince1970: t) }
        if let ids = UserDefaults.standard.stringArray(forKey: completionKey) { legacy.completedQuestionIds = Set(ids) }
        legacy.currentLevelIndex = UserDefaults.standard.integer(forKey: currentLevelKey)
        legacy.coinBalance = UserDefaults.standard.integer(forKey: coinsKey)
        if legacy.coinBalance == 0 && UserDefaults.standard.object(forKey: coinsKey) == nil { legacy.coinBalance = 10 }
        
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
}
