import Foundation

enum Language: String, CaseIterable, Identifiable {
    case swift = "Swift"
    case python = "Python"
    case cpp = "C++"
    case java = "Java"
    case c = "C"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .swift: return "swift"
        case .python: return "desktopcomputer"
        case .cpp: return "cpu"
        case .java: return "cup.and.saucer.fill"
        case .c: return "terminal"
        }
    }
}

enum Genre: String, CaseIterable, Identifiable {
    case cricket = "Cricket"
    case football = "Football"
    case anime = "Anime"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .cricket: return "figure.cricket"
        case .football: return "figure.soccer"
        case .anime: return "sparkles"
        }
    }
}

struct GenreQuestion: Identifiable {
    let id: UUID = UUID()
    let text: String
    let options: [String]
    let correctAnswerIndex: Int
    let genre: Genre
}

struct HiddenTestCase: Codable, Equatable {
    let input: String
    let expectedOutput: String
}

// MARK: - Shift Game Mode Models
struct ShiftOption: Codable, Equatable, Hashable {
    let id: UUID
    let text: String
    let explanation: String
    let isCorrect: Bool
    
    init(text: String, explanation: String, isCorrect: Bool) {
        // Use a deterministic UUID based on the text to ensure persistence matches across app launches
        let hashString = text.lowercased().trimmingCharacters(in: .whitespaces)
        var hash = UInt64(5381)
        for byte in hashString.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        let uuidString = String(format: "550e8400-e29b-41d4-a716-%012llx", hash)
        self.id = UUID(uuidString: uuidString) ?? UUID()
        
        self.text = text
        self.explanation = explanation
        self.isCorrect = isCorrect
    }
}

struct ShiftLineDetail: Codable, Equatable, Hashable {
    let lineNumber: Int
    let options: [ShiftOption]
}

struct ShiftData: Codable, Equatable {
    let code: String
    let errorLines: [Int: ShiftLineDetail] // Line Number -> Detail
}

enum QuestionCategory: String, Codable, CaseIterable {
    case type = "Type System"
    case pointer = "Memory Reference"
    case memory = "Memory Safety"
    case logic = "Logical Condition"
    case boundary = "Boundary Logic"
    case structure = "Code Structure"
    case unknown = "General"
}

struct Question: Identifiable, Equatable {
    let id: UUID
    let title: String // e.g., "Level 1 – Question 18"
    let description: String
    let initialCode: String
    let correctCode: String // For validation
    let difficulty: Int
    var levelNumber: Int
    var questionNumber: Int
    let category: QuestionCategory
    
    // Hint System
    let riddle: String // "Riddle must hint toward the fix"
    let conceptExplanation: String // "Answer must reveal the concept"
    
    // Concept Check System
    let conceptQuestion: String
    let conceptOptions: [String]
    let conceptCorrectAnswer: Int // Index of correct option
    let conceptOptionsExplanations: [String]? // Explanations for each option
    
    // New validation fields
    let hiddenTests: [HiddenTestCase]? 
    let brokenCode: String?
    
    // Shift Mode Data
    let shiftData: ShiftData?
    
    // Optional additional context
    let storyFragment: String?

    // Compiler Engine Fields
    let language: Language
    let expectedPatterns: [String]
    let forbiddenPatterns: [String]
    let expectedErrorType: ErrorType?
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String, 
         initialCode: String, 
         correctCode: String, 
         difficulty: Int, 
         riddle: String, 
         conceptExplanation: String,
         levelNumber: Int = 1,
         questionNumber: Int = 1,
         conceptQuestion: String? = nil,
         conceptOptions conceptOptionsParam: [String]? = nil,
         conceptCorrectAnswer conceptCorrectAnswerParam: Int? = 0,
         conceptOptionsExplanations conceptOptionsExplanationsParam: [String]? = nil,
         storyFragment: String? = nil,
         language: Language = .python,
         expectedPatterns: [String] = [],
         forbiddenPatterns: [String] = [],
         expectedErrorType: ErrorType? = nil,
         hiddenTests: [HiddenTestCase]? = nil,
         brokenCode: String? = nil,
         shiftData: ShiftData? = nil,
         category: QuestionCategory = .unknown) {
        self.id = id
        self.title = title
        self.description = description
        self.initialCode = initialCode
        self.correctCode = correctCode
        self.difficulty = difficulty
        self.riddle = riddle
        self.conceptExplanation = conceptExplanation
        self.levelNumber = levelNumber
        self.questionNumber = questionNumber
        self.category = category
        
        // Default values if not provided (to avoid breaking existing data)
        self.conceptQuestion = conceptQuestion ?? "What is the primary concept involved in this bug?"
        self.conceptOptions = conceptOptionsParam ?? ["Syntax Error", "Logic Error", "Runtime Error", "Type Error"]
        self.conceptCorrectAnswer = conceptCorrectAnswerParam ?? 0
        self.conceptOptionsExplanations = conceptOptionsExplanationsParam
        
        self.storyFragment = storyFragment
        self.language = language
        
        self.expectedPatterns = expectedPatterns
        self.forbiddenPatterns = forbiddenPatterns
        self.expectedErrorType = expectedErrorType
        self.hiddenTests = hiddenTests
        self.brokenCode = brokenCode
        self.shiftData = shiftData
    }
    
    func validate(userCode: String) -> Bool {
        return userCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == correctCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    // Audit check for missing expected output
    var isMissingExpectedOutput: Bool {
        guard let tests = hiddenTests, !tests.isEmpty else { return true }
        return tests.first?.expectedOutput.isEmpty ?? true
    }
}

struct Level: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
    var questions: [Question]
    var unlocked: Bool
    
    // Computed property for progress tracking (handled in GameManager mainly, but helpful here)
    var totalQuestions: Int { questions.count }
}

// Data Population
extension Question {
    static func levels(for language: Language) -> [Level] {
        return [
            Level(
                number: 1,
                title: "Level 1: Rookie Coder",
                description: language == .cpp || language == .java || language == .c ? "Master the fundamentals of \(language.rawValue) syntax and logic." : (language == .swift ? "Learn the fundamentals of Swift syntax and logic." : "Master the fundamentals of Python syntax and logic."),
                questions: generateLevel1Questions(for: language),
                unlocked: true
            ),
            Level(
                number: 2,
                title: "Level 2: Logic Apprentice",
                description: "Master runtime safety. Fix crashes like index out of range and nil unwrapping.",
                questions: generateLevel2Questions(for: language),
                unlocked: false
            ),
            Level(
                number: 3,
                title: "Level 3: Code Detective",
                description: "Find subtle logic errors. The code runs, but the result is wrong.",
                questions: generateLevel3Questions(for: language),
                unlocked: false
            ),
            Level(
                number: 4,
                title: "Level 4: Algorithm Architect",
                description: "Fix algorithmic bugs in searching, sorting, and recursion.",
                questions: generateLevel4Questions(for: language),
                unlocked: false
            )
        ]
    }

    // Keep legacy levels property but make it dynamic or empty?
    // Let's make it computed or just update GameManager to use the function.
    static var levels: [Level] {
        return levels(for: .swift) // Default
    }

