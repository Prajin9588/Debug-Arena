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

struct EvaluationResult {
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
    let feedback: String
    let message: String // Kept for compatibility, aliases to feedback
    let line: Int?
    
    init(status: EvaluationStatus, score: Int, level: UserLevel, complexity: Complexity, edgeCaseHandling: Bool, hardcodingDetected: Bool, feedback: String, line: Int? = nil) {
        self.status = status
        self.score = score
        self.level = level
        self.complexity = complexity
        self.edgeCaseHandling = edgeCaseHandling
        self.hardcodingDetected = hardcodingDetected
        self.feedback = feedback
        self.message = feedback
        self.line = line
    }
    
    // Helper for legacy simple errors
    static func simpleError(type: ErrorType, message: String, line: Int? = nil) -> EvaluationResult {
        return EvaluationResult(
            status: .incorrect,
            score: 0,
            level: .failed,
            complexity: .low,
            edgeCaseHandling: false,
            hardcodingDetected: false,
            feedback: "\(type.rawValue): \(message)",
            line: line
        )
    }
}
