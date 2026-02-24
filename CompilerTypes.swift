import Foundation

enum ProgrammingLanguage: String, CaseIterable, Identifiable {
    case swift = "Swift"
    case python = "Python"
    case cpp = "C++"
    case java = "Java"
    case c = "C"
    
    var id: String { rawValue }
    
    // Helper to map from existing Language enum if needed, though we can probably replace it or alias it.
    // For now, let's keep it aligned with the existing Language enum string values.
}

enum ErrorType: String, CaseIterable, Identifiable {
    case syntax = "Syntax Error"
    case logic = "Logic Error"
    case runtime = "Runtime Error"
    case missingStatement = "Missing Statement"
    case wrongOperator = "Wrong Operator"
    case compilation = "Compilation Error"
    case unknown = "Unknown Error"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .syntax: return "exclamationmark.triangle.fill"
        case .logic: return "brain.head.profile"
        case .runtime: return "ant.fill"
        case .missingStatement: return "text.badge.xmark"
        case .wrongOperator: return "plus.forwardslash.minus"
        case .compilation: return "hammer.fill"
        case .unknown: return "questionmark.diamond.fill"
        }
    }
}

// MARK: - Strict Evaluation Types

enum EvaluationStatus: String, Codable {
    case correct = "Correct"
    case incorrect = "Incorrect"
}

enum UserLevel: String, Codable {
    case failed = "Failed"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    case passed = "Passed"
    
    var color: String {
        switch self {
        case .failed: return "red"
        case .beginner: return "orange"
        case .intermediate: return "yellow"
        case .advanced: return "blue"
        case .expert: return "green"
        case .passed: return "green"
        }
    }
}

enum Complexity: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct TestCaseResult: Codable, Hashable {
    let input: String
    let expected: String
    let actual: String
    let passed: Bool
}

struct EvaluationResult: Codable {
    // QUESTION SCOPING
    let questionID: UUID
    
    // Legacy support (optional, can be computed from detailed result if needed)
    var isSuccess: Bool { status == .correct }
    var errorType: ErrorType? { status == .correct ? nil : .logic } // Simplified mapping
    
    // Strict Evaluation Fields
    let status: EvaluationStatus
    let score: Int
    let level: UserLevel
    let complexity: Complexity
    let edgeCaseHandling: Bool
    let hardcodingDetected: Bool
    var feedback: String
    var message: String { feedback }
    let line: Int?
    let difficulty: Int
    
    // Detailed Test Data
    var testResults: [TestCaseResult] = []
    
    // Adaptive Feedback Data
    var userSelectedOptionIndex: Int? = nil
    var userSelectedCategory: String? = nil
    
    // Rewards
    var coinsEarned: Int = 0
    var xpEarned: Int = 0
    
    init(questionID: UUID, status: EvaluationStatus, score: Int, level: UserLevel, complexity: Complexity, edgeCaseHandling: Bool, hardcodingDetected: Bool, feedback: String, line: Int? = nil, difficulty: Int = 1, testResults: [TestCaseResult] = [], coinsEarned: Int = 0, xpEarned: Int = 0, userSelectedOptionIndex: Int? = nil, userSelectedCategory: String? = nil) {
        self.questionID = questionID
        self.status = status
        self.score = score
        self.level = level
        self.complexity = complexity
        self.edgeCaseHandling = edgeCaseHandling
        self.hardcodingDetected = hardcodingDetected
        self.feedback = feedback
        self.line = line
        self.difficulty = difficulty
        self.testResults = testResults
        self.coinsEarned = coinsEarned
        self.xpEarned = xpEarned
        self.userSelectedOptionIndex = userSelectedOptionIndex
        self.userSelectedCategory = userSelectedCategory
    }
    
    // Helper for legacy simple errors
    static func simpleError(questionID: UUID, type: ErrorType, message: String, line: Int? = nil) -> EvaluationResult {
        return EvaluationResult(
            questionID: questionID,
            status: .incorrect,
            score: 0,
            level: .failed,
            complexity: .low,
            edgeCaseHandling: false,
            hardcodingDetected: false,
            feedback: "\(type.rawValue): \(message)",
            line: line,
            difficulty: 1
        )
    }
}
