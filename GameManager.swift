import SwiftUI
import Combine

// 1️⃣ GameLanguage
enum GameLanguage: String, CaseIterable, Codable, Hashable {
    case c
    case swift
    
    init(from language: Language) {
        switch language {
        case .c: self = .c
        case .swift: self = .swift
        default: self = .swift
        }
    }
}

// 2️⃣ GameLevel
enum GameLevel: Int, CaseIterable, Codable, Hashable {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    
    init(fromIndex index: Int) {
        self = GameLevel(rawValue: index + 1) ?? .level1
    }
}

// 3️⃣ GameModeKey
struct GameModeKey: Hashable, Codable {
    let language: GameLanguage
    let level: GameLevel
    let isShiftMode: Bool
}

// 4️⃣ ProgressData
struct ProgressData: Codable {
    var completed: Int = 0
    var completedIds: Set<String> = []
    var correct: Int = 0
    var total: Int = 0
    var xp: Int = 0
    var history: [HistoryEntry] = []
    var attempts: [String: Int] = [:]
    
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return (Double(correct) / Double(total)) * 100
    }
}

@MainActor
class GameManager: ObservableObject {
    enum ExecutionState: Equatable {
        case idle
        case running
        case correct
        case error(String)
        case levelComplete(Int, Bool)
        
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
    @Published var currentLevelIndex: Int = 0 {
        didSet { updateIsolatedBridges() }
    }
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedLanguage: Language = .swift {
        didSet { 
            Theme.selectedLanguage = selectedLanguage
            refreshQuestions() 
            updateIsolatedBridges()
        }
    }
    @Published var username: String = "Student Developer"
    
    // Game State
    @Published var executionState: ExecutionState = .idle
    @Published var lastEvaluationResult: EvaluationResult?
    @Published var attempts: [String: Int] = [:]
    
    // ISOLATED BRIDGES (These are updated based on the current mode)
    @Published var completedQuestionIds: Set<String> = []
    @Published var currentXP: Int = 0
    @Published var currentAccuracy: Double = 0
    @Published var currentCompleted: Int = 0
    
    // Global Stats
    @Published var currentStreak: Int = 0
    @Published var totalXP: Int = 0
    @Published var lifetimeAttempts: Int = 0
    @Published var history: [HistoryEntry] = []
    @Published var lastCompletedDate: Date?
    @Published var longestStreak: Int = 0
    @Published var unlockedLevels: Set<String> = []
    @Published var showStreakResetNotification: Bool = false
    @Published var streakResetMessage: String?
    
    // UI & Flags
    @Published var isTestingMode: Bool = false
    @Published var onboardingCompleted: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var onboardingStep: Int = 0
    @Published var levelOnboardingCompleted: Bool = false
    @Published var showLevelOnboarding: Bool = false
    @Published var levelOnboardingStep: Int = 0
    @Published var isDarkMode: Bool = false {
        didSet { Theme.isDarkMode = isDarkMode }
    }
    
    // Shift Data
    @Published var isShiftMode: Bool = false {
        didSet { updateIsolatedBridges() }
    }
    @Published var shiftFoundOptionIds: [String: Set<UUID>] = [:]
    
    // Hint System
    @Published var unlockedHints: Set<String> = []
    @Published var revealedSolutions: Set<String> = []
    @Published var shiftThoughts: [String: String] = [:]
    
    // ISOLATED STORAGE
    @Published private var progressStorage: [GameModeKey: ProgressData] = [:]
    
    private let progressDataKey = "debug_lab_isolated_progress_v6"
    
    init() {
        self.levels = Question.levels
        populateQuestionMetadata()
        loadProgress()
        Theme.isDarkMode = self.isDarkMode
        Theme.selectedLanguage = self.selectedLanguage
        
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: "debug_lab_onboarding_completed")
        self.levelOnboardingCompleted = UserDefaults.standard.bool(forKey: "debug_lab_level_onboarding_completed")

        if !onboardingCompleted {
            self.showOnboarding = true
        } else if !levelOnboardingCompleted {
            self.showLevelOnboarding = true
        }
        
        setupInitialState()
        if isTestingMode { unlockAllLevelsInternal() }
        updateIsolatedBridges()
    }
    