    private static func generateLevel3Questions(for language: Language) -> [Question] {
        var questions: [Question] = []
        
        if language == .swift {
        // Q1 — Simple Addition Error
        questions.append(Question(
            title: "Level 3 – Question 1",
            description: "Simple Addition Error",
            initialCode: "func add(_ a: Int, _ b: Int) -> Int {\n    let result = a + b\n    return result\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Review the logic carefully.",
            conceptExplanation: "Shift the focus to the correct logic.",
            language: .swift,
            shiftData: ShiftData(
                code: "func add(_ a: Int, _ b: Int) -> Int {\n    let result = a + b\n    return result\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Sum may miscalculate if variables not as expected; correct option.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Addition logic might fail with edge cases.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Swift syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Variables safely initialized; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Returning wrong value may occur if previous line miscomputed.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Not applicable here; educationally highlights concept; correct option.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Return syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))
        
        // Q2 — Factorial Function
        questions.append(Question(
            title: "Level 3 – Question 2",
            description: "Factorial Function",
            initialCode: "func factorial(_ n: Int) -> Int {\n    if n == 0 { return 1 }\n    return n * factorial(n - 1)\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Recursion must end somewhere.",
            conceptExplanation: "Base cases are critical.",
            language: .swift,
            shiftData: ShiftData(
                code: "func factorial(_ n: Int) -> Int {\n    if n == 0 { return 1 }\n    return n * factorial(n - 1)\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Base case trap", explanation: "Stops recursion correctly; essential for function correctness.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Condition correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Base case exists; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Recursive multiplication may overflow; educationally important.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Recursion terminates properly; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Recursion assumes n > 0; highlights correct logic.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Return syntax valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))
        
        // Q3 — Fibonacci Sequence
        questions.append(Question(
            title: "Level 3 – Question 3",
            description: "Fibonacci Sequence",
            initialCode: "func fib(_ n: Int) -> Int {\n    if n <= 1 { return n }\n    return fib(n - 1) + fib(n - 2)\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Growth is exponential.",
            conceptExplanation: "Recursion performance pitfalls.",
            language: .swift,
            shiftData: ShiftData(
                code: "func fib(_ n: Int) -> Int {\n    if n <= 1 { return n }\n    return fib(n - 1) + fib(n - 2)\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Base case trap", explanation: "Stops recursion for n = 0 or 1; key concept.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Condition correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Incorrect base case can break function; educational point.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Recursive sum may be expensive; highlight recursion understanding.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Base case prevents infinite recursion; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Performance concern; educational insight.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Return syntax valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))
        

        // Q4 — Reverse String
        questions.append(Question(
            title: "Level 3 – Question 4",
            description: "Reverse String",
            initialCode: "func reverse(_ str: String) -> String {\n    var chars = Array(str)\n    var left = 0, right = chars.count - 1\n    while left < right {\n        chars.swapAt(left, right)\n        left += 1\n        right -= 1\n    }\n    return String(chars)\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Mirror, Mirror.",
            conceptExplanation: "Pointers moving inwards.",
            language: .swift,
            shiftData: ShiftData(
                code: "func reverse(_ str: String) -> String {\n    var chars = Array(str)\n    var left = 0, right = chars.count - 1\n    while left < right {\n        chars.swapAt(left, right)\n        left += 1\n        right -= 1\n    }\n    return String(chars)\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Conversion correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Must convert to array for mutability; educational point.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid Swift syntax; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Safe array; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Right index last element; avoids out-of-bounds; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Misalignment breaks reversal; educational highlight.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Declaration valid; distractor.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Stops when left >= right; correct.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Loop terminates; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Incorrect condition may skip middle; educational.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Swap mechanics correct; educational.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Indices valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "SwapAt syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Misuse breaks reversal; correct educational insight.", isCorrect: true)
                    ])
                ]
            )
        ))

        // Q5 — Merge Two Sorted Arrays
        questions.append(Question(
            title: "Level 3 – Question 5",
            description: "Merge Two Sorted Arrays",
            initialCode: "func merge(a: [Int], b: [Int]) -> [Int] {\n    var result: [Int] = []\n    var i = 0, j = 0\n    while i < a.count || j < b.count {\n        if a[i] < b[j] { result.append(a[i]); i += 1 } \n        else { result.append(b[j]); j += 1 }\n    }\n    return result\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Two lines becoming one.",
            conceptExplanation: "Merging logic requires careful indexing.",
            language: .swift,
            shiftData: ShiftData(
                code: "func merge(a: [Int], b: [Int]) -> [Int] {\n    var result: [Int] = []\n    var i = 0, j = 0\n    while i < a.count || j < b.count {\n        if a[i] < b[j] { result.append(a[i]); i += 1 } \n        else { result.append(b[j]); j += 1 }\n    }\n    return result\n}",
                errorLines: [
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Infinite loop", explanation: "Using || may never terminate if one array still has elements.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "i/j may go out-of-bounds; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Condition syntax correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "May index beyond array; correct.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "No optionals involved; distractor.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Loop not affected; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Assumes both arrays have elements; educational.", isCorrect: true)
                    ]),
                    7: ShiftLineDetail(lineNumber: 7, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "May miss last element; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false),
                        ShiftOption(text: "Off-by-one", explanation: "Final array may miss element; correct.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Array safely initialized; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q6 — Detect Cycle in Linked List
        questions.append(Question(
            title: "Level 3 – Question 6",
            description: "Detect Cycle in Linked List",
            initialCode: "func hasCycle(head: Node?) -> Bool {\n    var slow = head\n    var fast = head\n    while fast != nil {\n        slow = slow?.next\n        fast = fast?.next?.next\n        if slow === fast { return true }\n    }\n    return false\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Running in circles.",
            conceptExplanation: "Tortoise and Hare.",
            language: .swift,
            shiftData: ShiftData(
                code: "func hasCycle(head: Node?) -> Bool {\n    var slow = head\n    var fast = head\n    while fast != nil {\n        slow = slow?.next\n        fast = fast?.next?.next\n        if slow === fast { return true }\n    }\n    return false\n}",
                errorLines: [
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Slow pointer may not progress correctly if fast skips; correct.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Single step of slow cannot loop alone; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Optional safe unwrapping prevents crash; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Pointer misalignment may misdetect cycle; correct.", isCorrect: true)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Infinite loop", explanation: "Skipping two nodes may miss cycle; loop may never resolve; correct.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "fast?.next?.next may be nil → optional safety important; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Assignment syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Off-by-one", explanation: "No index here; distractor.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Comparison may fail if pointers misaligned; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Condition logically correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Doesn’t loop; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Swift syntax valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q7 — QuickSort Partition
        questions.append(Question(
            title: "Level 3 – Question 7",
            description: "QuickSort Partition",
            initialCode: "func partition(arr: inout [Int], low: Int, high: Int) -> Int {\n    let pivot = arr[high]\n    var i = low - 1\n    for j in low..<high {\n        if arr[j] < pivot { i += 1; arr.swapAt(i,j) }\n    }\n    arr.swapAt(i, high)\n    return i\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Dividing the conquerable.",
            conceptExplanation: "Partitioning correctly is key.",
            language: .swift,
            shiftData: ShiftData(
                code: "func partition(arr: inout [Int], low: Int, high: Int) -> Int {\n    let pivot = arr[high]\n    var i = low - 1\n    for j in low..<high {\n        if arr[j] < pivot { i += 1; arr.swapAt(i,j) }\n    }\n    arr.swapAt(i, high)\n    return i\n}",
                errorLines: [
                    1: ShiftLineDetail(lineNumber: 1, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "i may underflow if low = 0; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Initial index misalignment affects swap logic; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Declaration valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "i is integer; safe; distractor.", isCorrect: false)
                    ]),
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Loop excludes last element; may misplace pivot; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Loop syntax correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Pivot handling may fail for small arrays; correct.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "For-loop terminates; distractor.", isCorrect: false)
                    ]),
                    6: ShiftLineDetail(lineNumber: 6, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Swap may misplace pivot if i incorrect; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "i may be one less than intended; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "SwapAt syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Array exists; safe; distractor.", isCorrect: false)
                    ]),
                    7: ShiftLineDetail(lineNumber: 7, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Returning wrong pivot index may corrupt recursion; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Index may not represent true partition; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Return syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q8 — Detect Palindrome
        questions.append(Question(
            title: "Level 3 – Question 8",
            description: "Detect Palindrome",
            initialCode: "func isPalindrome(s: String) -> Bool {\n    let chars = Array(s)\n    var left = 0, right = chars.count\n    while left < right {\n        if chars[left] != chars[right] { return false }\n        left += 1\n        right -= 1\n    }\n    return true\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Reading backwards.",
            conceptExplanation: "Indices must meet.",
            language: .swift,
            shiftData: ShiftData(
                code: "func isPalindrome(s: String) -> Bool {\n    let chars = Array(s)\n    var left = 0, right = chars.count\n    while left < right {\n        if chars[left] != chars[right] { return false }\n        left += 1\n        right -= 1\n    }\n    return true\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Array indices go 0 to count-1; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization itself correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Array safely initialized; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Loop may crash or skip last char; correct.", isCorrect: true)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Loop condition may miss middle element; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Should be <= for even-length strings; correct.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Condition terminates; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Comparison fails if right out-of-bounds; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "May terminate too early; correct.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Array safely initialized; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Increment/decrement may misalign indices; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Loop may overshoot indices; correct.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "No loop issue; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q9 — Guard Early Exit Trap
        questions.append(Question(
            title: "Level 3 – Question 9",
            description: "Guard Early Exit Trap",
            initialCode: "func printPositive(_ n: Int) {\n    guard n > 0 else { return }\n    print(n * 2)\n    return\n    print(\"Done\")\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Blocking the path.",
            conceptExplanation: "Guards ensure prerequisites.",
            language: .swift,
            shiftData: ShiftData(
                code: "func printPositive(_ n: Int) {\n    guard n > 0 else { return }\n    print(n * 2)\n    return\n    print(\"Done\")\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Early exit trap", explanation: "Function may return before intended logic; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Guard syntax correct; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "User may assume all code executes; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Multiplication logic may fail if negatives; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Not relevant; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Only prints double; may ignore processing; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Dead code trap", explanation: "Code after return never executes; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Return itself fine; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Later statements skipped; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Dead code trap", explanation: "Line never executed; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "May mislead user about completion; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Print itself fine; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Syntax valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))
        

        // Q10 — Struct vs Class Trap
        questions.append(Question(
            title: "Level 3 – Question 10",
            description: "Struct vs Class Trap",
            initialCode: "struct Counter { var value = 0 }\nfunc increase(_ c: Counter) {\n    var copy = c\n    copy.value += 1\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Copy or Reference?",
            conceptExplanation: "Structs are value types.",
            language: .swift,
            shiftData: ShiftData(
                code: "struct Counter { var value = 0 }\nfunc increase(_ c: Counter) {\n    var copy = c\n    copy.value += 1\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Value vs Reference", explanation: "Struct copy does not modify original; correct.", isCorrect: true),
                        ShiftOption(text: "State inconsistency", explanation: "Original value remains unchanged; correct.", isCorrect: true),
                        ShiftOption(text: "Side-effect trap", explanation: "Copy itself has no side-effect; distractor.", isCorrect: false),
                        ShiftOption(text: "Copy confusion trap", explanation: "Users may assume copy modifies original; correct.", isCorrect: true)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Increment affects only copy; correct.", isCorrect: true),
                        ShiftOption(text: "Value vs Reference", explanation: "Original struct untouched; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Increment syntax valid; distractor.", isCorrect: false),
                        ShiftOption(text: "Side-effect trap", explanation: "Original unchanged; correct.", isCorrect: true)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Function does not return modified struct; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "User may assume returned copy affects original; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Void return correct; distractor.", isCorrect: false),
                            ShiftOption(text: "Side-effect trap", explanation: "No side-effect on caller; correct.", isCorrect: true)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Value vs Reference", explanation: "Struct behavior is copy-on-write; correct.", isCorrect: true),
                        ShiftOption(text: "Copy confusion trap", explanation: "Users may misunderstand effect; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "No calculation; distractor.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Function closure valid; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q11 — Find Maximum Subarray
        questions.append(Question(
            title: "Level 3 – Question 11",
            description: "Find Maximum Subarray",
            initialCode: "func maxSubArray(_ nums: [Int]) -> Int {\n    var maxSoFar = nums[0]\n    var maxEndingHere = 0\n    for num in nums {\n        maxEndingHere += num\n        if maxEndingHere > maxSoFar { maxSoFar = maxEndingHere }\n        else { maxSoFar = num }\n    }\n    return maxSoFar\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Kadane's shadow.",
            conceptExplanation: "Dynamic programming approach.",
            language: .swift,
            shiftData: ShiftData(
                code: "func maxSubArray(_ nums: [Int]) -> Int {\n    var maxSoFar = nums[0]\n    var maxEndingHere = 0\n    for num in nums {\n        maxEndingHere += num\n        if maxEndingHere > maxSoFar { maxSoFar = maxEndingHere }\n        else { maxSoFar = num }\n    }\n    return maxSoFar\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Initial max may not handle negative-only arrays; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong initialization", explanation: "Starting max logic may misalign first comparison; correct.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "No index misalignment here; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Array assumed non-empty; distractor.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong initialization", explanation: "Should start with nums[0] to avoid negative sum errors; correct.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization itself doesn’t calculate; distractor.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Starting from 0 can break max logic; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid Swift syntax; distractor.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Comparison may overwrite correctly tracked max; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "May skip updating when needed; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Safe check; distractor.", isCorrect: false)
                    ]),
                    6: ShiftLineDetail(lineNumber: 6, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Resets max incorrectly for negative subarrays; correct.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Overwrites max incorrectly; correct.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax; distractor.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop here; distractor.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q12 — Remove Duplicates
        questions.append(Question(
            title: "Level 3 – Question 12",
            description: "Remove Duplicates",
            initialCode: "func removeDuplicates(_ nums: inout [Int]) -> Int {\n    var i = 0\n    for j in 1..<nums.count {\n        if nums[i] != nums[j] { nums[i] = nums[j]; i += 1 }\n    }\n    return i\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Playing nice with duplicates.",
            conceptExplanation: "Two pointers pattern.",
            language: .swift,
            shiftData: ShiftData(
                code: "func removeDuplicates(_ nums: inout [Int]) -> Int {\n    var i = 0\n    for j in 1..<nums.count {\n        if nums[i] != nums[j] { nums[i] = nums[j]; i += 1 }\n    }\n    return i\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Index may skip first element logic.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization is correct.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Increment may miscount final length.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid Swift syntax.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Assignment may overwrite unique elements.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "The for-loop terminates.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "i/j misalignment may miss duplicates.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Array is safely indexed.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Returned count may not include last element.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Final length miscounted by 1.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Count return is intentional.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Loop may skip first element check.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Loop control itself is fine.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Range is safe.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q13 — Merge Intervals
        questions.append(Question(
            title: "Level 3 – Question 13",
            description: "Merge Intervals",
            initialCode: "func mergeIntervals(_ intervals: [[Int]]) -> [[Int]] {\n    guard !intervals.isEmpty else { return [] }\n    var result: [[Int]] = [intervals[0]]\n    for i in 1..<intervals.count {\n        if result.last![1] >= intervals[i][0] {\n            result.last![1] = max(result.last![1], intervals[i][1]) - 1\n        } else {\n            result.append(intervals[i])\n        }\n    }\n    return result\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Overlapping boundaries.",
            conceptExplanation: "Merging ranges.",
            language: .swift,
            shiftData: ShiftData(
                code: "func mergeIntervals(_ intervals: [[Int]]) -> [[Int]] {\n    guard !intervals.isEmpty else { return [] }\n    var result: [[Int]] = [intervals[0]]\n    for i in 1..<intervals.count {\n        if result.last![1] >= intervals[i][0] {\n            result.last![1] = max(result.last![1], intervals[i][1]) - 1\n        } else {\n            result.append(intervals[i])\n        }\n    }\n    return result\n}",
                errorLines: [
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Initial array may misalign merge.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Starting with first element only.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid Swift syntax.", isCorrect: false),
                        ShiftOption(text: "Off-by-one", explanation: "Indexing is not misaligned.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Comparison may incorrectly merge intervals.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: ">= may miss exact overlap.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Guard prevents empty array.", isCorrect: false)
                    ]),
                    6: ShiftLineDetail(lineNumber: 6, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Subtracting 1 may shrink interval incorrectly.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Alters intended merged range.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid assignment.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop.", isCorrect: false)
                    ]),
                    7: ShiftLineDetail(lineNumber: 7, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Appending may skip intervals in edge cases.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "May misplace intervals.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Safe.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q14 — Rotate Array
        questions.append(Question(
            title: "Level 3 – Question 14",
            description: "Rotate Array",
            initialCode: "func rotate(_ nums: inout [Int], _ k: Int) {\n    let n = nums.count\n    let steps = k % n\n    for _ in 0..<steps {\n        let last = nums.removeLast()\n        nums.insert(last, at: 0)\n    }\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Spinning around.",
            conceptExplanation: "Modulo and Rotation.",
            language: .swift,
            shiftData: ShiftData(
                code: "func rotate(_ nums: inout [Int], _ k: Int) {\n    let n = nums.count\n    let steps = k % n\n    for _ in 0..<steps {\n        let last = nums.removeLast()\n        nums.insert(last, at: 0)\n    }\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Modulo may fail when k > n.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Negative k not handled.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop issue.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Loop may execute fewer times than intended.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Steps count misalign.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Loop logic intended.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Removes element but order may shift.", isCorrect: true),
                        ShiftOption(text: "Side-effect trap", explanation: "Mutation affects original array unexpectedly.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Array safely indexed.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Inserts element at front each loop; may misalign.", isCorrect: true),
                        ShiftOption(text: "Side-effect trap", explanation: "Array elements shifted unexpectedly.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Intended rotation.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q15 — Two Sum Problem
        questions.append(Question(
            title: "Level 3 – Question 15",
            description: "Two Sum Problem",
            initialCode: "func twoSum(_ nums: [Int], _ target: Int) -> [Int] {\n    for i in 0..<nums.count {\n        for j in i..<nums.count {\n            if nums[i] + nums[j] == target { return [i,j] }\n        }\n    }\n    return []\n}",
            correctCode: "",
            difficulty: 3,
            riddle: "Finding a pair.",
            conceptExplanation: "Nested loops complexity.",
            language: .swift,
            shiftData: ShiftData(
                code: "func twoSum(_ nums: [Int], _ target: Int) -> [Int] {\n    for i in 0..<nums.count {\n        for j in i..<nums.count {\n            if nums[i] + nums[j] == target { return [i,j] }\n        }\n    }\n    return []\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Outer loop includes 0 correctly but may misalign inner start.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Loop itself is fine.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Inner loop may include same element twice.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Should start at i+1 to avoid pairing same element.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Inner loop may sum same element twice.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Terminates naturally.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Sum logic may fail for negative numbers.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "May miss all valid pairs if multiple exist.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Array is safely indexed.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Empty return if no pair found; may confuse user.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Return itself is correct.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "No loop.", isCorrect: false)
                    ])
                ]
            )
        ))

        } else if language == .c {
            // MARK: - Level 3 (C Language)
            // Q1 — Fibonacci Recursion
            questions.append(Question(
                title: "Level 3 – Question 1",
                description: "Infinite Recursion in Fibonacci",
                initialCode: "int fib(int n) {\n    if (n == 0) return 0;\n    if (n == 1) return 1;\n    return fib(n) + fib(n - 1); // Typo in recursion?\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Spiral out of control.",
                conceptExplanation: "Base cases and recursive steps.",
                language: .c,
                shiftData: ShiftData(
                    code: "int fib(int n) {\n    if (n == 0) return 0;\n    if (n == 1) return 1;\n    return fib(n) + fib(n - 1); // Typo in recursion?\n}",
                    errorLines: [
                        4: ShiftLineDetail(lineNumber: 4, options: [
                            ShiftOption(text: "Infinite loop", explanation: "fib(n) calls itself without reducing n.", isCorrect: true),
                            ShiftOption(text: "Stack overflow", explanation: "Unbounded recursion will crash the stack.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Should be fib(n-1) + fib(n-2).", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Syntax is valid C.", isCorrect: false)
                        ])
                    ]
                )
            ))

            // Q2 — Array Out of Bounds
            questions.append(Question(
                title: "Level 3 – Question 2",
                description: "Array Index Out of Bounds",
                initialCode: "void printArray(int arr[], int size) {\n    for (int i = 0; i <= size; i++) {\n        printf(\"%d \", arr[i]);\n    }\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "One step too far.",
                conceptExplanation: "0-based indexing.",
                language: .c,
                shiftData: ShiftData(
                    code: "void printArray(int arr[], int size) {\n    for (int i = 0; i <= size; i++) {\n        printf(\"%d \", arr[i]);\n    }\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Off-by-one", explanation: "Loop condition i <= size accesses invalid index.", isCorrect: true),
                            ShiftOption(text: "Index out of bounds", explanation: "Accessing arr[size] is undefined behavior.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "For loop syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Wrong calculation", explanation: "Loop initialization is correct.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q3 — Uninitialized Variable
            questions.append(Question(
                title: "Level 3 – Question 3",
                description: "Uninitialized Variable Usage",
                initialCode: "int sum(int n) {\n    int total;\n    for (int i = 0; i < n; i++) {\n        total += i;\n    }\n    return total;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Starting from nothing.",
                conceptExplanation: "Automatic variables contain garbage.",
                language: .c,
                shiftData: ShiftData(
                    code: "int sum(int n) {\n    int total;\n    for (int i = 0; i < n; i++) {\n        total += i;\n    }\n    return total;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Logic oversight", explanation: "Variable total is not initialized.", isCorrect: true),
                            ShiftOption(text: "Garbage value", explanation: "Adding to uninitialized memory produces undefined results.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Declaration is valid.", isCorrect: false),
                            ShiftOption(text: "Wrong calculation", explanation: "Logic would be correct if initialized to 0.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
             // Q4 — Integer Division
            questions.append(Question(
                title: "Level 3 – Question 4",
                description: "Integer Division Truncation",
                initialCode: "double average(int a, int b) {\n    return (a + b) / 2;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Lost in translation.",
                conceptExplanation: "Int/Int results in Int.",
                language: .c,
                shiftData: ShiftData(
                    code: "double average(int a, int b) {\n    return (a + b) / 2;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Precision loss", explanation: "Integer division truncates decimal part.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Should cast one operand to double.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Valid return statement.", isCorrect: false),
                            ShiftOption(text: "Type mismatch", explanation: "Implicit cast to return type works but after data loss.", isCorrect: false)
                        ])
                    ]
                )
            ))

            // Q5 — String Comparison
            questions.append(Question(
                title: "Level 3 – Question 5",
                description: "String Comparison Error",
                initialCode: "int checkPassword(char* s) {\n    if (s == \"password\") return 1;\n    return 0;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Address vs Value.",
                conceptExplanation: "Use strcmp for C strings.",
                language: .c,
                shiftData: ShiftData(
                    code: "int checkPassword(char* s) {\n    if (s == \"password\") return 1;\n    return 0;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Pointer comparison", explanation: "Compares memory addresses, not string content.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Literal string has different address than s.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Valid pointer comparison syntax.", isCorrect: false),
                            ShiftOption(text: "Correctness", explanation: "This will always return false.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q6 — Memory Leak
            questions.append(Question(
                title: "Level 3 – Question 6",
                description: "Memory Leak",
                initialCode: "void process() {\n    int* ptr = (int*)malloc(sizeof(int) * 10);\n    // do work\n    return;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Forgotten cleanup.",
                conceptExplanation: "Manual memory management.",
                language: .c,
                shiftData: ShiftData(
                    code: "void process() {\n    int* ptr = (int*)malloc(sizeof(int) * 10);\n    // do work\n    return;\n}",
                    errorLines: [
                        4: ShiftLineDetail(lineNumber: 4, options: [
                            ShiftOption(text: "Memory leak", explanation: "Allocated memory is not freed before return.", isCorrect: true),
                            ShiftOption(text: "Resource exhaustion", explanation: "Repeated calls will consume all memory.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Return is valid.", isCorrect: false),
                            ShiftOption(text: "Null pointer", explanation: "Malloc might return NULL but that is a separate check.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q7 — Buffer Overflow
            questions.append(Question(
                title: "Level 3 – Question 7",
                description: "Buffer Overflow",
                initialCode: "void copy(char* src) {\n    char dest[5];\n    strcpy(dest, src);\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Spilling over.",
                conceptExplanation: "Unchecked string copy.",
                language: .c,
                shiftData: ShiftData(
                    code: "void copy(char* src) {\n    char dest[5];\n    strcpy(dest, src);\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Buffer overflow", explanation: "src might be larger than dest buffer.", isCorrect: true),
                            ShiftOption(text: "Security risk", explanation: "Classic vulnerability.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Function call is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Should use strncpy.", isCorrect: true)
                        ])
                    ]
                )
            ))

            // Q8 — Modifying String Literal
            questions.append(Question(
                title: "Level 3 – Question 8",
                description: "Modifying String Literal",
                initialCode: "void modify() {\n    char* s = \"Hello\";\n    s[0] = 'h';\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Immutable past.",
                conceptExplanation: "String literals are read-only.",
                language: .c,
                shiftData: ShiftData(
                    code: "void modify() {\n    char* s = \"Hello\";\n    s[0] = 'h';\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Runtime error", explanation: "Writing to read-only memory segment causes crash.", isCorrect: true),
                            ShiftOption(text: "Undefined behavior", explanation: "Modifying string literal is undefined.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Array indexing syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Should use char array for mutable strings.", isCorrect: true)
                        ])
                    ]
                )
            ))

             // Q9 — Dangling Pointer
            questions.append(Question(
                title: "Level 3 – Question 9",
                description: "Dangling Pointer",
                initialCode: "int* getPtr() {\n    int x = 10;\n    return &x;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Vanishing act.",
                conceptExplanation: "Stack memory lifetime.",
                language: .c,
                shiftData: ShiftData(
                    code: "int* getPtr() {\n    int x = 10;\n    return &x;\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Dangling pointer", explanation: "Returning address of local stack variable.", isCorrect: true),
                            ShiftOption(text: "Undefined behavior", explanation: "Accessing this pointer after return is unsafe.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Address-of operator is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Variable x is destroyed when function returns.", isCorrect: true)
                        ])
                    ]
                )
            ))

            // Q10 — Macro Side Effects
            questions.append(Question(
                title: "Level 3 – Question 10",
                description: "Macro Side Effects",
                initialCode: "#define SQUARE(x) x*x\nint main() {\n    int result = SQUARE(1+2);\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Hidden expansion.",
                conceptExplanation: "Textual substitution requires parenthesis.",
                language: .c,
                shiftData: ShiftData(
                    code: "#define SQUARE(x) x*x\nint main() {\n    int result = SQUARE(1+2);\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Logic oversight", explanation: "Expands to 1+2*1+2 = 5, not 9.", isCorrect: true),
                            ShiftOption(text: "Precedence error", explanation: "Missing parentheses in macro definition.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Macro usage is valid.", isCorrect: false),
                            ShiftOption(text: "Wrong calculation", explanation: "Standard order of operations applies.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q11 — Sizeof Pointer vs Array
            questions.append(Question(
                title: "Level 3 – Question 11",
                description: "Sizeof Pointer",
                initialCode: "void func(int arr[]) {\n    int size = sizeof(arr) / sizeof(arr[0]);\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Decay to pointer.",
                conceptExplanation: "Array parameter decays to pointer.",
                language: .c,
                shiftData: ShiftData(
                    code: "void func(int arr[]) {\n    int size = sizeof(arr) / sizeof(arr[0]);\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Wrong calculation", explanation: "sizeof(arr) returns pointer size, not array size.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Cannot determine array length inside function this way.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Sizeof usage is valid.", isCorrect: false),
                            ShiftOption(text: "Off-by-one", explanation: "Not an indexing error.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q12 — Swap Logic
            questions.append(Question(
                title: "Level 3 – Question 12",
                description: "Swap Logic Fail",
                initialCode: "void swap(int a, int b) {\n    int temp = a;\n    a = b;\n    b = temp;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "No effect.",
                conceptExplanation: "Pass by value vs reference.",
                language: .c,
                shiftData: ShiftData(
                    code: "void swap(int a, int b) {\n    int temp = a;\n    a = b;\n    b = temp;\n}",
                    errorLines: [
                        1: ShiftLineDetail(lineNumber: 1, options: [
                            ShiftOption(text: "Logic oversight", explanation: "Arguments passed by value, originals unchanged.", isCorrect: true),
                            ShiftOption(text: "No side effect", explanation: "Swaps only local copies.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Function syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Missing pointers", explanation: "Should take int* arguments.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q13 — Break vs Continue
            questions.append(Question(
                title: "Level 3 – Question 13",
                description: "Break vs Continue",
                initialCode: "void printOdd(int n) {\n    for (int i=0; i<n; i++) {\n        if (i % 2 == 0) break;\n        printf(\"%d\", i);\n    }\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Stopping short.",
                conceptExplanation: "Break exits loop entirely.",
                language: .c,
                shiftData: ShiftData(
                    code: "void printOdd(int n) {\n    for (int i=0; i<n; i++) {\n        if (i % 2 == 0) break;\n        printf(\"%d\", i);\n    }\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Logic oversight", explanation: "Break stops loop on first even number (0).", isCorrect: true),
                            ShiftOption(text: "Wrong keyword", explanation: "Should use continue to skip iteration.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Break is valid here.", isCorrect: false),
                            ShiftOption(text: "Off-by-one", explanation: "Not an index error.", isCorrect: false)
                        ])
                    ]
                )
            ))

            // Q14 — Switch Fallthrough
            questions.append(Question(
                title: "Level 3 – Question 14",
                description: "Switch Fallthrough",
                initialCode: "void check(int n) {\n    switch(n) {\n        case 1: printf(\"One\");\n        case 2: printf(\"Two\");\n    }\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Cascading effect.",
                conceptExplanation: "Case statements fall through without break.",
                language: .c,
                shiftData: ShiftData(
                    code: "void check(int n) {\n    switch(n) {\n        case 1: printf(\"One\");\n        case 2: printf(\"Two\");\n    }\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Logic oversight", explanation: "Execution continues to case 2.", isCorrect: true),
                            ShiftOption(text: "Missing break", explanation: "Should end case with break statement.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Case syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Wrong calculation", explanation: "Not a math error.", isCorrect: false)
                        ])
                    ]
                )
            ))

            // Q15 — Infinite While Loop
            questions.append(Question(
                title: "Level 3 – Question 15",
                description: "Infinite While Loop",
                initialCode: "void countdown(int n) {\n    while (n > 0);\n    n--;\n}",
                correctCode: "",
                difficulty: 3,
                riddle: "Lost in whitespace.",
                conceptExplanation: "Semicolon terminates loop body.",
                language: .c,
                shiftData: ShiftData(
                    code: "void countdown(int n) {\n    while (n > 0);\n    n--;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Infinite loop", explanation: "Semicolon makes empty loop body.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "n is never decremented inside loop.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Semicolon is valid but logic is wrong.", isCorrect: false),
                            ShiftOption(text: "Dead code", explanation: "n-- is never reached.", isCorrect: true)
                        ])
                    ]
                )
            ))
        }
        return questions
    }

    private static func generateLevel4Questions(for language: Language) -> [Question] {
        var questions: [Question] = []
        
        if language == .swift {
        // Q1 — Reverse Doubly Linked List
        questions.append(Question(
            title: "Level 4 – Question 1",
            description: "Reverse Doubly Linked List",
            initialCode: "class DNode { var next: DNode?; var prev: DNode? }\nfunc reverseDLL(_ head: DNode?) -> DNode? {\n    var current = head\n    var temp: DNode? = nil\n    while current != nil {\n        temp = current?.prev\n        current?.prev = current?.next\n        // current?.next = temp  <-- Missing update?\n        current = current?.prev // Wait, is this right step?\n    }\n    return temp?.prev\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Flipping directions.",
            conceptExplanation: "Swap next and prev completely.",
            language: .swift,
            shiftData: ShiftData(
                code: "class DNode { var next: DNode?; var prev: DNode? }\nfunc reverseDLL(_ head: DNode?) -> DNode? {\n    var current = head\n    var temp: DNode? = nil\n    while current != nil {\n        temp = current?.prev\n        current?.prev = current?.next\n        // current?.next = temp  <-- Missing update?\n        current = current?.prev // Wait, is this right step?\n    }\n    return temp?.prev\n}",
                errorLines: [
                    6: ShiftLineDetail(lineNumber: 6, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Failed to update current.next.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Assignment is missing.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "This comment is not executable code.", isCorrect: false),
                        ShiftOption(text: "Side-effect trap", explanation: "List structure is broken.", isCorrect: true)
                    ]),
                    7: ShiftLineDetail(lineNumber: 7, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Moving to prev moves backwards after swap.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "May get stuck or crash.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Current is optional, so it is safe.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "The syntax is valid.", isCorrect: false)
                    ]),
                    9: ShiftLineDetail(lineNumber: 9, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Returning new head requires temp check.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Temp may be nil for single node.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Return value logic is critical.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "The syntax is valid.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q2 — Level Order Traversal
        questions.append(Question(
            title: "Level 4 – Question 2",
            description: "Level Order Traversal",
            initialCode: "func levelOrder(_ root: Node?) -> [[Int]] {\n    guard let root = root else { return [] }\n    var queue = [root]\n    var result = [[Int]]()\n    while !queue.isEmpty {\n        let node = queue.removeLast() // pop back?\n        // Logic to group by level missing\n        queue.append(node.left!)\n        queue.append(node.right!)\n    }\n    return result\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Queueing up.",
            conceptExplanation: "BFS requires FIFO queue.",
            language: .swift,
            shiftData: ShiftData(
                code: "func levelOrder(_ root: Node?) -> [[Int]] {\n    guard let root = root else { return [] }\n    var queue = [root]\n    var result = [[Int]]()\n    while !queue.isEmpty {\n        let node = queue.removeLast() // pop back?\n        // Logic to group by level missing\n        queue.append(node.left!)\n        queue.append(node.right!)\n    }\n    return result\n}",
                errorLines: [
                    6: ShiftLineDetail(lineNumber: 6, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "removeLast makes it a Stack (DFS), not Queue (BFS).", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "BFS requires removeFirst.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "This is a valid method.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Queue is not empty, so it is safe.", isCorrect: false)
                    ]),
                    8: ShiftLineDetail(lineNumber: 8, options: [
                        ShiftOption(text: "Null pointer", explanation: "Force unwrapping left child crashes if nil.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Must check for nil before appending.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Queue size changes dynamically.", isCorrect: false)
                    ]),
                    9: ShiftLineDetail(lineNumber: 9, options: [
                        ShiftOption(text: "Null pointer", explanation: "Force unwrapping right child crashes if nil.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Must check for nil.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Wrong calculation", explanation: "Appending nil is invalid.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q3 — Merge K Sorted Lists
        questions.append(Question(
            title: "Level 4 – Question 3",
            description: "Merge K Sorted Lists",
            initialCode: "func mergeKLists(_ lists: [Node?]) -> Node? {\n    if lists.isEmpty { return nil }\n    var result = lists[0]\n    for i in 1...lists.count {\n        // Merge result with lists[i]\n        // Assume merge(l1, l2) exists\n    }\n    return result\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Divide and Conquer.",
            conceptExplanation: "Iterative merging.",
            language: .swift,
            shiftData: ShiftData(
                code: "func mergeKLists(_ lists: [Node?]) -> Node? {\n    if lists.isEmpty { return nil }\n    var result = lists[0]\n    for i in 1...lists.count {\n        // Merge result with lists[i]\n        // Assume merge(l1, l2) exists\n    }\n    return result\n}",
                errorLines: [
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Range 1...count creates out-of-bounds error.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Iteration count interpretation.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Lists array access is unsafe at count.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Range validation logic.", isCorrect: false)
                    ]),
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Initializing with lists[0] is only valid if count > 0.", isCorrect: true),
                        ShiftOption(text: "Null pointer", explanation: "Guarded check prevents crash.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization logic appears correct.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q4 — Binary Tree Maximum Path Sum
        questions.append(Question(
            title: "Level 4 – Question 4",
            description: "Binary Tree Maximum Path Sum",
            initialCode: "var maxSum = Int.min\nfunc maxPathSum(_ root: TreeNode?) -> Int {\n    guard let root = root else { return 0 }\n    let left = maxPathSum(root.left)\n    let right = maxPathSum(root.right)\n    let price = root.val + left + right\n    maxSum = max(maxSum, price)\n    return price\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Finding the best route.",
            conceptExplanation: "Path vs Subtree sum.",
            language: .swift,
            shiftData: ShiftData(
                code: "var maxSum = Int.min\nfunc maxPathSum(_ root: TreeNode?) -> Int {\n    guard let root = root else { return 0 }\n    let left = maxPathSum(root.left)\n    let right = maxPathSum(root.right)\n    let price = root.val + left + right\n    maxSum = max(maxSum, price)\n    return price\n}",
                errorLines: [
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Should ignore negative path sums (max(0, ...)).", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Returning full sum propagates negatives.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Recursion terminates correctly.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Should ignore negative path sums.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Summing negative children reduces max.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Operation is safe.", isCorrect: false)
                    ]),
                    8: ShiftLineDetail(lineNumber: 8, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Should return max of ONE branch + root, not both.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Returning both creates an invalid split path.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Return statement is valid.", isCorrect: false),
                        ShiftOption(text: "Side-effect trap", explanation: "Updates global var okay, but return is wrong.", isCorrect: true)
                    ])
                ]
            )
        ))

        // Q5 — Longest Valid Parentheses
        questions.append(Question(
            title: "Level 4 – Question 5",
            description: "Longest Valid Parentheses",
            initialCode: "func longestValidParentheses(_ s: String) -> Int {\n    var stack = [-1]\n    var maxLen = 0\n    for (i, char) in s.enumerated() {\n        if char == \"(\" { stack.append(i) }\n        else {\n            stack.removeLast()\n            if stack.isEmpty { stack.append(i) }\n            else { maxLen = max(maxLen, i - stack.last!) }\n        }\n    }\n    return maxLen\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Matching pairs.",
            conceptExplanation: "Stack tracks indices.",
            language: .swift,
            shiftData: ShiftData(
                code: "func longestValidParentheses(_ s: String) -> Int {\n    var stack = [-1]\n    var maxLen = 0\n    for (i, char) in s.enumerated() {\n        if char == \"(\" { stack.append(i) }\n        else {\n            stack.removeLast()\n            if stack.isEmpty { stack.append(i) }\n            else { maxLen = max(maxLen, i - stack.last!) }\n        }\n    }\n    return maxLen\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Stack initialization -1 handles edge cases correctly.", isCorrect: false),
                         ShiftOption(text: "Wrong calculation", explanation: "Stack logic is generally sound.", isCorrect: false),
                         ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                         ShiftOption(text: "Null pointer", explanation: "Safe.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Code correctly appends index for '('", isCorrect: false),
                        ShiftOption(text: "Wrong calculation", explanation: "Logic is correct.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Correct.", isCorrect: false),
                        ShiftOption(text: "Side-effect trap", explanation: "Append affects stack state.", isCorrect: false)
                    ]),
                    6: ShiftLineDetail(lineNumber: 6, options: [
                         ShiftOption(text: "Logic oversight", explanation: "Popping is needed to match parentheses.", isCorrect: true),
                         ShiftOption(text: "Wrong calculation", explanation: "Calculation is performed subsequently.", isCorrect: false),
                         ShiftOption(text: "Infinite loop", explanation: "There is no infinite loop.", isCorrect: false),
                         ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q6 — Median of Two Sorted Arrays
        questions.append(Question(
            title: "Level 4 – Question 6",
            description: "Median of Two Sorted Arrays",
            initialCode: "func findMedian(_ nums1: [Int], _ nums2: [Int]) -> Double {\n    let merged = (nums1 + nums2).sorted()\n    let mid = merged.count / 2\n    if merged.count % 2 == 0 {\n        return Double(merged[mid] + merged[mid - 1]) / 2 // Integer division?\n    } else {\n        return Double(merged[mid])\n    }\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Middle ground.",
            conceptExplanation: "Integer division truncation.",
            language: .swift,
            shiftData: ShiftData(
                code: "func findMedian(_ nums1: [Int], _ nums2: [Int]) -> Double {\n    let merged = (nums1 + nums2).sorted()\n    let mid = merged.count / 2\n    if merged.count % 2 == 0 {\n        return Double(merged[mid] + merged[mid - 1]) / 2 // Integer division?\n    } else {\n        return Double(merged[mid])\n    }\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Performance trap", explanation: "O(n+m) merging is not O(log(n+m)).", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Sorting is correct but inefficient.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Merging logic is valid but inefficient.", isCorrect: false)
                    ]),
                    5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Integer division occurs before Double conversion.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Fractional part is truncated.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid syntax.", isCorrect: false),
                        ShiftOption(text: "Type mismatch", explanation: "Double initialization handles the type conversion.", isCorrect: false)
                    ])
                ]
            )
        ))

       // Q7 — Edit Distance
        questions.append(Question(
            title: "Level 4 – Question 7",
            description: "Edit Distance",
            initialCode: "func minDistance(_ word1: String, _ word2: String) -> Int {\n    let m = word1.count, n = word2.count\n    var dp = [[Int]](repeating: [Int](repeating: 0, count: n), count: m)\n    for i in 0...m { dp[i][0] = i }\n    for j in 0...n { dp[0][j] = j }\n    // ... loops ...\n    return dp[m][n]\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Transformations.",
            conceptExplanation: "DP Table Initialization.",
            language: .swift,
            shiftData: ShiftData(
                code: "func minDistance(_ word1: String, _ word2: String) -> Int {\n    let m = word1.count, n = word2.count\n    var dp = [[Int]](repeating: [Int](repeating: 0, count: n), count: m)\n    for i in 0...m { dp[i][0] = i }\n    for j in 0...n { dp[0][j] = j }\n    // ... loops ...\n    return dp[m][n]\n}",
                errorLines: [
                    3: ShiftLineDetail(lineNumber: 3, options: [
                        ShiftOption(text: "Off-by-one", explanation: "Array size should be n+1, m+1.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Initialization size is incorrect.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Safe.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Index out of bounds", explanation: "Loop index goes to m, causing crash with array size m.", isCorrect: true),
                        ShiftOption(text: "Off-by-one", explanation: "Loop range is incorrect.", isCorrect: true),
                        ShiftOption(text: "Infinite loop", explanation: "Loop is finite.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Boundary condition failure.", isCorrect: true)
                    ]),
                     5: ShiftLineDetail(lineNumber: 5, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Condition left < right is safer; left <= right may double count middle.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Loop converges correctly.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Loop terminates.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false)
                    ]),
                     7: ShiftLineDetail(lineNumber: 7, options: [
                        ShiftOption(text: "Wrong calculation", explanation: "Water accumulation logic is correct.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Max value update is correct.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false),
                        ShiftOption(text: "Null pointer", explanation: "Safe.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q9 — Largest Rectangle in Histogram
        questions.append(Question(
            title: "Level 4 – Question 9",
            description: "Largest Rectangle in Histogram",
            initialCode: "func largestRectangleArea(_ heights: [Int]) -> Int {\n    var stack: [Int] = []\n    var maxArea = 0\n    for (i, h) in heights.enumerated() {\n        while !stack.isEmpty && heights[stack.last!] > h {\n            let height = heights[stack.removeLast()]\n            let width = stack.isEmpty ? i : i - stack.last! - 1\n            maxArea = max(maxArea, height * width)\n        }\n        stack.append(i)\n    }\n    return maxArea\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Area under the curve.",
            conceptExplanation: "Monotonic Stack.",
            language: .swift,
            shiftData: ShiftData(
                code: "func largestRectangleArea(_ heights: [Int]) -> Int {\n    var stack: [Int] = []\n    var maxArea = 0\n    for (i, h) in heights.enumerated() {\n        while !stack.isEmpty && heights[stack.last!] > h {\n            let height = heights[stack.removeLast()]\n            let width = stack.isEmpty ? i : i - stack.last! - 1\n            maxArea = max(maxArea, height * width)\n        }\n        stack.append(i)\n    }\n    return maxArea\n}",
                errorLines: [
                    9: ShiftLineDetail(lineNumber: 9, options: [
                        ShiftOption(text: "Logic oversight", explanation: "Loop ends but stack is not empty; remaining elements ignored.", isCorrect: true),
                        ShiftOption(text: "Wrong calculation", explanation: "Max area calculation is incomplete.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Loop finishes correctly.", isCorrect: false)
                    ])
                ]
            )
        ))

        // Q10 — Reverse Linked List Recursively
        questions.append(Question(
            title: "Level 4 – Question 10",
            description: "Reverse Linked List Recursively",
            initialCode: "func reverseList(_ head: ListNode?) -> ListNode? {\n    if head == nil || head?.next == nil { return head }\n    let p = reverseList(head?.next)\n    head?.next?.next = head\n    head?.next = nil\n    return p\n}",
            correctCode: "",
            difficulty: 4,
            riddle: "Recursive flip.",
            conceptExplanation: "Stack unwinding.",
            language: .swift,
            shiftData: ShiftData(
                code: "func reverseList(_ head: ListNode?) -> ListNode? {\n    if head == nil || head?.next == nil { return head }\n    let p = reverseList(head?.next)\n    head?.next?.next = head\n    head?.next = nil\n    return p\n}",
                errorLines: [
                    2: ShiftLineDetail(lineNumber: 2, options: [
                        ShiftOption(text: "Base case trap", explanation: "Correct base case; recursion stops at end.", isCorrect: false),
                        ShiftOption(text: "Logic oversight", explanation: "Recursion logic is correct.", isCorrect: false),
                        ShiftOption(text: "Infinite loop", explanation: "Base case exists.", isCorrect: false),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false)
                    ]),
                    4: ShiftLineDetail(lineNumber: 4, options: [
                        ShiftOption(text: "Null pointer", explanation: "Recursive safety check holds.", isCorrect: false),
                        ShiftOption(text: "Cycle creation", explanation: "Cycle forms if head.next is not set to nil.", isCorrect: true),
                        ShiftOption(text: "Logic oversight", explanation: "Crucial step to reverse the link.", isCorrect: true),
                        ShiftOption(text: "Syntax error", explanation: "Valid.", isCorrect: false)
                    ])
                ]
            )
        ))
        
        } else if language == .c {
         // MARK: - Level 4 (C Language)
            
            // Q1 — Double Free
            questions.append(Question(
                title: "Level 4 – Question 1",
                description: "Double Free",
                initialCode: "void cleanup(int* ptr) {\n    free(ptr);\n    free(ptr);\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Reviewing history.",
                conceptExplanation: "Memory management rules.",
                language: .c,
                shiftData: ShiftData(
                    code: "void cleanup(int* ptr) {\n    free(ptr);\n    free(ptr);\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Double free", explanation: "Freeing already freed memory causes crash.", isCorrect: true),
                            ShiftOption(text: "Undefined behavior", explanation: "Heap corruption likely.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Function call is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Redundant cleanup.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q2 — Use After Free
            questions.append(Question(
                title: "Level 4 – Question 2",
                description: "Use After Free",
                initialCode: "int getValue(int* ptr) {\n    free(ptr);\n    return *ptr;\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Post-mortem access.",
                conceptExplanation: "Dangling pointer usage.",
                language: .c,
                shiftData: ShiftData(
                    code: "int getValue(int* ptr) {\n    free(ptr);\n    return *ptr;\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Use after free", explanation: "Accessing memory after freeing it.", isCorrect: true),
                            ShiftOption(text: "Undefined behavior", explanation: "Value is unpredictable.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Dereference syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Should return before freeing.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q3 — Signed Integer Overflow
            questions.append(Question(
                title: "Level 4 – Question 3",
                description: "Signed Integer Overflow",
                initialCode: "int add(int a, int b) {\n    if (a > 0 && b > 0 && a + b < 0) return -1;\n    return a + b;\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Wrapping around.",
                conceptExplanation: "Undefined behavior logic.",
                language: .c,
                shiftData: ShiftData(
                    code: "int add(int a, int b) {\n    if (a > 0 && b > 0 && a + b < 0) return -1;\n    return a + b;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Undefined behavior", explanation: "Signed overflow is UB in C.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Check relies on overflow having happened.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Expression syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Compiler optimization", explanation: "Compiler may remove check assuming no overflow.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q4 — Scanf Missing Ampersand
            questions.append(Question(
                title: "Level 4 – Question 4",
                description: "Scanf Error",
                initialCode: "void readInput() {\n    int n;\n    scanf(\"%d\", n);\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Address required.",
                conceptExplanation: "Pass pointer to scanf.",
                language: .c,
                shiftData: ShiftData(
                    code: "void readInput() {\n    int n;\n    scanf(\"%d\", n);\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Segmentation fault", explanation: "Writing to address 'n' (random value).", isCorrect: true),
                            ShiftOption(text: "Missing &", explanation: "Scanf needs address of variable.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Valid function call syntax.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Input not stored correctly.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q5 — Strcat Buffer Overflow
            questions.append(Question(
                title: "Level 4 – Question 5",
                description: "Strcat Overflow",
                initialCode: "void combine(char* s) {\n    char buf[10] = \"Hello\";\n    strcat(buf, s);\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Running out of space.",
                conceptExplanation: "Unbounded string concatenation.",
                language: .c,
                shiftData: ShiftData(
                    code: "void combine(char* s) {\n    char buf[10] = \"Hello\";\n    strcat(buf, s);\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Buffer overflow", explanation: "Input strings may exceed buf size.", isCorrect: true),
                            ShiftOption(text: "Undefined behavior", explanation: "Overwriting stack memory.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Logic error, not syntax.", isCorrect: false),
                            ShiftOption(text: "Security risk", explanation: "Exploitable vulnerability.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q6 — Malloc Cast
            questions.append(Question(
                title: "Level 4 – Question 6",
                description: "Incorrect Malloc Size",
                initialCode: "int* createArray(int n) {\n    return malloc(n);\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Bytes vs Elements.",
                conceptExplanation: "Malloc takes bytes, not count.",
                language: .c,
                shiftData: ShiftData(
                    code: "int* createArray(int n) {\n    return malloc(n);\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Wrong allocation", explanation: "Allocates n bytes, not n integers.", isCorrect: true),
                            ShiftOption(text: "Heap corruption", explanation: "Writing out of bounds later.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Valid C, but incorrect size.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Should be n * sizeof(int).", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q7 — File Not Closed
            questions.append(Question(
                title: "Level 4 – Question 7",
                description: "Resource Leak",
                initialCode: "void readFile() {\n    FILE* f = fopen(\"data.txt\", \"r\");\n    if (!f) return;\n    // read data\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Left open.",
                conceptExplanation: "File handles must be closed.",
                language: .c,
                shiftData: ShiftData(
                    code: "void readFile() {\n    FILE* f = fopen(\"data.txt\", \"r\");\n    if (!f) return;\n    // read data\n}",
                    errorLines: [
                        4: ShiftLineDetail(lineNumber: 4, options: [
                            ShiftOption(text: "Resource leak", explanation: "File handle not closed (fclose).", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "May run out of file descriptors.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Implicit return is valid.", isCorrect: false),
                            ShiftOption(text: "Null pointer", explanation: "Checked at line 3.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q8 — Unsigned Comparison
            questions.append(Question(
                title: "Level 4 – Question 8",
                description: "Unsigned Logic",
                initialCode: "void loopCheck() {\n    for (unsigned int i = 10; i >= 0; i--) {\n        printf(\"%u\", i);\n    }\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Never negative.",
                conceptExplanation: "Unsigned integers wrap around.",
                language: .c,
                shiftData: ShiftData(
                    code: "void loopCheck() {\n    for (unsigned int i = 10; i >= 0; i--) {\n        printf(\"%u\", i);\n    }\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Infinite loop", explanation: "Unsigned i is always >= 0.", isCorrect: true),
                            ShiftOption(text: "Integer underflow", explanation: "Wrap arounds to max int.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Loop syntax is valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "0 - 1 becomes 4294967295.", isCorrect: true)
                        ])
                    ]
                )
            ))
            
            // Q9 — Const Pointer Modification
            questions.append(Question(
                title: "Level 4 – Question 9",
                description: "Const Correctness",
                initialCode: "void mod(const int* ptr) {\n    *ptr = 0;\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Breaking the promise.",
                conceptExplanation: "Const pointers are read-only.",
                language: .c,
                shiftData: ShiftData(
                    code: "void mod(const int* ptr) {\n    *ptr = 0;\n}",
                    errorLines: [
                        2: ShiftLineDetail(lineNumber: 2, options: [
                            ShiftOption(text: "Compilation error", explanation: "Cannot assign to read-only location.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Assignment syntax is invalid for const.", isCorrect: true),
                            ShiftOption(text: "Logic oversight", explanation: "Violates const contract.", isCorrect: true),
                            ShiftOption(text: "Valid code", explanation: "This will not compile.", isCorrect: false)
                        ])
                    ]
                )
            ))
            
            // Q10 — Volatile needed
            questions.append(Question(
                title: "Level 4 – Question 10",
                description: "Volatile Keyword",
                initialCode: "int flag = 0; // shared var\nvoid wait() {\n    while (flag == 0); // hardware updates flag\n}",
                correctCode: "",
                difficulty: 4,
                riddle: "Invisible changes.",
                conceptExplanation: "Compiler caching optimization.",
                language: .c,
                shiftData: ShiftData(
                    code: "int flag = 0; // shared var\nvoid wait() {\n    while (flag == 0); // hardware updates flag\n}",
                    errorLines: [
                        3: ShiftLineDetail(lineNumber: 3, options: [
                            ShiftOption(text: "Infinite loop", explanation: "Compiler optimizes check to always true.", isCorrect: true),
                            ShiftOption(text: "Missing volatile", explanation: "Tell compiler value changes externally.", isCorrect: true),
                            ShiftOption(text: "Syntax error", explanation: "Loop buffer valid.", isCorrect: false),
                            ShiftOption(text: "Logic oversight", explanation: "Hardware update ignored by generated code.", isCorrect: true)
                        ])
                    ]
                )
            ))
        }
        return questions
    }

    private static func generatePlaceholders(for level: Int, count: Int = 50, language: Language = .python) -> [Question] {
        var generated: [Question] = []
        for i in 1...count {
            generated.append(
                Question(
                    title: "Level \(level) – Question \(i)",
                    description: "Level \(level) challenge: Optimize the logic for question \(i).",
                    initialCode: language == .c ? "int main() {\n    // TODO: Implement logic\n    return 0;\n}" : "def process():\n    # TODO: Implement logic\n    pass",
                    correctCode: language == .c ? "int main() {\n    return 0;\n}" : "def process():\n    return True",
                    difficulty: level,
                    riddle: "This is a placeholder riddle for Level \(level), Question \(i).",
                    conceptExplanation: "Concept: Placeholder logic for level \(level).",
                    storyFragment: "Data Stream \(level).\(i) analyzing...",
                    language: language
                )
            )
        }
        return generated
    }
    
    private static func generateLevel1Questions(for language: Language) -> [Question] {
        var questions: [Question] = []

        if language == .swift {
            questions.append(Question(
                title: "Level 1 – Question 1",
                description: "Cannot find 'prnt' in scope",
                initialCode: "prnt(\"Hello, Swift!\")",
                correctCode: "print(\"Hello, Swift!\")",
                difficulty: 1,
                riddle: "I speak to the console, miss me and nothing prints.",
                conceptExplanation: "Use the correct built-in function for console output.",
                language: .swift,
                expectedPatterns: ["^print\\s*\\(.*\\)$"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hello, Swift!")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 2",
                description: "Expected '{' after 'if' condition",
                initialCode: "let x = 5\nif x > 3 print(\"Big\")",
                correctCode: "let x = 5\nif x > 3 {\n    print(\"Big\")\n}",
                difficulty: 1,
                riddle: "I wrap your block tight, without me the compiler will fight.",
                conceptExplanation: "All if blocks must be enclosed in braces {}.",
                language: .swift,
                expectedPatterns: ["if\\s*\\(?.*\\)?\\s*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Big")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 3",
                description: "Variable 'name' used before being initialized",
                initialCode: "var name: String\nprint(name)",
                correctCode: "var name: String = \"Hari\"\nprint(name)",
                difficulty: 1,
                riddle: "I give life to a variable, without me it's just an empty label.",
                conceptExplanation: "Variables must be initialized before use.",
                language: .swift,
                expectedPatterns: ["(var|let)\\s+\\w+(:\\s*\\w+)?\\s*=\\s*.*"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hari")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 4",
                description: "Missing argument label 'name:' in call",
                initialCode: "func greet(name: String) {\n    print(\"Hello \\(name)\")\n}\ngreet(\"Hari\")",
                correctCode: "func greet(name: String) {\n    print(\"Hello \\(name)\")\n}\ngreet(name: \"Hari\")",
                difficulty: 1,
                riddle: "I match the function's label, without me the function will stab.",
                conceptExplanation: "Function call must match parameter labels.",
                language: .swift,
                expectedPatterns: ["\\w+\\(.*:\\s*.*\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hello Hari")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 5",
                description: "Expected ':' after case pattern",
                initialCode: "let day = \"Monday\"\nswitch day\ncase \"Monday\":\n    print(\"Start week\")\ndefault:\n    print(\"Other day\")",
                correctCode: "let day = \"Monday\"\nswitch day {\ncase \"Monday\":\n    print(\"Start week\")\ndefault:\n    print(\"Other day\")\n}",
                difficulty: 1,
                riddle: "I tell the compiler where the case ends,\nMiss me, and error sends.",
                conceptExplanation: "Any correctly structured switch that outputs correct results passes.",
                language: .swift,
                expectedPatterns: ["switch\\s+\\w+\\s*\\{.*case\\s+.*:.*default:.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Start week")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 6",
                description: "Functions with return values must declare a return type",
                initialCode: "func add(a: Int, b: Int) {\n    return a + b\n}",
                correctCode: "func add(a: Int, b: Int) -> Int {\n    return a + b\n}",
                difficulty: 1,
                riddle: "I tell what comes back, without me the function is black.",
                conceptExplanation: "Declare the return type for functions returning a value.",
                language: .swift,
                expectedPatterns: ["func\\s+\\w+\\(.*\\)\\s*->\\s*\\w+"],
                hiddenTests: [
                    HiddenTestCase(input: "print(add(a: 2, b: 3))", expectedOutput: "5")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 7",
                description: "Cannot assign to value in condition",
                initialCode: "let x = 5\nif x = 5 {\n    print(\"Yes\")\n}",
                correctCode: "let x = 5\nif x == 5 {\n    print(\"Yes\")\n}",
                difficulty: 1,
                riddle: "I check equality, not assign reality.",
                conceptExplanation: "Use == for comparison, not =.",
                language: .swift,
                expectedPatterns: ["if\\s*\\w+\\s*==\\s*\\w+"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Yes")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 8",
                description: "Missing argument list for call",
                initialCode: "func sayHello() {\n    print(\"Hi\")\n}\nsayHello",
                correctCode: "func sayHello() {\n    print(\"Hi\")\n}\nsayHello()",
                difficulty: 1,
                riddle: "I call you properly, without me the function sleeps.",
                conceptExplanation: "All function calls require parentheses, even with no parameters.",
                language: .swift,
                expectedPatterns: ["\\w+\\(\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hi")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 9",
                description: "Cannot use keyword 'func' as identifier",
                initialCode: "let func = 5",
                correctCode: "let myFunc = 5",
                difficulty: 1,
                riddle: "I'm reserved, choose another word to be heard.",
                conceptExplanation: "Cannot use reserved keywords as variable names.",
                language: .swift,
                expectedPatterns: ["^(?!.*\\b(func|if|let|var|return|switch)\\b).+$"],
                hiddenTests: [
                    HiddenTestCase(input: "print(myFunc)", expectedOutput: "5")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 10",
                description: "Expected ',' between tuple elements",
                initialCode: "let point = (x: 5 y: 10)",
                correctCode: "let point = (x: 5, y: 10)",
                difficulty: 1,
                riddle: "I separate twins, without me they blend in.",
                conceptExplanation: "Use commas to separate tuple elements.",
                language: .swift,
                expectedPatterns: ["\\(\\w+:\\s*[^,]+,\\s*\\w+:\\s*[^)]+\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "print(point.x)", expectedOutput: "5")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 11",
                description: "Index out of range",
                initialCode: "let arr = [1, 2, 3]\nprint(arr[3])",
                correctCode: "let arr = [1, 2, 3]\nprint(arr[2])",
                difficulty: 1,
                riddle: "I start at zero, count carefully, or you'll get an error.",
                conceptExplanation: "Array indices must be within 0..<array.count.",
                language: .swift,
                expectedPatterns: ["\\w+\\[\\d+\\]"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "3")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 12",
                description: "Expected ':' in dictionary element",
                initialCode: "let dict = [\"name\" \"Hari\"]",
                correctCode: "let dict = [\"name\": \"Hari\"]",
                difficulty: 1,
                riddle: "I connect key to value, miss me and syntax fails.",
                conceptExplanation: "Use : to separate dictionary keys and values.",
                language: .swift,
                expectedPatterns: ["\\[\\s*\\w+\\s*:\\s*.+\\s*\\]"],
                hiddenTests: [
                    HiddenTestCase(input: "print(dict[\"name\"]!)", expectedOutput: "Hari")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 13",
                description: "Expected '{' after 'while' condition",
                initialCode: "var i = 0\nwhile i < 5\n    print(i)\n    i += 1",
                correctCode: "var i = 0\nwhile i < 5 {\n    print(i)\n    i += 1\n}",
                difficulty: 1,
                riddle: "I wrap loops safely, without me the compiler shouts.",
                conceptExplanation: "All loop bodies must be enclosed in {}.",
                language: .swift,
                expectedPatterns: ["while\\s*\\(?.*\\)?\\s*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "0\n1\n2\n3\n4")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 14",
                description: "Expected ',' between function parameters",
                initialCode: "func sum(a: Int b: Int) -> Int {\n    return a + b\n}",
                correctCode: "func sum(a: Int, b: Int) -> Int {\n    return a + b\n}",
                difficulty: 1,
                riddle: "I separate parameters, forget me and the compiler will glare.",
                conceptExplanation: "Function parameters must be separated by commas.",
                language: .swift,
                expectedPatterns: ["func\\s+\\w+\\(.*?,.*?\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "print(sum(a: 2, b: 3))", expectedOutput: "5")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 15",
                description: "Expected ')' before '{' or Expected '}' at end",
                initialCode: "let x = 10\nif x > 5 {\n    print(\"Big\")",
                correctCode: "let x = 10\nif x > 5 {\n    print(\"Big\")\n}",
                difficulty: 1,
                riddle: "I enclose your condition completely, miss me and syntax breaks.",
                conceptExplanation: "if conditions must have matching {}.",
                language: .swift,
                expectedPatterns: ["if\\s*\\(?.*\\)?\\s*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Big")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 16",
                description: "Type 'Circle' does not conform to protocol 'Drawable'",
                initialCode: "protocol Drawable {\n    func draw()\n}\n\nstruct Circle: Drawable {\n}",
                correctCode: "protocol Drawable {\n    func draw()\n}\n\nstruct Circle: Drawable {\n    func draw() {\n        print(\"Drawing circle\")\n    }\n}",
                difficulty: 1,
                riddle: "Protocol promises must be kept; missing methods cause compiler upset.",
                conceptExplanation: "All protocol requirements must be implemented by conforming types.",
                language: .swift,
                expectedPatterns: ["func\\s+draw\\s*\\(\\s*\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "Circle().draw()", expectedOutput: "Drawing circle")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 17",
                description: "Error is not handled because function is not marked throws",
                initialCode: "import Foundation\n\nfunc risky() {\n    throw NSError(domain: \"\", code: 1)\n}",
                correctCode: "import Foundation\n\nfunc risky() throws {\n    throw NSError(domain: \"\", code: 1)\n}",
                difficulty: 1,
                riddle: "If function throws from its core; mark it throws or compiler will roar.",
                conceptExplanation: "Functions that contain 'throw' statements must be marked with the 'throws' keyword in their signature.",
                language: .swift,
                expectedPatterns: ["func\\s+risky\\s*\\(\\s*\\)\\s+throws"],
                hiddenTests: [
                    HiddenTestCase(input: "do { try risky() } catch { print(\"Caught\") }", expectedOutput: "Caught")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 18",
                description: "String literal must include \\() for variable interpolation",
                initialCode: "let age = 20\nprint(\"I am age years old\")",
                correctCode: "let age = 20\nprint(\"I am \\(age) years old\")",
                difficulty: 1,
                riddle: "I show your variable inside the string, forget me and it's plain.",
                conceptExplanation: "Variables in strings must use \\(variable) syntax.",
                language: .swift,
                expectedPatterns: ["\\\\\\(.*\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "I am 20 years old")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 19",
                description: "Cannot assign to value: 'pi' is a 'let' constant",
                initialCode: "let pi = 3.14\npi = 3.1415",
                correctCode: "var pi = 3.14\npi = 3.1415",
                difficulty: 1,
                riddle: "I can change my mind, but constants cannot.",
                conceptExplanation: "let is used to define a constant (a value that never changes). var is used to define a variable (a value that can be updated).",
                language: .swift,
                expectedPatterns: ["var\\s+pi\\s*="],
                forbiddenPatterns: ["let\\s+pi\\s*="],
                hiddenTests: [
                    HiddenTestCase(input: "print(pi)", expectedOutput: "3.1415")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 20",
                description: "Missing return in function expected to return 'Int'",
                initialCode: "func multiply(a: Int, b: Int) -> Int {\n    a * b\n}",
                correctCode: "func multiply(a: Int, b: Int) -> Int {\n    return a * b\n}",
                difficulty: 1,
                riddle: "I send the result back, forget me and it's lost.",
                conceptExplanation: "Use return for functions that provide a value.",
                language: .swift,
                expectedPatterns: ["return\\s+.*"],
                hiddenTests: [
                    HiddenTestCase(input: "print(multiply(a: 2, b: 3))", expectedOutput: "6")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 21",
                description: "Missing parentheses in function call",
                initialCode: "var arr = [1,2,3]\narr.append 4",
                correctCode: "var arr = [1,2,3]\narr.append(4)",
                difficulty: 1,
                riddle: "I wrap my argument in parentheses, or the compiler is anxious.",
                conceptExplanation: "Method calls require parentheses around arguments.",
                language: .swift,
                expectedPatterns: ["\\w+\\.append\\(.*\\)"],
                hiddenTests: [
                    HiddenTestCase(input: "print(arr)", expectedOutput: "[1, 2, 3, 4]")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 22",
                description: "Cannot find 'a' in scope",
                initialCode: "let dict = [\"a\":1]\nprint(dict[a])",
                correctCode: "let dict = [\"a\":1]\nprint(dict[\"a\"])",
                difficulty: 1,
                riddle: "I'm a string key, miss quotes and I vanish.",
                conceptExplanation: "Dictionary keys must match type exactly.",
                language: .swift,
                expectedPatterns: ["\\[\\s*\".*\"\\s*\\]"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Optional(1)")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 23",
                description: "Cannot assign to value in condition",
                initialCode: "let flag = true\nif flag = false {\n    print(\"No\")\n}",
                correctCode: "let flag = true\nif flag == false {\n    print(\"No\")\n}",
                difficulty: 1,
                riddle: "I check truth, not assign it.",
                conceptExplanation: "Use == for Boolean comparisons.",
                language: .swift,
                expectedPatterns: ["if\\s+.*==.*\\s*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 24",
                description: "C-style for statement is unavailable in Swift",
                initialCode: "for i = 0; i<5; i++ {\n    print(i)\n}",
                correctCode: "for i in 0..<5 {\n    print(i)\n}",
                difficulty: 1,
                riddle: "I run my loop Swift-style, old C-style is not worthwhile.",
                conceptExplanation: "Use Swift for-in loops instead of C-style loops.",
                language: .swift,
                expectedPatterns: ["for\\s+\\w+\\s+in\\s+.*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "0\n1\n2\n3\n4")
                ]
            ))
            questions.append(Question(
                title: "Level 1 – Question 25",
                description: "Value of optional type 'String?' must be unwrapped",
                initialCode: "var name: String? = \"Hari\"\nif name {\n    print(name)\n}",
                correctCode: "var name: String? = \"Hari\"\nif let name = name {\n    print(name)\n}",
                difficulty: 1,
                riddle: "I unwrap safely, without me you risk a crash.",
                conceptExplanation: "Use if let for safe optional unwrapping.",
                language: .swift,
                expectedPatterns: ["if\\s+let\\s+\\w+\\s*=\\s*\\w+\\s*\\{.*\\}"],
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hari")
                ]
            ))
        } else if language == .c {
            // MARK: - Level 1 (C Language)
            // Q1 — Pointer Type Mismatch
            questions.append(Question(
                title: "Level 1 – Question 1",
                description: "Pointer Type Mismatch",
                initialCode: "#include <stdio.h>\n\nint main() {\n    int x = 10;\n    float *ptr = &x;\n    printf(\"%f\\n\", *ptr);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint main() {\n    int x = 10;\n    int *ptr = &x;\n    printf(\"%d\\n\", *ptr);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Pointers must match the type they point; mismatch leads the compiler to disappoint.",
                conceptExplanation: "Pointer type must match variable type; printf format specifier must match pointed type.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "10")
                ]
            ))

            // Q2 — Array Out-of-Bounds Access
            questions.append(Question(
                title: "Level 1 – Question 2",
                description: "Array Out-of-Bounds Access",
                initialCode: "#include <stdio.h>\n\nint main() {\n    int arr[3] = {1, 2, 3};\n    printf(\"%d\", arr[3]);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint main() {\n    int arr[3] = {1, 2, 3};\n    printf(\"%d\", arr[2]);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Arrays start at zero, don’t forget; the last index is one less than set.",
                conceptExplanation: "Array indices must be within bounds (0 to size-1).",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "3")
                ]
            ))

            // Q3 — Function Return Type Mismatch
            questions.append(Question(
                title: "Level 1 – Question 3",
                description: "Function Return Type Mismatch",
                initialCode: "#include <stdio.h>\n\nfloat sum(int a, int b) {\n    return a + b;\n}\n\nint main() {\n    int result = sum(3, 4);\n    printf(\"%d\\n\", result);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint sum(int a, int b) {\n    return a + b;\n}\n\nint main() {\n    int result = sum(3, 4);\n    printf(\"%d\\n\", result);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Return types must match what you store; otherwise warnings will roar.",
                conceptExplanation: "Return type must align with variable assignment.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "7")
                ]
            ))

            // Q4 — Confusing Postfix vs Prefix Increment
            questions.append(Question(
                title: "Level 1 – Question 4",
                description: "Confusing Postfix vs Prefix Increment",
                initialCode: "#include <stdio.h>\n\nint main() {\n    int a = 5;\n    int b = a++ + ++a;\n    printf(\"%d\\n\", b);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint main() {\n    int a = 5;\n    int b = a + (a + 1);\n    printf(\"%d\\n\", b);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Increment carefully, sequenced right; otherwise the compiler gives fright.",
                conceptExplanation: "Avoid undefined behavior from unsequenced modifications in expressions.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "11")
                ]
            ))
            
            // Q5 — Using Void Function Return
            questions.append(Question(
                title: "Level 1 – Question 5",
                description: "Using Void Function Return",
                initialCode: "#include <stdio.h>\n\nvoid greet() {\n    printf(\"Hello\\n\");\n}\n\nint main() {\n    int x = greet();\n    printf(\"%d\\n\", x);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nvoid greet() {\n    printf(\"Hello\\n\");\n}\n\nint main() {\n    greet();\n    return 0;\n}",
                difficulty: 1,
                riddle: "Void returns nothing, assign it not; use it directly, that’s the plot.",
                conceptExplanation: "Void functions cannot be assigned to variables.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "Hello")
                ]
            ))
            
            // Q6 — Conditional Assignment Confusion
            questions.append(Question(
                title: "Level 1 – Question 6",
                description: "Conditional Assignment Confusion",
                initialCode: "#include <stdio.h>\n\nint main() {\n    int a = 5, b = 10;\n    int c = (a > b ? a);\n    printf(\"%d\\n\", c);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint main() {\n    int a = 5, b = 10;\n    int c = (a > b ? a : b);\n    printf(\"%d\\n\", c);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Ternary wants both paths; forget one and it will collapse.",
                conceptExplanation: "Ternary operator must include both outcomes.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "10")
                ]
            ))
            
            // Q7 — Using Uninitialized Pointer
            questions.append(Question(
               title: "Level 1 – Question 7",
               description: "Using Uninitialized Pointer",
               initialCode: "#include <stdio.h>\n\nint main() {\n    int *ptr;\n    *ptr = 10;\n    printf(\"%d\\n\", *ptr);\n    return 0;\n}",
               correctCode: "#include <stdio.h>\n#include <stdlib.h>\n\nint main() {\n    int *ptr = malloc(sizeof(int));\n    *ptr = 10;\n    printf(\"%d\\n\", *ptr);\n    free(ptr);\n    return 0;\n}",
               difficulty: 1,
               riddle: "Pointer uninitialized is a trap; allocate memory, avoid the crash map.",
               conceptExplanation: "Pointers must point to valid memory before dereferencing.",
               language: .c,
               hiddenTests: [
                   HiddenTestCase(input: "", expectedOutput: "10")
               ]
            ))
            
            // Q8 — Wrong Use of Const
            questions.append(Question(
                title: "Level 1 – Question 8",
                description: "Wrong Use of Const",
                initialCode: "#include <stdio.h>\n\nint main() {\n    const int x = 5;\n    x = 10;\n    printf(\"%d\\n\", x);\n    return 0;\n}",
                correctCode: "#include <stdio.h>\n\nint main() {\n    int x = 5;\n    x = 10;\n    printf(\"%d\\n\", x);\n    return 0;\n}",
                difficulty: 1,
                riddle: "Const cannot be changed; respect its range.",
                conceptExplanation: "Do not assign a new value to const variables.",
                language: .c,
                hiddenTests: [
                    HiddenTestCase(input: "", expectedOutput: "10")
                ]
            ))

             // Q9 — Misusing Struct Members
             questions.append(Question(
                 title: "Level 1 – Question 9",
                 description: "Misusing Struct Members",
                 initialCode: "#include <stdio.h>\n\nstruct Point {\n    int x;\n    int y;\n};\n\nint main() {\n    struct Point p;\n    p = 10;\n    printf(\"%d\\n\", p.x);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nstruct Point {\n    int x;\n    int y;\n};\n\nint main() {\n    struct Point p;\n    p.x = 10;\n    p.y = 20;\n    printf(\"%d %d\\n\", p.x, p.y);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Structs are containers; assign to members, not the whole.",
                 conceptExplanation: "Assign values to struct fields individually, not as a whole integer.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "10 20")
                 ]
             ))

             // Q10 — Function Pointer Misuse
             questions.append(Question(
                 title: "Level 1 – Question 10",
                 description: "Function Pointer Misuse",
                 initialCode: "#include <stdio.h>\n\nvoid greet() {\n    printf(\"Hello\\n\");\n}\n\nint main() {\n    void (*fp)();\n    fp = greet();\n    fp();\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nvoid greet() {\n    printf(\"Hello\\n\");\n}\n\nint main() {\n    void (*fp)();\n    fp = greet;\n    fp();\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Assign the pointer, not the call; otherwise, the compiler will brawl.",
                 conceptExplanation: "Function pointer should store function name only, not result of call.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "Hello")
                 ]
             ))
             
             // Q11 — Array Name Misuse
             questions.append(Question(
                 title: "Level 1 – Question 11",
                 description: "Array Name Misuse",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    int arr[5] = {1,2,3,4,5};\n    printf(\"%d\\n\", arr);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int arr[5] = {1,2,3,4,5};\n    printf(\"%d\\n\", arr[0]);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "The array name points to start; to see values, pick a part.",
                 conceptExplanation: "Array names are pointers; to print a value, use an index.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "1")
                 ]
             ))
             
             // Q12 — Integer Division Confusion
             questions.append(Question(
                 title: "Level 1 – Question 12",
                 description: "Integer Division Confusion",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    int a = 5, b = 2;\n    float c = a / b;\n    printf(\"%f\\n\", c);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int a = 5, b = 2;\n    float c = (float)a / b;\n    printf(\"%f\\n\", c);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Divide with care; cast before you share.",
                 conceptExplanation: "Cast one operand to float to avoid integer division.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "2.500000")
                 ]
             ))
             
             // Q13 — Pointer Arithmetic Mistake
             questions.append(Question(
                 title: "Level 1 – Question 13",
                 description: "Pointer Arithmetic Mistake",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    int arr[3] = {1,2,3};\n    int *p = arr;\n    printf(\"%d\\n\", *p+2);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int arr[3] = {1,2,3};\n    int *p = arr;\n    printf(\"%d\\n\", *(p+2));\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Pointer plus number doesn’t just add; dereference to get the correct pad.",
                 conceptExplanation: "Pointer arithmetic must be dereferenced for correct element access.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "3")
                 ]
             ))
             
             // Q14 — Mixing Signed and Unsigned
             questions.append(Question(
                 title: "Level 1 – Question 14",
                 description: "Mixing Signed and Unsigned",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    unsigned int a = 10;\n    int b = -5;\n    if(a + b > 0)\n        printf(\"Positive\\n\");\n    else\n        printf(\"Negative\\n\");\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int a = 10;\n    int b = -5;\n    if(a + b > 0)\n        printf(\"Positive\\n\");\n    else\n        printf(\"Negative\\n\");\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Signed plus unsigned is tricky; match types or results get sticky.",
                 conceptExplanation: "Avoid mixing signed and unsigned in arithmetic.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "Positive")
                 ]
             ))
             
             // Q15 — Confusing Enum Usage
             questions.append(Question(
                 title: "Level 1 – Question 15",
                 description: "Confusing Enum Usage",
                 initialCode: "#include <stdio.h>\n\nenum Colors {RED, GREEN, BLUE};\n\nint main() {\n    int c = GREEN;\n    if(c = BLUE)\n        printf(\"Blue selected\\n\");\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nenum Colors {RED, GREEN, BLUE};\n\nint main() {\n    int c = GREEN;\n    if(c == BLUE)\n        printf(\"Blue selected\\n\");\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Enum assigns numbers, check with care; one = assigns, two == compare.",
                 conceptExplanation: "Use == to compare values, not =.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "")
                 ]
             ))
             
             // Q16 — Struct Pointer Access
             questions.append(Question(
                 title: "Level 1 – Question 16",
                 description: "Struct Pointer Access",
                 initialCode: "#include <stdio.h>\n\nstruct Point {\n    int x;\n    int y;\n};\n\nint main() {\n    struct Point p = {1,2};\n    struct Point *ptr = &p;\n    printf(\"%d\\n\", ptr.x);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nstruct Point {\n    int x;\n    int y;\n};\n\nint main() {\n    struct Point p = {1,2};\n    struct Point *ptr = &p;\n    printf(\"%d\\n\", ptr->x);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Pointer to struct uses arrow; dot is for direct care.",
                 conceptExplanation: "Use -> when accessing struct through pointer.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "1")
                 ]
             ))
             
             // Q17 — Function Prototype Missing Argument Types
             questions.append(Question(
                 title: "Level 1 – Question 17",
                 description: "Function Prototype Missing Argument Types",
                 initialCode: "#include <stdio.h>\n\nint sum();\n\nint main() {\n    printf(\"%d\\n\", sum(2,3));\n    return 0;\n}\n\nint sum(int a, int b) {\n    return a+b;\n}",
                 correctCode: "#include <stdio.h>\n\nint sum(int a, int b);\n\nint main() {\n    printf(\"%d\\n\", sum(2,3));\n    return 0;\n}\n\nint sum(int a, int b) {\n    return a+b;\n}",
                 difficulty: 1,
                 riddle: "Prototype must match; otherwise warnings will hatch.",
                 conceptExplanation: "Function declaration must include correct parameters.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "5")
                 ]
             ))
             
             // Q18 — Implicit Conversion in Return
             questions.append(Question(
                 title: "Level 1 – Question 18",
                 description: "Implicit Conversion in Return",
                 initialCode: "#include <stdio.h>\n\nint div_func() {\n    return 5/2.0;\n}\n\nint main() {\n    printf(\"%d\\n\", div_func());\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nfloat div_func() {\n    return 5/2.0;\n}\n\nint main() {\n    printf(\"%f\\n\", div_func());\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Returning int loses float’s grace; match return type to hold the space.",
                 conceptExplanation: "Return type must match value type.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "2.500000")
                 ]
             ))
             
             // Q19 — Misusing Macro
             questions.append(Question(
                 title: "Level 1 – Question 19",
                 description: "Misusing Macro",
                 initialCode: "#include <stdio.h>\n#define PI 3.14\n\nint main() {\n    float area = PI(5*5);\n    printf(\"%f\\n\", area);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n#define PI 3.14\n\nint main() {\n    float area = PI * (5*5);\n    printf(\"%f\\n\", area);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Macros are values, not a call; multiply to get the ball.",
                 conceptExplanation: "Macros are constants, not functions.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "78.500000")
                 ]
             ))
             
             // Q20 — Multiple Declaration Confusion
             questions.append(Question(
                 title: "Level 1 – Question 20",
                 description: "Multiple Declaration Confusion",
                 initialCode: "#include <stdio.h>\n\nint a = 10;\n\nint main() {\n    int a = 20;\n    printf(\"%d\\n\", a);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint a = 10;\n\nint main() {\n    printf(\"%d\\n\", a);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Global or local, choose your scope; shadowed names give logic a slope.",
                 conceptExplanation: "Avoid confusing shadowed variables.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "10")
                 ]
             ))
             
             // Q21 — Pointer to Pointer Misuse
             questions.append(Question(
                 title: "Level 1 – Question 21",
                 description: "Pointer to Pointer Misuse",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    int x = 10;\n    int *p = &x;\n    int **q = p;\n    printf(\"%d\\n\", **q);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int x = 10;\n    int *p = &x;\n    int **q = &p;\n    printf(\"%d\\n\", **q);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Double pointer needs the address of a pointer; otherwise, it cannot uncover.",
                 conceptExplanation: "A pointer-to-pointer must point to the address of a pointer.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "10")
                 ]
             ))
             
             // Q22 — Recursion Without Base Case
             questions.append(Question(
                 title: "Level 1 – Question 22",
                 description: "Recursion Without Base Case",
                 initialCode: "#include <stdio.h>\n\nint factorial(int n) {\n    return n * factorial(n-1);\n}\n\nint main() {\n    printf(\"%d\\n\", factorial(5));\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint factorial(int n) {\n    if(n == 0) return 1;\n    return n * factorial(n-1);\n}\n\nint main() {\n    printf(\"%d\\n\", factorial(5));\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Recursion must know when to stop; without it, the stack goes pop.",
                 conceptExplanation: "Recursive functions must include a base case.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "120")
                 ]
             ))
             
             // Q23 — Preprocessor Conditional Error
             questions.append(Question(
                 title: "Level 1 – Question 23",
                 description: "Preprocessor Conditional Error",
                 initialCode: "#include <stdio.h>\n\n#define DEBUG 0\n\n#if DEBUG\n    printf(\"Debug mode\\n\");\n#endif\n\nint main() {\n    printf(\"Program start\\n\");\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\n#define DEBUG 0\n\nint main() {\n#if DEBUG\n    printf(\"Debug mode\\n\");\n#endif\n    printf(\"Program start\\n\");\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Preprocessor cannot hold code alone; wrap inside functions to make it known.",
                 conceptExplanation: "#if code must be inside a function if it contains statements.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "Program start")
                 ]
             ))
             
             // Q24 — Void Pointer Arithmetic
             questions.append(Question(
                 title: "Level 1 – Question 24",
                 description: "Void Pointer Arithmetic",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    int x = 10;\n    void *ptr = &x;\n    ptr++;\n    printf(\"%d\\n\", *(int*)ptr);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int x[2] = {10, 20};\n    int *ptr = x;\n    ptr++;\n    printf(\"%d\\n\", *ptr);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Void pointers cannot increment; cast or use proper type to circumvent.",
                 conceptExplanation: "Arithmetic is not allowed on void*; must cast to appropriate type.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "20")
                 ]
             ))
             
             // Q25 — Implicit Type Casting in Array Index
             questions.append(Question(
                 title: "Level 1 – Question 25",
                 description: "Implicit Type Casting in Array Index",
                 initialCode: "#include <stdio.h>\n\nint main() {\n    double index = 2.5;\n    int arr[5] = {1,2,3,4,5};\n    printf(\"%d\\n\", arr[index]);\n    return 0;\n}",
                 correctCode: "#include <stdio.h>\n\nint main() {\n    int index = 2;\n    int arr[5] = {1,2,3,4,5};\n    printf(\"%d\\n\", arr[index]);\n    return 0;\n}",
                 difficulty: 1,
                 riddle: "Array wants whole numbers; decimals make it frown.",
                 conceptExplanation: "Array indices must be integers.",
                 language: .c,
                 hiddenTests: [
                     HiddenTestCase(input: "", expectedOutput: "3")
                 ]
             ))
        }
        return questions
    }

    private static func generateLevel2Questions(for language: Language) -> [Question] {
        var questions: [Question] = []
        
        if language == .swift {
        let commonOptions = [
            "Runtime Error: Index out of range",
            "Fatal error: Unexpectedly found nil",
            "Runtime Error: Division by zero",
            "Fatal error: Stack overflow"
        ]
        
        // 1. Array Index Out of Range
        questions.append(Question(
            title: "Level 2 – Question 1",
            description: "Identify the runtime error in this code.",
            initialCode: "func getItem(_ arr: [Int]) -> Int {\n    return arr[3]\n}\nprint(getItem([1, 2, 3]))",
            correctCode: "func getItem(_ arr: [Int]) -> Int {\n    // Fix: Check bounds\n    if arr.count > 3 { return arr[3] }\n    return 0\n}\nprint(getItem([1, 2, 3]))",
            difficulty: 2,
            riddle: "I stepped beyond the edge.",
            conceptExplanation: "Indices are 0-based. Index 3 requires 4 elements.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "func getItem(_ arr: [Int]) -> Int {\n    return arr[3]\n}\nprint(getItem([1, 2, 3]))"
        ))
        
        // 2. Nil Force Unwrap
        questions.append(Question(
            title: "Level 2 – Question 2",
            description: "Identify the runtime error.",
            initialCode: "var name: String? = nil\nprint(name!)",
            correctCode: "var name: String? = nil\nprint(name ?? \"Guest\")",
            difficulty: 2,
            riddle: "I demanded a value from nothing.",
            conceptExplanation: "Forcing an unwrap on nil causes a crash.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 1,
            language: .swift,
            hiddenTests: [],
            brokenCode: "var name: String? = nil\nprint(name!)"
        ))
        
        // 3. Division by Zero
        questions.append(Question(
            title: "Level 2 – Question 3",
            description: "Identify the runtime error.",
            initialCode: "let x = 10\nlet y = 0\nprint(x / y)",
            correctCode: "let x = 10\nlet y = 0\nif y != 0 { print(x / y) } else { print(0) }",
            difficulty: 2,
            riddle: "You cannot divide by nothing.",
            conceptExplanation: "Division by zero is undefined and crashes.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 2,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let x = 10\nlet y = 0\nprint(x / y)"
        ))
        
        // 4. Infinite Recursion
        questions.append(Question(
            title: "Level 2 – Question 4",
            description: "Identify the runtime error.",
            initialCode: "func loop(_ n: Int) {\n    loop(n + 1)\n}\nloop(0)",
            correctCode: "func loop(_ n: Int) {\n    if n > 10 { return }\n    loop(n + 1)\n}\nloop(0)",
            difficulty: 2,
            riddle: "I run usage until the stack breaks.",
            conceptExplanation: "Recursion without a base case fills the stack.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 3,
            language: .swift,
            hiddenTests: [],
            brokenCode: "func loop(_ n: Int) {\n    loop(n + 1)\n}\nloop(0)"
        ))
        
        // 5. Index Out of Range (Off by one)
        questions.append(Question(
            title: "Level 2 – Question 5",
            description: "Identify the runtime error.",
            initialCode: "let arr = [10, 20]\nfor i in 0...arr.count {\n    print(arr[i])\n}",
            correctCode: "let arr = [10, 20]\nfor i in 0..<arr.count {\n    print(arr[i])\n}",
            difficulty: 2,
            riddle: "I counted one too many.",
            conceptExplanation: "Arrays go from 0 to count-1.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let arr = [10, 20]\nfor i in 0...arr.count {\n    print(arr[i])\n}"
        ))
        
        // 6. Force Cast Error
        questions.append(Question(
            title: "Level 2 – Question 6",
            description: "Identify the runtime error.",
            initialCode: "let x: Any = \"Hello\"\nlet y = x as! Int",
            correctCode: "let x: Any = \"Hello\"\nif let y = x as? Int { print(y) }",
            difficulty: 2,
            riddle: "I pretended to be a number, but I was a word.",
            conceptExplanation: "Forced casting (as!) fails if types don't match.",
            conceptOptions: [
                "Runtime Error: Casting error",
                "Fatal error: Unexpectedly found nil",
                "Runtime Error: Index out of range",
                "Syntax Error"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let x: Any = \"Hello\"\nlet y = x as! Int"
        ))
        
        // 7. try! Error
        questions.append(Question(
            title: "Level 2 – Question 7",
            description: "Identify the runtime error.",
            initialCode: "func fail() -> String {\n    return \"Error: File not found\"\n}\nlet content = try! fail()",
            correctCode: "func fail() -> String {\n    return \"Error: File not found\"\n}\n// Use try? or do-catch\nif let content = try? fail() { print(content) }",
            difficulty: 2,
            riddle: "I insisted on success, but met failure.",
            conceptExplanation: "try! crashes if the operation throws an error.",
            conceptOptions: [
                "Fatal error: 'try!' expression unexpectedly raised an error",
                "Fatal error: Unexpectedly found nil",
                "Runtime Error: Division by zero",
                "Runtime Error: Index out of range"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "func fail() -> String {\n    return \"Error: File not found\"\n}\nlet content = try! fail()"
        ))
        
        // 8. String Index Out of Range
        questions.append(Question(
            title: "Level 2 – Question 8",
            description: "Identify the runtime error.",
            initialCode: "let str = \"Hi\"\nprint(str[5])",
            correctCode: "let str = \"Hi\"\nif str.count > 5 { print(str[5]) }",
            difficulty: 2,
            riddle: "I reached for a letter that wasn't there.",
            conceptExplanation: "Accessing string indices beyond bounds crashes.",
            conceptOptions: [
                "Fatal error: String index out of range",
                "Runtime Error: Index out of range",
                "Fatal error: Unexpectedly found nil",
                "Runtime Error: Casting error"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let str = \"Hi\"\nprint(str[5])"
        ))
        
        // 9. Remove First from Empty
        questions.append(Question(
            title: "Level 2 – Question 9",
            description: "Identify the runtime error.",
            initialCode: "var arr: [Int] = []\narr.removeFirst()",
            correctCode: "var arr: [Int] = []\nif !arr.isEmpty { arr.removeFirst() }",
            difficulty: 2,
            riddle: "I tried to take from an empty cup.",
            conceptExplanation: "Cannot remove validation from empty collection.",
            conceptOptions: [
                "Runtime Error: Can't remove first element from an empty collection",
                "Runtime Error: Index out of range",
                "Fatal error: Unexpectedly found nil",
                "Runtime Error: Division by zero"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "var arr: [Int] = []\narr.removeFirst()"
        ))
        
        // 10. Force Unwrap on Dictionary Lookup
        questions.append(Question(
            title: "Level 2 – Question 10",
            description: "Identify the runtime error.",
            initialCode: "let dict = [\"a\": 1]\nprint(dict[\"b\"]!)",
            correctCode: "let dict = [\"a\": 1]\nprint(dict[\"b\"] ?? 0)",
            difficulty: 2,
            riddle: "The key was missing, but I turned it anyway.",
            conceptExplanation: "Dictionary lookup returns optional. Force unwrapping nil crashes.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 1,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let dict = [\"a\": 1]\nprint(dict[\"b\"]!)"
        ))
        
        // 11-20: Variations / Edge Cases
        
        // 11. Remove Last from Empty
        questions.append(Question(
            title: "Level 2 – Question 11",
            description: "Identify the runtime error.",
            initialCode: "var nums: [Int] = []\nnums.removeLast()",
            correctCode: "var nums: [Int] = []\nif !nums.isEmpty { nums.removeLast() }",
            difficulty: 2,
            riddle: "I tried to take the end, but there was no beginning.",
            conceptExplanation: "Cannot remove from empty array.",
            conceptOptions: [
                "Runtime Error: Can't remove last element from an empty collection",
                "Runtime Error: Index out of range",
                "Fatal error: Stack overflow",
                "Runtime Error: Casting error"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "var nums: [Int] = []\nnums.removeLast()"
        ))
        
        // 12. Modulo by Zero (Division by Zero variant)
        questions.append(Question(
            title: "Level 2 – Question 12",
            description: "Identify the runtime error.",
            initialCode: "let a = 10\nlet b = 0\nprint(a % b)",
            correctCode: "let a = 10\nlet b = 0\nif b != 0 { print(a % b) }",
            difficulty: 2,
            riddle: "Remainders imply division, and one cannot divide by zero.",
            conceptExplanation: "Modulo by zero is also a runtime crash.",
            conceptOptions: [
                "Runtime Error: Division by zero",
                "Runtime Error: Index out of range",
                "Fatal error: Swift runtime failure",
                "Syntax Error"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let a = 10\nlet b = 0\nprint(a % b)"
        ))
        
        // 13. Double Force Unwrap
        questions.append(Question(
            title: "Level 2 – Question 13",
            description: "Identify the runtime error.",
            initialCode: "var data: String?? = nil\nprint(data!!)",
            correctCode: "var data: String?? = nil\nif let d = data, let val = d { print(val) }",
            difficulty: 2,
            riddle: "Twice the force, double the fall.",
            conceptExplanation: "Unwrapping nil at any level causes specific crash.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 1,
            language: .swift,
            hiddenTests: [],
            brokenCode: "var data: String?? = nil\nprint(data!!)"
        ))
        
        // 14. Accessing Empty String at index 0
        questions.append(Question(
            title: "Level 2 – Question 14",
            description: "Identify the runtime error.",
            initialCode: "let s = \"\"\nprint(s[0])",
            correctCode: "let s = \"\"\nif !s.isEmpty { print(s[0]) }",
            difficulty: 2,
            riddle: "I looked for the start of nothing.",
            conceptExplanation: "Empty string has no indices.",
            conceptOptions: [
                "Fatal error: String index out of range",
                "Runtime Error: Index out of range",
                "Fatal error: Unexpectedly found nil",
                "Runtime Error: Division by zero"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let s = \"\"\nprint(s[0])"
        ))

        // 15. Cast String to Double
        questions.append(Question(
             title: "Level 2 – Question 15",
             description: "Identify the runtime error.",
             initialCode: "let s: Any = \"Not a number\"\nlet d = s as! Double",
             correctCode: "let s: Any = \"Not a number\"\nif let d = s as? Double { print(d) }",
             difficulty: 2,
             riddle: "Words cannot become pure value.",
             conceptExplanation: "Invalid cast crashes the app.",
             conceptOptions: [
                 "Runtime Error: Casting error",
                 "Syntax Error",
                 "Fatal error: Unexpectedly found nil",
                 "Runtime Error: Index out of range"
             ],
             conceptCorrectAnswer: 0,
             language: .swift,
             hiddenTests: [],
             brokenCode: "let s: Any = \"Not a number\"\nlet d = s as! Double"
        ))

        // 16. Array Negative Index
        questions.append(Question(
            title: "Level 2 – Question 16",
            description: "Identify the runtime error.",
            initialCode: "let arr = [1, 2, 3]\nprint(arr[-1])",
            correctCode: "let arr = [1, 2, 3]\nif arr.indices.contains(0) { print(arr[0]) }",
            difficulty: 2,
            riddle: "I looked backward where there was no path.",
            conceptExplanation: "Negative indices are not valid in standard Arrays.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let arr = [1, 2, 3]\nprint(arr[-1])"
        ))

        // 17. Recursive Factorial without Base Case for negative
        questions.append(Question(
            title: "Level 2 – Question 17",
            description: "Identify the runtime error for input -1.",
            initialCode: "func fact(_ n: Int) -> Int {\n    if n == 0 { return 1 }\n    return n * fact(n - 1)\n}\nprint(fact(-1))",
            correctCode: "func fact(_ n: Int) -> Int {\n    if n <= 0 { return 1 }\n    return n * fact(n - 1)\n}\nprint(fact(-1))",
            difficulty: 2,
            riddle: "I went down forever looking for zero.",
            conceptExplanation: "Recursion must handle all possible inputs to terminate.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 3,
            language: .swift,
            hiddenTests: [],
            brokenCode: "func fact(_ n: Int) -> Int {\n    if n == 0 { return 1 }\n    return n * fact(n - 1)\n}\nprint(fact(-1))"
        ))

        // 18. Cast Int to Array
        questions.append(Question(
            title: "Level 2 – Question 18",
            description: "Identify the runtime error.",
            initialCode: "let x: Any = 5\nlet arr = x as! [Int]",
            correctCode: "let x: Any = 5\nif let arr = x as? [Int] { print(arr) }",
            difficulty: 2,
            riddle: "A single point cannot claim to be a line.",
            conceptExplanation: "Type mismatch in force cast.",
            conceptOptions: [
                 "Runtime Error: Casting error",
                 "Fatal error: Unexpectedly found nil",
                 "Runtime Error: Index out of range",
                 "Fatal error: Stack overflow"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let x: Any = 5\nlet arr = x as! [Int]"
        ))

        // 19. try! literal error
        questions.append(Question(
            title: "Level 2 – Question 19",
            description: "Identify the runtime error.",
            initialCode: "let x = try! String(contentsOfFile: \"ghost\")",
            correctCode: "let x = try? String(contentsOfFile: \"ghost\")",
            difficulty: 2,
            riddle: "I ignored the warning signs.",
            conceptExplanation: "Force trying a throwing call crashes on error.",
            conceptOptions: [
                "Fatal error: 'try!' expression unexpectedly raised an error", 
                "Runtime Error: Division by zero",
                "Fatal error: Stack overflow",
                "Runtime Error: Index out of range"
            ],
            conceptCorrectAnswer: 0,
            language: .swift,
            hiddenTests: [],
            brokenCode: "let x = try! String(contentsOfFile: \"ghost\")"
        ))

        // 20. Force Unwrap Result of Function
        questions.append(Question(
            title: "Level 2 – Question 20",
            description: "Identify the runtime error.",
            initialCode: "func get() -> Int? { return nil }\nprint(get()! + 1)",
            correctCode: "if let val = get() { print(val + 1) }",
            difficulty: 2,
            riddle: "I tried to add one to a shadow.",
            conceptExplanation: "Result is nil, unwrapping crashes.",
            conceptOptions: commonOptions,
            conceptCorrectAnswer: 1,
            language: .swift,
            hiddenTests: [],
            brokenCode: "func get() -> Int? { return nil }\nprint(get()! + 1)"
        ))
        
        } else if language == .c {
            // MARK: - Level 2 (C Language)
            
            // 1. Missing Semicolon
            questions.append(Question(
                title: "Level 2 – Question 1",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int x = 10\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I look complete, but one small pause is missing.",
                conceptExplanation: "Every statement in C must end with a semicolon (;).",
                conceptOptions: ["Runtime Error", "Compilation Error", "Logical Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Program never compiles, so runtime never starts.",
                    "Missing semicolon after variable declaration.",
                    "This is syntax-related, not logic.",
                    "There is a clear syntax mistake."
                ],
                language: .c
            ))

            // 2. Undeclared Variable
            questions.append(Question(
                title: "Level 2 – Question 2",
                description: "Identify the error type.",
                initialCode: "#include <stdio.h>\nint main() {\n    printf(\"%d\", value);\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I am called, but I was never declared.",
                conceptExplanation: "C requires variables to be declared before they are used.",
                conceptOptions: ["Logical Error", "Runtime Error", "Compilation Error", "No Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "This is a declaration issue.",
                    "The program fails before runtime.",
                    "value is undeclared before use.",
                    "Undeclared variables are invalid."
                ],
                language: .c
            ))

            // 3. Division by Zero
            questions.append(Question(
                title: "Level 2 – Question 3",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int a = 8;\n    int b = 0;\n    int c = a / b;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I divide by nothing and expect something.",
                conceptExplanation: "Division by zero is an invalid mathematical operation and causes a crash.",
                conceptOptions: ["Compilation Error", "Runtime Error", "Logical Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Syntax is valid.",
                    "Division by zero causes runtime failure.",
                    "The issue appears only during execution.",
                    "Division by zero is invalid."
                ],
                language: .c
            ))

            // 4. Array Out of Bounds
            questions.append(Question(
                title: "Level 2 – Question 4",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int arr[4] = {1, 2, 3, 4};\n    int x = arr[4];\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I step one place beyond my limit.",
                conceptExplanation: "Arrays are 0-indexed. Accessing index 4 in a size 4 array is out of bounds.",
                conceptOptions: ["Logical Error", "Compilation Error", "Undefined Behavior", "No Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "This accesses invalid memory.",
                    "Compiler does not detect runtime bounds.",
                    "Valid indexes are 0–3. Index 4 is out of bounds.",
                    "Index exceeds array size."
                ],
                language: .c
            ))

            // 5. Assignment in Condition
            questions.append(Question(
                title: "Level 2 – Question 5",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int x = 3;\n    if(x = 2)\n        x++;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I compare… but secretly assign.",
                conceptExplanation: "Using assignment (=) instead of comparison (==) always evaluates to the assigned value.",
                conceptOptions: ["Compilation Error", "Runtime Error", "No Error", "Logical Error"],
                conceptCorrectAnswer: 3,
                conceptOptionsExplanations: [
                    "Syntax is valid.",
                    "Code runs, but logic is incorrect.",
                    "Condition logic is flawed.",
                    "Assignment used instead of comparison."
                ],
                language: .c
            ))

            // 6. Uninitialized Variable
            questions.append(Question(
                title: "Level 2 – Question 6",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int x;\n    int y = x + 1;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I exist, but I hold random memory.",
                conceptExplanation: "Using a variable before initializing it leads to unpredictable results.",
                conceptOptions: ["Compilation Error", "Undefined Behavior", "Runtime Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Syntax is valid.",
                    "x is uninitialized before use.",
                    "It may not crash, but value is unpredictable.",
                    "Uninitialized variables are unsafe."
                ],
                language: .c
            ))

            // 7. NULL Pointer Dereference
            questions.append(Question(
                title: "Level 2 – Question 7",
                description: "Identify the error type.",
                initialCode: "#include <stddef.h>\nint main() {\n    int *p = NULL;\n    *p = 7;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I point to nothing and try to write.",
                conceptExplanation: "NULL is a pointer to address 0. Writing to it crashes the program.",
                conceptOptions: ["Compilation Error", "Logical Error", "Runtime Error", "No Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "Syntax is valid.",
                    "This is a memory access violation.",
                    "Dereferencing NULL causes crash.",
                    "NULL cannot be dereferenced."
                ],
                language: .c
            ))

            // 8. Double Free
            questions.append(Question(
                title: "Level 2 – Question 8",
                description: "Identify the error type.",
                initialCode: "#include <stdlib.h>\nint main() {\n    int *p = malloc(sizeof(int));\n    free(p);\n    free(p);\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I free what is already gone.",
                conceptExplanation: "Freeing memory that has already been deallocated corrupts the heap.",
                conceptOptions: ["Logical Error", "Compilation Error", "No Error", "Undefined Behavior"],
                conceptCorrectAnswer: 3,
                conceptOptionsExplanations: [
                    "This is a memory management issue.",
                    "Syntax is valid.",
                    "Double freeing is invalid.",
                    "Freeing memory twice corrupts memory state."
                ],
                language: .c
            ))

            // 9. Printf Format Mismatch
            questions.append(Question(
                title: "Level 2 – Question 9",
                description: "Identify the error type.",
                initialCode: "#include <stdio.h>\nint main() {\n    double x = 5.2;\n    printf(\"%d\", x);\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I wear the wrong identity when printing.",
                conceptExplanation: "Printf expects an integer for %d, but a double was provided.",
                conceptOptions: ["Compilation Error", "Runtime Error", "Undefined Behavior", "No Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "Compiler may warn but allows it.",
                    "It may print garbage, not necessarily crash.",
                    "%d expects int, not double.",
                    "Format specifier is incorrect."
                ],
                language: .c
            ))

            // 10. Undeclared Input Variable
            questions.append(Question(
                title: "Level 2 – Question 10",
                description: "Identify the error type.",
                initialCode: "#include <stdio.h>\nint main() {\n    scanf(\"%d\", &x);\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I speak without being introduced.",
                conceptExplanation: "Scanf requires a variable to store the value. x is not defined.",
                conceptOptions: ["Runtime Error", "Compilation Error", "Logical Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Program fails before execution.",
                    "x is undeclared.",
                    "Declaration is missing.",
                    "Variable must be defined first."
                ],
                language: .c
            ))

            // 11. Updating Const Variable
            questions.append(Question(
                title: "Level 2 – Question 11",
                description: "Identify the error type.",
                initialCode: "int main() {\n    const int a = 4;\n    a = 9;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I promise to never change.",
                conceptExplanation: "The const keyword signifies a variable that cannot be reassigned.",
                conceptOptions: ["No Error", "Runtime Error", "Logical Error", "Compilation Error"],
                conceptCorrectAnswer: 3,
                conceptOptionsExplanations: [
                    "Const variables are immutable.",
                    "Code fails at compile time.",
                    "Violates const rule.",
                    "Cannot modify a const variable."
                ],
                language: .c
            ))

            // 12. Dereferencing Uninitialized Pointer
            questions.append(Question(
                title: "Level 2 – Question 12",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int *p;\n    int value = *p;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I point somewhere unknown.",
                conceptExplanation: "Uninitialized pointers point to random memory locations. Dereferencing them is dangerous.",
                conceptOptions: ["Compilation Error", "Runtime Error", "Logical Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Syntax valid.",
                    "Uninitialized pointer dereference.",
                    "Memory is accessed without initialization.",
                    "Pointer must be initialized."
                ],
                language: .c
            ))

            // 13. Unclosed Brace
            questions.append(Question(
                title: "Level 2 – Question 13",
                description: "Identify the error type.",
                initialCode: "int main() {\n    if(1) {\n        return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I open a block and forget to close it.",
                conceptExplanation: "Every opening brace '{' must have a corresponding closing brace '}'.",
                conceptOptions: ["Logical Error", "No Error", "Compilation Error", "Runtime Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "This is structural syntax issue.",
                    "Code block incomplete.",
                    "Missing closing brace.",
                    "Compilation fails first."
                ],
                language: .c
            ))

            // 14. Negative Index Access
            questions.append(Question(
                title: "Level 2 – Question 14",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int arr[3];\n    arr[-2] = 10;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I use a negative door to enter memory.",
                conceptExplanation: "Accessing negative indices in C results in accessing memory before the array starts.",
                conceptOptions: ["Logical Error", "Compilation Error", "No Error", "Undefined Behavior"],
                conceptCorrectAnswer: 3,
                conceptOptionsExplanations: [
                    "Memory corruption occurs.",
                    "Compiler does not detect.",
                    "Index must be >= 0.",
                    "Negative index accesses invalid memory."
                ],
                language: .c
            ))

            // 15. Too Small Malloc
            questions.append(Question(
                title: "Level 2 – Question 15",
                description: "Identify the error type.",
                initialCode: "#include <stdlib.h>\nint main() {\n    int *p = malloc(1);\n    p[1] = 5;\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I allocate less than I need.",
                conceptExplanation: "Allocating 1 byte is not sufficient to store an array of integers.",
                conceptOptions: ["Logical Error", "Undefined Behavior", "Compilation Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Memory overflow risk.",
                    "Allocated 1 byte but accessing beyond.",
                    "Syntax is valid.",
                    "Allocation insufficient."
                ],
                language: .c
            ))

            // 16. Returning Address of Local Variable
            questions.append(Question(
                title: "Level 2 – Question 16",
                description: "Identify the error type.",
                initialCode: "int* func() {\n    int x = 5;\n    return &x;\n}\nint main() {\n    int *p = func();\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I return something that no longer lives.",
                conceptExplanation: "Local variables are destroyed when a function returns. Returning their address is invalid.",
                conceptOptions: ["Compilation Error", "No Error", "Undefined Behavior", "Runtime Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "Syntax valid.",
                    "Causes dangling pointer.",
                    "Returning address of local variable.",
                    "Memory becomes invalid after function exits."
                ],
                language: .c
            ))

            // 17. Void Return from Int Function
            questions.append(Question(
                title: "Level 2 – Question 17",
                description: "Identify the error type.",
                initialCode: "int test() {\n    int a = 3;\n}\nint main() {\n    int x = test();\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I forget to return what I promise.",
                conceptExplanation: "A function declared to return an int must return a value.",
                conceptOptions: ["Runtime Error", "Logical Error", "No Error", "Compilation Error"],
                conceptCorrectAnswer: 3,
                conceptOptionsExplanations: [
                    "Fails at compile stage.",
                    "Missing required return.",
                    "Return statement required.",
                    "Non-void function must return value."
                ],
                language: .c
            ))

            // 18. Infinite For Loop
            questions.append(Question(
                title: "Level 2 – Question 18",
                description: "Identify the error type.",
                initialCode: "int main() {\n    for(;;) {\n    }\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I loop without escape.",
                conceptExplanation: "An empty for(;;) creates a loop that runs forever.",
                conceptOptions: ["Compilation Error", "Logical Error", "Runtime Error", "No Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "Syntax valid.",
                    "Infinite loop with no break.",
                    "Program hangs but does not crash.",
                    "Logic has no termination."
                ],
                language: .c
            ))

            // 19. Missing Switch Break
            questions.append(Question(
                title: "Level 2 – Question 19",
                description: "Identify the error type.",
                initialCode: "#include <stdio.h>\nint main() {\n    int x = 2;\n    switch(x) {\n        case 2: printf(\"Two\");\n        case 3: printf(\"Three\");\n    }\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I fall through when I should stop.",
                conceptExplanation: "Missing a break; statement causes the program to fall through to the next case.",
                conceptOptions: ["Compilation Error", "Runtime Error", "Logical Error", "No Error"],
                conceptCorrectAnswer: 2,
                conceptOptionsExplanations: [
                    "Syntax valid.",
                    "Code executes but unintended logic.",
                    "Missing break after case 2 causes fallthrough.",
                    "Break is required."
                ],
                language: .c
            ))

            // 20. Variable Shadowing
            questions.append(Question(
                title: "Level 2 – Question 20",
                description: "Identify the error type.",
                initialCode: "int main() {\n    int x = 5;\n    {\n        int x = 7;\n    }\n    return 0;\n}",
                correctCode: "",
                difficulty: 2,
                riddle: "I shadow what already exists.",
                conceptExplanation: "Shadowing variables in nested scopes is valid in C.",
                conceptOptions: ["Compilation Error", "No Error", "Runtime Error", "Logical Error"],
                conceptCorrectAnswer: 1,
                conceptOptionsExplanations: [
                    "C allows inner scope redeclaration.",
                    "This is valid variable shadowing.",
                    "No runtime issue.",
                    "Behavior is well-defined."
                ],
                language: .c
            ))
        }
        return questions
    }
}

// Extension to map legacy/previous static data to new Init
extension Question {
    static let allQuestions: [Question] = []

    static let genreQuestions: [GenreQuestion] = [
        // Cricket
        GenreQuestion(text: "Who has the most centuries in International Cricket?", options: ["Sachin Tendulkar", "Virat Kohli", "Ricky Ponting", "Steve Smith"], correctAnswerIndex: 0, genre: .cricket),
        GenreQuestion(text: "Which country won the first ever Cricket World Cup in 1975?", options: ["Australia", "West Indies", "England", "India"], correctAnswerIndex: 1, genre: .cricket),
        GenreQuestion(text: "How many balls are in a standard over?", options: ["5", "6", "7", "8"], correctAnswerIndex: 1, genre: .cricket),
        
        // Football
        GenreQuestion(text: "Which player has won the most Ballon d'Or awards?", options: ["Cristiano Ronaldo", "Lionel Messi", "Pele", "Diego Maradona"], correctAnswerIndex: 1, genre: .football),
        GenreQuestion(text: "Which country has won the most FIFA World Cups?", options: ["Germany", "Italy", "Brazil", "Argentina"], correctAnswerIndex: 2, genre: .football),
        GenreQuestion(text: "Which club has won the most UEFA Champions League titles?", options: ["Barcelona", "AC Milan", "Liverpool", "Real Madrid"], correctAnswerIndex: 3, genre: .football),
        
        // Anime
        GenreQuestion(text: "What is the highest-grossing anime film of all time?", options: ["Spirited Away", "Your Name", "Demon Slayer: Mugen Train", "One Piece Red"], correctAnswerIndex: 2, genre: .anime),
        GenreQuestion(text: "In 'Naruto', what is the name of the nine-tailed fox?", options: ["Shukaku", "Kurama", "Matatabi", "Gyuki"], correctAnswerIndex: 1, genre: .anime),
        GenreQuestion(text: "Who is known as the 'Pirate Hunter' in One Piece?", options: ["Sanji", "Luffy", "Zoro", "Usopp"], correctAnswerIndex: 2, genre: .anime)
    ]
}
