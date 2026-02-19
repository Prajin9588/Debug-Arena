import Foundation

struct LanguageProgress: Codable {
    var currentLevelIndex: Int = 0
    var completedQuestionIds: Set<String> = []
    
    // Gamification
    var streak: Int = 0
    var dailyStreak: Int = 0
    var lastActiveDate: Date?
    var totalXP: Int = 0
    
    // Economics
    var coinBalance: Int = 10
    
    // Hints & Solutions
    var unlockedHints: Set<String> = []
    var revealedSolutions: Set<String> = []
    var dailyFreeHintsUsed: Int = 0
    var lastDailyReset: Date?
    
    // Shift Mode
    var shiftThoughts: [String: String] = [:]
    var shiftFoundOptionIds: [String: Set<UUID>] = [:]
    
    // Meta
    var attempts: [String: Int] = [:]
    var unlockedLevels: Set<Int> = [1]
}
