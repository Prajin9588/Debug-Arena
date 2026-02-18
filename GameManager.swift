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
    
    // Premium Features
    @Published var coinBalance: Int = 10 // Starting bonus
    @Published var unlockedHints: Set<String> = []
    @Published var revealedSolutions: Set<String> = []
    
    
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
    
    init() {
        self.levels = Question.levels
        loadProgress()
        setupInitialState()
        // Check streak on launch to see if it was broken
        // Check streak on launch to see if it was broken
        checkDailyStreakOnLaunch()
        checkDailyHintReset()
        // debugUnlockAllLevels() // Removed for strict locking
        enforceStrictLevelLocks()
    }
    
    private func debugUnlockAllLevels() {
        for i in 0..<levels.count {
            levels[i].unlocked = true
        }
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
        selectedLanguage = language
        refreshQuestions()
        // Ready to enter Dashboard
    }
    
    private func refreshQuestions() {
        let updatedLevels = Question.levels(for: selectedLanguage)
        // Preserve unlock status when switching? 
        // Actually, the requirement implies level 1 is shared or at least unlocked by default.
        // Let's preserve the 'unlocked' state for each level index.
        for i in 0..<levels.count {
            if i < updatedLevels.count {
                var newLevel = updatedLevels[i]
                newLevel.unlocked = levels[i].unlocked
                levels[i] = newLevel
            }
        }
    }
    
    func unlockThresholdReached(for levelIndex: Int) -> Bool {
        let level = levels[levelIndex]
        let completedInLevel = level.questions.filter { completedQuestionIds.contains($0.title) }.count
        return completedInLevel >= 15
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
    
    private func checkLevelUnlock() {
        let completedCount = levelProgress(for: currentLevelIndex)
        let nextLevelIndex = currentLevelIndex + 1
        
        guard nextLevelIndex < levels.count else { return }
        
        // Strict Locking: Must complete ALL questions in the current level
        let threshold = levels[currentLevelIndex].totalQuestions
        
        if completedCount >= threshold {
            if !levels[nextLevelIndex].unlocked {
                levels[nextLevelIndex].unlocked = true
                executionState = .levelComplete(nextLevelIndex + 1, false) // Notify user
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
    
    // MARK: - Persistence
    
    private func saveProgress() {
        // Attempts
        UserDefaults.standard.set(attempts, forKey: attemptsKey)
        
        // Completion
        let completionIds = Array(completedQuestionIds)
        UserDefaults.standard.set(completionIds, forKey: completionKey)
        
        // Current Level
        UserDefaults.standard.set(currentLevelIndex, forKey: currentLevelKey)
        
        // Coins
        UserDefaults.standard.set(coinBalance, forKey: coinsKey)
        
        // Gamification
        UserDefaults.standard.set(streak, forKey: "debug_lab_streak")
        UserDefaults.standard.set(dailyStreak, forKey: dailyStreakKey)
        UserDefaults.standard.set(streak, forKey: "debug_lab_streak")
        UserDefaults.standard.set(dailyStreak, forKey: dailyStreakKey)
        UserDefaults.standard.set(lastActiveDate?.timeIntervalSince1970, forKey: lastActiveDateKey)
        UserDefaults.standard.set(totalXP, forKey: "debug_lab_total_xp")
        
        // Hints
        UserDefaults.standard.set(dailyFreeHintsUsed, forKey: dailyHintsKey)
        UserDefaults.standard.set(lastDailyReset?.timeIntervalSince1970, forKey: lastDailyResetKey)
        
        // Hints Data
        let hintsData = Array(unlockedHints)
        UserDefaults.standard.set(hintsData, forKey: hintsKey)
        
        // Solutions
        let solutionsData = Array(revealedSolutions)
        UserDefaults.standard.set(solutionsData, forKey: solutionsKey)
        
        // Unlocked Levels
        let unlockedLevels = levels.filter { $0.unlocked }.map { $0.number }
        UserDefaults.standard.set(unlockedLevels, forKey: unlockedLevelsKey)
        
        // Language
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageKey)
        
        // Username
        UserDefaults.standard.set(username, forKey: usernameKey)
    }
    private func loadProgress() {
        if let attemptsData = UserDefaults.standard.dictionary(forKey: attemptsKey) as? [String: Int] {
            attempts = attemptsData
        }
        
        dailyFreeHintsUsed = UserDefaults.standard.integer(forKey: dailyHintsKey)
        if let resetTime = UserDefaults.standard.object(forKey: lastDailyResetKey) as? TimeInterval {
            lastDailyReset = Date(timeIntervalSince1970: resetTime)
        }
        
        if let completionIds = UserDefaults.standard.stringArray(forKey: completionKey) {
            completedQuestionIds = Set(completionIds)
        }
        
        currentLevelIndex = UserDefaults.standard.integer(forKey: currentLevelKey)
        coinBalance = UserDefaults.standard.integer(forKey: coinsKey)
        if coinBalance == 0 && UserDefaults.standard.object(forKey: coinsKey) == nil {
            coinBalance = 10 // Default if not set
        }
        
        if let hintsData = UserDefaults.standard.stringArray(forKey: hintsKey) {
            unlockedHints = Set(hintsData)
        }
        
        if let solutionsData = UserDefaults.standard.stringArray(forKey: solutionsKey) {
            revealedSolutions = Set(solutionsData)
        }
        
        if let unlockedLevels = UserDefaults.standard.array(forKey: unlockedLevelsKey) as? [Int] {
            for i in 0..<levels.count {
                if unlockedLevels.contains(levels[i].number) {
                    levels[i].unlocked = true
                }
            }
        }
        if let languageRaw = UserDefaults.standard.string(forKey: languageKey),
           let language = Language(rawValue: languageRaw) {
            selectedLanguage = language
            refreshQuestions()
        }
        
        if let savedUsername = UserDefaults.standard.string(forKey: usernameKey) {
            username = savedUsername
        }
        
        streak = UserDefaults.standard.integer(forKey: "debug_lab_streak")
        dailyStreak = UserDefaults.standard.integer(forKey: dailyStreakKey)
        if let lastActiveTime = UserDefaults.standard.object(forKey: lastActiveDateKey) as? TimeInterval {
            lastActiveDate = Date(timeIntervalSince1970: lastActiveTime)
        }
        totalXP = UserDefaults.standard.integer(forKey: "debug_lab_total_xp")
    }
    
    private func setupInitialState() {
        if !levels.isEmpty {
            levels[0].unlocked = true
        }
    }
}