    // MARK: - Isolation Logic
    
    private var currentKey: GameModeKey {
        GameModeKey(
            language: GameLanguage(from: selectedLanguage),
            level: GameLevel(fromIndex: currentLevelIndex),
            isShiftMode: currentQuestion.shiftData != nil || isShiftMode
        )
    }
    
    private func getProgress() -> ProgressData {
        progressStorage[currentKey] ?? ProgressData()
    }
    
    private func setProgress(_ data: ProgressData) {
        progressStorage[currentKey] = data
        updateIsolatedBridges()
        saveProgress()
    }
    
    private func updateIsolatedBridges() {
        let data = getProgress()
        self.completedQuestionIds = data.completedIds
        self.currentXP = data.xp
        self.currentAccuracy = data.accuracy
        self.currentCompleted = data.completed
        self.attempts = data.attempts
        
        // Update global XP as aggregate
        self.totalXP = progressStorage.values.reduce(0) { $0 + $1.xp }
    }
    
    func recordAnswer(correct: Bool) {
        var data = getProgress()
        data.total += 1
        if correct {
            data.correct += 1
            data.completed += 1
            data.xp += 10
        }
        
        // Record to history for both success and failure to update graph accuracy
        let entry = HistoryEntry(date: Date(), xp: data.xp, solvedCount: data.completed, accuracy: data.accuracy)
        data.history.append(entry)
        
        // Update Daily Streak (Calendar-based, once per day)
        updateDailyStreak()
        
        setProgress(data)
    }
    
    private func updateDailyStreak() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        guard let lastDate = lastCompletedDate else {
            // First time completing a challenge
            currentStreak = 1
            lastCompletedDate = today
            longestStreak = max(longestStreak, currentStreak)
            saveProgress()
            return
        }
        
        let normalizedLastDate = calendar.startOfDay(for: lastDate)
        
        if calendar.isDate(normalizedLastDate, inSameDayAs: today) {
            // Already interacted today, do nothing to streak count
            return
        }
        
        // Check if last interaction was exactly yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(normalizedLastDate, inSameDayAs: yesterday) {
            currentStreak += 1
        } else {
            // Gap of one or more days
            currentStreak = 1
        }
        
        lastCompletedDate = today
        longestStreak = max(longestStreak, currentStreak)
        saveProgress()
    }
    
    // MARK: - Report Aggregates
    
    func getLanguageXP(for lang: String) -> Int {
        let gameLang = lang.lowercased() == "swift" ? GameLanguage.swift : GameLanguage.c
        return progressStorage.filter { $0.key.language == gameLang }.reduce(0) { $0 + $1.value.xp }
    }
    
    func getLanguageSolvedCount(for lang: String) -> Int {
        let gameLang = lang.lowercased() == "swift" ? GameLanguage.swift : GameLanguage.c
        let allIds = progressStorage.filter { $0.key.language == gameLang }.map { $0.value.completedIds }
        var uniqueIds = Set<String>()
        for ids in allIds { uniqueIds.formUnion(ids) }
        return uniqueIds.count
    }
    
    func getLanguageAccuracy(for lang: String) -> Double {
        let gameLang = lang.lowercased() == "swift" ? GameLanguage.swift : GameLanguage.c
        let items = progressStorage.filter { $0.key.language == gameLang }.map { $0.value }
        let total = items.reduce(0) { $0 + $1.total }
        let correct = items.reduce(0) { $0 + $1.correct }
        guard total > 0 else { return 0 }
        return (Double(correct) / Double(total)) * 100
    }
    
    func getLanguageHistory(for lang: String) -> [Double] {
        let gameLang = lang.lowercased() == "swift" ? GameLanguage.swift : GameLanguage.c
        let key = GameModeKey(
            language: gameLang,
            level: GameLevel(fromIndex: currentLevelIndex),
            isShiftMode: isShiftMode
        )
        return progressStorage[key]?.history.map { $0.accuracy } ?? []
    }
    
    // MARK: - App logic
    
    func selectLevel(_ index: Int) {
        if index < levels.count && levels[index].unlocked {
            currentLevelIndex = index
        }
    }
    
    func selectLanguage(_ language: Language) {
        selectedLanguage = language
    }
    
    func refreshQuestions() {
        self.levels = Question.levels(for: selectedLanguage)
        syncLevelUnlockState()
        if isTestingMode { unlockAllLevelsInternal() }
        populateQuestionMetadata()
    }
    
    private func syncLevelUnlockState() {
        for i in 0..<levels.count {
            let key = "\(selectedLanguage.rawValue)_\(levels[i].number)"
            if unlockedLevels.contains(key) {
                levels[i].unlocked = true
            }
        }
    }
    
    func resetQuestionState(for question: Question) {
        lastEvaluationResult = nil
        executionState = .idle
    }
    
    func questionsRequiredForNextLevel(levelIndex: Int) -> Int {
        guard levels.indices.contains(levelIndex) else { return 0 }
        
        // Use the actual count of questions as the threshold for Level 1 and 2
        // while maintaining specific logic for others if needed.
        return levels[levelIndex].questions.count
    }
    
    func unlockThresholdReached(for levelIndex: Int) -> Bool {
        levelProgress(for: levelIndex) >= questionsRequiredForNextLevel(levelIndex: levelIndex)
    }
    
    func levelProgress(for index: Int) -> Int {
        guard index < levels.count else { return 0 }
        let key = GameModeKey(
            language: GameLanguage(from: selectedLanguage),
            level: GameLevel(fromIndex: index),
            isShiftMode: isShiftMode
        )
        return progressStorage[key]?.completedIds.count ?? 0
    }
    
    // MARK: - Gameplay Logic
    
    func runCode(userCode: String) {
        guard executionState != .running else { return }
        attempts[currentQuestion.title, default: 0] += 1
        lifetimeAttempts += 1
        executionState = .running
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let result = CompilerEngine.shared.evaluate(code: userCode, for: self.currentQuestion, attempts: self.attempts[self.currentQuestion.title, default: 0])
            self.lastEvaluationResult = result
            if result.isSuccess {
                self.recordAnswer(correct: true)
                self.handleCorrectSubmission()
            } else {
                self.recordAnswer(correct: false)
                self.executionState = .error(result.message)
                self.saveProgress()
            }
        }
    }
    
    private func handleCorrectSubmission() {
        var data = getProgress()
        if !data.completedIds.contains(currentQuestion.title) {
            data.completedIds.insert(currentQuestion.title)
        }
        setProgress(data)
        checkLevelUnlock()
        executionState = .correct
    }
    
    func markShiftOptionFound(questionTitle: String, optionId: UUID) {
        if shiftFoundOptionIds[questionTitle] == nil {
            shiftFoundOptionIds[questionTitle] = []
        }
        shiftFoundOptionIds[questionTitle]?.insert(optionId)
        saveProgress()
    }
    
    func getShiftProgress(for question: Question) -> Double {
        guard let data = question.shiftData else { return 0 }
        let found = shiftFoundOptionIds[question.title]?.count ?? 0
        let total = data.errorLines.values.reduce(0) { $0 + $1.options.filter { $0.isCorrect }.count }
        return total > 0 ? Double(found) / Double(total) : 0
    }
    
    func handleShiftCompletion(for question: Question) {
        handleCorrectSubmission()
    }

    private func checkLevelUnlock() {
        let completedInLevel = levelProgress(for: currentLevelIndex)
        let nextIdx = currentLevelIndex + 1
        guard nextIdx < levels.count else { return }
        
        let threshold = questionsRequiredForNextLevel(levelIndex: currentLevelIndex)
        if completedInLevel >= threshold {
            let nextLevelNumber = levels[nextIdx].number
            let key = "\(selectedLanguage.rawValue)_\(nextLevelNumber)"
            if !unlockedLevels.contains(key) {
                unlockedLevels.insert(key)
                syncLevelUnlockState()
                executionState = .levelComplete(nextLevelNumber, false)
                saveProgress()
            }
        }
    }
    
    // MARK: - Onboarding & UI
    
    func updateUsername(_ name: String) {
        username = name
        saveProgress()
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: "debug_lab_onboarding_completed")
        
        // Chain to level onboarding if needed
        if !levelOnboardingCompleted {
            showLevelOnboarding = true
        }
        
        saveProgress()
    }
    
    func completeLevelOnboarding() {
        levelOnboardingCompleted = true
        showLevelOnboarding = false
        UserDefaults.standard.set(true, forKey: "debug_lab_level_onboarding_completed")
        saveProgress()
    }
    
    func replayOnboarding() {
        onboardingStep = 0
        showOnboarding = true
    }
    
    func replayLevelOnboarding() {
        levelOnboardingStep = 0
        showLevelOnboarding = true
    }
    
    func unlockHint() { unlockedHints.insert(currentQuestion.title); saveProgress() }
    func unlockHintWithGenreQuiz() { unlockHint() }
    func getGenreQuestions(for genre: Genre) -> [GenreQuestion] { Question.genreQuestions.filter { $0.genre == genre } }
    
    // MARK: - Persistence
    
    func saveProgress() {
        if let data = try? JSONEncoder().encode(progressStorage) { UserDefaults.standard.set(data, forKey: progressDataKey) }
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "debug_lab_lang_v6")
        UserDefaults.standard.set(username, forKey: "debug_lab_user_v6")
        UserDefaults.standard.set(currentLevelIndex, forKey: "debug_lab_lvl_v6")
        UserDefaults.standard.set(currentStreak, forKey: "debug_lab_streak_v6")
        UserDefaults.standard.set(longestStreak, forKey: "debug_lab_longest_streak_v6")
        UserDefaults.standard.set(lastCompletedDate, forKey: "debug_lab_last_date_v6")
        UserDefaults.standard.set(isDarkMode, forKey: "debug_lab_dark_v6")
        UserDefaults.standard.set(Array(unlockedLevels), forKey: "debug_lab_unlocked_levels_v6")
        if let data = try? JSONEncoder().encode(shiftFoundOptionIds) { UserDefaults.standard.set(data, forKey: "debug_lab_shift_v6") }
    }
    
    func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressDataKey), let decoded = try? JSONDecoder().decode([GameModeKey: ProgressData].self, from: data) { progressStorage = decoded }
        if let lang = UserDefaults.standard.string(forKey: "debug_lab_lang_v6"), let l = Language(rawValue: lang) { selectedLanguage = l }
        currentLevelIndex = UserDefaults.standard.integer(forKey: "debug_lab_lvl_v6")
        currentStreak = UserDefaults.standard.integer(forKey: "debug_lab_streak_v6")
        longestStreak = UserDefaults.standard.integer(forKey: "debug_lab_longest_streak_v6")
        lastCompletedDate = UserDefaults.standard.object(forKey: "debug_lab_last_date_v6") as? Date
        isDarkMode = UserDefaults.standard.bool(forKey: "debug_lab_dark_v6")
        if let unlocked = UserDefaults.standard.stringArray(forKey: "debug_lab_unlocked_levels_v6") { unlockedLevels = Set(unlocked) }
        if let data = UserDefaults.standard.data(forKey: "debug_lab_shift_v6"), let decoded = try? JSONDecoder().decode([String: Set<UUID>].self, from: data) { shiftFoundOptionIds = decoded }
        refreshQuestions()
    }
    
    private func setupInitialState() {
        // Automatically unlock level 1 for all languages
        for lang in Language.allCases {
            unlockedLevels.insert("\(lang.rawValue)_1")
        }
        syncLevelUnlockState()
    }
    
    private func populateQuestionMetadata() {
        for lIdx in 0..<levels.count {
            for qIdx in 0..<levels[lIdx].questions.count {
                levels[lIdx].questions[qIdx].levelNumber = levels[lIdx].number
                levels[lIdx].questions[qIdx].questionNumber = qIdx + 1
            }
        }
    }
    
    private func unlockAllLevelsInternal() {
        for i in 0..<levels.count { levels[i].unlocked = true }
    }
    
    var currentLevel: Level {
        levels.indices.contains(currentLevelIndex) ? levels[currentLevelIndex] : Level(number: 1, title: "", description: "", questions: [], unlocked: true)
    }
    
    var currentQuestion: Question {
        currentLevel.questions.indices.contains(currentQuestionIndex) ? currentLevel.questions[currentQuestionIndex] : Question(title: "", description: "", initialCode: "", correctCode: "", difficulty: 1, riddle: "", conceptExplanation: "")
    }
}
