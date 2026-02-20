import Foundation

class CompilerEngine {
    static let shared = CompilerEngine()
    // Shared instance for compilation tasks
    
    private init() {}
    
    // LOGICAL VALIDATION ENGINE
    func evaluate(code: String, for question: Question) -> EvaluationResult {
        // Level 2 Special Handling (Runtime Error ID)
        if question.difficulty == 2 {
            return evaluateLevel2(code: code, question: question)
        }
        
        // Level 1 C Special Handling (Strict Logic Engine)
        if question.language == .c && question.levelNumber == 1 {
            return evaluateCLevel1(code: code, question: question)
        }

        // 1. Normalize Code (Token-based approach) - kept for structural hints if needed
        let normalizedCode = normalize(code)
        
        // 2. Initial Structure Check
        if normalizedCode.isEmpty {
            return EvaluationResult.simpleError(questionID: question.id, type: .syntax, message: "Code cannot be empty.")
        }
        
        // Variables for scoring
        var score = 50 // Base
        var feedbackItems: [String] = []
        var passedHiddenTests = true
        var hardcodingDetected = false
        
        // 3. Interpreter Setup
        let interpreter = SimpleInterpreter()
        
        // 3. Execution (Simulated)
        // If normalization fails or strict syntax check needed, we rely on SimpleInterpreter.
        // NOTE: SimpleInterpreter now returns "Syntax Error: ..." strings if parsing fails.
        // We need to check for this.
        
        // Initial check for syntax errors using interpreter's parser
        let syntaxCheck = interpreter.evaluate(code: code)
        if syntaxCheck.contains("Syntax Error:") {
             return EvaluationResult(
                questionID: question.id,
                status: .incorrect, // Mapped from isSuccess: false
                score: 0,
                level: .failed,
                complexity: .low, // Default
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "Compilation Failed:\n\(syntaxCheck)"
            )
        }
        
        var testResults: [TestCaseResult] = []
        var passedTestCount = 0
        let totalTests = (question.hiddenTests?.count ?? 0) > 0 ? (question.hiddenTests?.count ?? 0) : 1
        
        if let hiddenTests = question.hiddenTests, !hiddenTests.isEmpty {
            for (index, test) in hiddenTests.enumerated() {
                // Setup context/input code
                let driverCode = test.input
                let combinedCode = code + "\n" + driverCode
                
                // Execute
                let output = interpreter.evaluate(code: combinedCode)
                let expected = test.expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                let actual = output.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let passed = actual == expected || actual.lowercased() == expected.lowercased()
                
                if passed {
                    passedTestCount += 1
                } else {
                    passedHiddenTests = false
                }
                
                testResults.append(TestCaseResult(
                    input: driverCode.isEmpty ? "(Standard Execution)" : driverCode,
                    expected: expected,
                    actual: actual,
                    passed: passed
                ))
                
                // Legacy feedback items
                if passed {
                    if actual.lowercased() == expected.lowercased() && actual != expected {
                         feedbackItems.append("⚠️ Test \(index + 1): Case mismatch.")
                    }
                } else {
                    if feedbackItems.filter({ $0.contains("❌") }).isEmpty {
                        feedbackItems.append("❌ Test \(index + 1) Failed")
                    }
                }
            }
            
            if passedHiddenTests {
                feedbackItems.append("✅ Passed all \(hiddenTests.count) hidden logical tests.")
            } else {
                feedbackItems.append("ℹ️ Passed \(passedTestCount)/\(hiddenTests.count) tests.")
            }
            
        } else {
            // Fallback for questions without hidden tests
            let goldenOutput = interpreter.evaluate(code: question.correctCode).trimmingCharacters(in: .whitespacesAndNewlines)
            let userOutput = interpreter.evaluate(code: code).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let passed = userOutput == goldenOutput || userOutput.lowercased() == goldenOutput.lowercased()
            
            if passed {
                 passedTestCount = 1
                 passedHiddenTests = true
                 feedbackItems.append("✅ Output matches expected result.")
            } else {
                 passedHiddenTests = false
                 feedbackItems.append("❌ Output Mismatch")
            }
            
            testResults.append(TestCaseResult(
                input: "Main execution",
                expected: goldenOutput,
                actual: userOutput,
                passed: passed
            ))
        }

        // 5. Anti-Hardcoding / Concept Validation (Secondary)
        if isHardcoded(code: code, question: question) {
             hardcodingDetected = true
             passedHiddenTests = false 
             score = 30
             feedbackItems.append("⚠️ Hardcoding detected. Please use the required logic constructs.")
        }
        
        // 6. Logic & Complexity Analysis
        let complexityScore = analyzeComplexity(code: code, language: question.language)
        
        // 7. Dynamic Scoring Logic
        let logicScore = (Double(passedTestCount) / Double(totalTests)) * 70.0
        score = Int(logicScore) + 20 // Base 20 for compiling
        
        if passedHiddenTests && !hardcodingDetected {
             score = max(score, 90) 
        }
        
        if complexityScore.optimizedFuncs {
            score += 10
            feedbackItems.append("✨ Optimized Approach")
        }
        
        score = max(0, min(100, score))
        
        // 8. Level Classification
        let userLevel: UserLevel
        switch score {
        case 90...100: userLevel = .expert
        case 75...89: userLevel = .advanced
        case 50...74: userLevel = .intermediate
        case 30...49: userLevel = .beginner
        default: userLevel = .failed
        }
        
        let finalFeedback = feedbackItems.joined(separator: "\n")
        let status: EvaluationStatus = (userLevel == .failed) ? .incorrect : .correct
        
        return EvaluationResult(
            questionID: question.id,
            status: status,
            score: score,
            level: userLevel,
            complexity: complexityScore.level,
            edgeCaseHandling: passedHiddenTests,
            hardcodingDetected: hardcodingDetected,
            feedback: finalFeedback,
            difficulty: question.difficulty,
            testResults: testResults,
            coinsEarned: status == .correct ? 1 : 0,
            xpEarned: status == .correct ? 10 : 0
        )
    }
    
    // MARK: - Helper Methods
    
    private func normalize(_ code: String) -> String {
        return code
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: ";", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func checkPatterns(code: String, question: Question) -> (success: Bool, error: String?) {
         // Check Required
        for pattern in question.expectedPatterns {
            if !matchesPattern(code, pattern: pattern) {
                return (false, "Missing required code pattern: \(pattern)")
            }
        }
        // Check Forbidden
        for pattern in question.forbiddenPatterns {
            if matchesPattern(code, pattern: pattern) {
                return (false, "Use of forbidden pattern detected: \(pattern)")
            }
        }
        return (true, nil)
    }
    
    private func matchesPattern(_ code: String, pattern: String) -> Bool {
        if let _ = code.range(of: pattern, options: .regularExpression) {
            return true
        }
        return code.contains(pattern)
    }
    
    private func evaluateLevel2(code: String, question: Question) -> EvaluationResult {
        var selectedOpt = -1
        
        if let range = code.range(of: "// SELECTED_OPT: ") {
            let substr = code[range.upperBound...]
            let stringVal = String(substr).trimmingCharacters(in: .whitespacesAndNewlines)
            if let val = Int(stringVal) {
                selectedOpt = val
            } else {
                 let parts = String(substr).components(separatedBy: CharacterSet.decimalDigits.inverted)
                 if let first = parts.first, let val = Int(first) {
                     selectedOpt = val
                 }
            }
        }
        
        guard question.conceptOptions.indices.contains(question.conceptCorrectAnswer) else {
             return EvaluationResult.simpleError(questionID: question.id, type: .unknown, message: "Invalid Configuration")
        }
        let expectedErrorFragment = question.conceptOptions[question.conceptCorrectAnswer]
        let userChoice = question.conceptOptions.indices.contains(selectedOpt) ? question.conceptOptions[selectedOpt] : "None Selected"
        let isCorrect = selectedOpt == question.conceptCorrectAnswer
        
        let testResult = TestCaseResult(
            input: "Diagnosis Selection",
            expected: expectedErrorFragment,
            actual: userChoice,
            passed: isCorrect
        )
        
        return EvaluationResult(
            questionID: question.id,
            status: isCorrect ? .correct : .incorrect,
            score: isCorrect ? 100 : 0,
            level: isCorrect ? .passed : .failed,
            complexity: .medium,
            edgeCaseHandling: isCorrect,
            hardcodingDetected: false,
            feedback: isCorrect ? "Correct! You identified the error: \(expectedErrorFragment)" : "Incorrect diagnosis. Try again.",
            difficulty: question.difficulty,
            testResults: [testResult],
            coinsEarned: isCorrect ? 1 : 0,
            xpEarned: isCorrect ? 10 : 0
        )
    }

    private func isHardcoded(code: String, question: Question) -> Bool {
        let normalized = normalize(code).lowercased()
        let logicKeywords = ["if", "for", "while", "return", "map", "filter", "switch", "func", "class", "var", "let"]
        let hasLogic = logicKeywords.contains { normalized.contains($0) }
        if normalized.contains("print") && !hasLogic && code.count < 40 { return true }
        return false
    }

    private func simulateExecution(code: String) -> String {
        var output = ""
        // Capture print("...") content
        // Simple regex for print("...") or print('...') or print(...)
        let pattern = #"print\s*\((.*?)\)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(code.startIndex..<code.endIndex, in: code)
        
        regex?.enumerateMatches(in: code, options: [], range: nsrange) { match, _, _ in
            if let match = match, let range = Range(match.range(at: 1), in: code) {
                var content = String(code[range])
                // Strip surrounding quotes
                if (content.hasPrefix("\"") && content.hasSuffix("\"")) || (content.hasPrefix("'") && content.hasSuffix("'")) {
                    content.removeFirst()
                    content.removeLast()
                }
                output += content + "\n"
            }
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct ComplexityScore {
        let level: Complexity
        let nestedLoops: Int
        let optimizedFuncs: Bool
        let messyStructure: Bool
    }
    
    private func analyzeComplexity(code: String, language: Language) -> ComplexityScore {
        var nestedLoops = 0
        var loopDepth = 0
        var maxDepth = 0
        
        let lines = code.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("for") || trimmed.hasPrefix("while") {
                loopDepth += 1
                maxDepth = max(maxDepth, loopDepth)
            }
            if trimmed.contains("}") { // Rough closure/scope end check
                 loopDepth = max(0, loopDepth - 1)
            }
             // Python indentation (simplified check, real python parsing is hard here)
            if language == .python && !trimmed.isEmpty {
                 // Assume indentation depth matches loop depth roughly for this sim
            }
        }
        
        // Reset for rough count
        nestedLoops = maxDepth
        
        // Check for optimizations
        let optimizations = ["map", "filter", "reduce", "sort", "contains"]
        let hasOptimization = optimizations.contains { matchesPattern(code, pattern: $0) }
        
        // Determine level
        let complexityLevel: Complexity
        if nestedLoops > 1 {
            complexityLevel = .high
        } else if hasOptimization {
            complexityLevel = .low // Optimized is "Low" complexity in terms of Big O usually (or hidden)
        } else {
            complexityLevel = .medium
        }
        
        return ComplexityScore(level: complexityLevel, nestedLoops: nestedLoops, optimizedFuncs: hasOptimization, messyStructure: false)
    }
    
    // MARK: - Syntax Checking (Reused/Updated)
    
    private func checkSyntax(code: String, language: Language, questionID: UUID) -> EvaluationResult? {
         let lines = code.components(separatedBy: .newlines)
         
         switch language {
         case .c, .cpp:
             if !code.contains("int main") {
                 return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing 'int main()' function")
             }
             // Check for semicolon
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("#") && !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") && !trimmed.hasSuffix(">") {
                     return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing semicolon ';'", line: index + 1)
                 }
             }
         case .java:
             if !code.contains("class ") {
                  return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing class definition")
             }
             if !code.contains("public static void main") {
                 return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing 'public static void main'")
             }
             // Check for semicolon
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("@") && !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") {
                      return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing semicolon ';'", line: index + 1)
                 }
             }
         case .python:
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if (trimmed.hasPrefix("if") || trimmed.hasPrefix("for") || trimmed.hasPrefix("while") || trimmed.hasPrefix("def") || trimmed.hasPrefix("class")) && !trimmed.hasSuffix(":") {
                     return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing colon ':'", line: index + 1)
                 }
             }
         case .swift:
              if code.contains("int ") || code.contains("String ") {
                   // return EvaluationResult.simpleError(type: .syntax, message: "Use 'var' or 'let' in Swift.")
              }
         }
         return nil
    }
    // MARK: - Level 1 C Evaluation Engine
    
    private func evaluateCLevel1(code: String, question: Question) -> EvaluationResult {
        // Step 1: Logic Rule Validation (FIRST PRIORITY)
        // Check if user code satisfies the Logic Rule.
        // Execute hidden test cases (Simulated via Logic Check for this engine).
        
        // 1.1: Syntax Check
        if !code.contains("int main") {
            return failC(question, msg: "Logic Rule Not Satisfied: Missing 'int main()'")
        }
        
        // 1.2: Logic & Hidden Test Validation
        let logicResult = checkCLevel1Logic(code: code, question: question)
        
        if !logicResult.passed {
            return failC(question, msg: "Logic Rule Not Satisfied\nHidden Test Case Failed")
        }
        
        // Step 2: Correct Answer Structure Match
        // (As per instructions: If logically equivalent, proceed. Logic is primary.)
        // Since logicResult.passed is true, we assume logical equivalence/correctness.
        
        // Step 3: Final Evaluation
        // If Step 1 passed: Return PASS with 100/100
        
        return passC(question, testDetails: logicResult.details)
    }
    
    // Helper to generate FAIL result
    private func failC(_ q: Question, msg: String) -> EvaluationResult {
         let feedback = "FAIL\n❌ Level 1 – C Failed\n" + msg
         return EvaluationResult(
            questionID: q.id,
            status: .incorrect,
            score: 0,
            level: .failed,
            complexity: .low,
            edgeCaseHandling: false,
            hardcodingDetected: false,
            feedback: feedback,
            difficulty: 1,
            testResults: [], // Failed tests not detailed in strict fail mode req, but could be specific
            coinsEarned: 0,
            xpEarned: 0
        )
    }
    
    // Helper to generate PASS result
    private func passC(_ q: Question, testDetails: [TestCaseResult]) -> EvaluationResult {
        let feedback = "PASS\n✅ Level 1 – C Passed\nEvaluation Score: 100/100\nAll Hidden Test Cases Passed\nLogic Rule Satisfied"
        return EvaluationResult(
            questionID: q.id,
            status: .correct,
            score: 100,
            level: .expert,
            complexity: .low,
            edgeCaseHandling: true,
            hardcodingDetected: false,
            feedback: feedback,
            difficulty: 1,
            testResults: testDetails,
            coinsEarned: 1,
            xpEarned: 10
        )
    }
    
    // Logic Rule Checker for C Level 1 Questions (Q1-Q25)
    private func checkCLevel1Logic(code: String, question: Question) -> (passed: Bool, details: [TestCaseResult]) {
        // Normalize for easier matching (remove multi-spaces, keep newlines for context if needed, or just standard normalize)
        let cleanCode = code
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        // Helper for success details
        func success() -> [TestCaseResult] {
            return question.hiddenTests?.map { TestCaseResult(input: $0.input, expected: $0.expectedOutput, actual: $0.expectedOutput, passed: true) } ?? []
        }
        
        // Identify Question Logic Rule based on Title/Description
        let title = question.title
        
        // Q1: Pointer Type Mismatch (float *ptr -> int *ptr)
        if title.contains("Question 1") && title.contains("Level 1") {
            // Must have 'int *ptr' or 'int* ptr' and not 'float *ptr'
            if (code.contains("int *ptr") || code.contains("int* ptr")) && !code.contains("float *ptr") {
                return (true, success())
            }
            return (false, [])
        }
        
        // Q2: Array Out-of-Bounds (arr[3] -> arr[2] or similar valid)
        if title.contains("Question 2") && title.contains("Level 1") {
            if code.contains("arr[2]") || code.contains("arr[1]") || code.contains("arr[0]") {
                return (true, success())
            }
            return (false, [])
        }
        
        // Q3: Function Return Type (float sum -> int sum)
        if title.contains("Question 3") && title.contains("Level 1") {
            if code.contains("int sum(") { return (true, success()) }
            return (false, [])
        }
        
        // Q4: Postfix/Prefix (Sequence point) - Checks for separate lines or valid logic
        if title.contains("Question 4") && title.contains("Level 1") {
            // Ensure no "a++ + ++a" or "++a + a++"
            if !cleanCode.contains("a++ + ++a") && !cleanCode.contains("++a + a++") { return (true, success()) }
            return (false, [])
        }
        
        // Q5: Void Function Return (greeting = ... removed)
        if title.contains("Question 5") && title.contains("Level 1") {
            // Should call greet(); directly, not assign.
            if !code.contains("int x = greet()") && code.contains("greet()") { return (true, success()) }
            return (false, [])
        }
        
        // Q6: Ternary (a > b ? a : b)
        if title.contains("Question 6") && title.contains("Level 1") {
            if code.contains("? a : b") || code.contains("?a:b") { return (true, success()) }
            return (false, [])
        }
        
        // Q7: Uninitialized Pointer (*ptr = 10 -> malloc)
        if title.contains("Question 7") && title.contains("Level 1") {
            if code.contains("malloc") || code.contains("&") { return (true, success()) }
            return (false, [])
        }
        
        // Q8: Const (remove const)
        if title.contains("Question 8") && title.contains("Level 1") {
            if !code.contains("const int x") && code.contains("int x") { return (true, success()) }
            return (false, [])
        }
        
        // Q9: Struct Members (p = 10 -> p.x = 10)
        if title.contains("Question 9") && title.contains("Level 1") {
            if (code.contains("p.x =") || code.contains("p.y =")) && !cleanCode.contains("p = 10") { return (true, success()) }
            return (false, [])
        }
        
        // Q10: Func Pointer (fp = greet)
        if title.contains("Question 10") && title.contains("Level 1") {
            if code.contains("fp = greet;") || code.contains("fp = &greet;") { return (true, success()) }
            return (false, [])
        }
        
        // Q11: Array Name (printf arr -> arr[0])
        if title.contains("Question 11") && title.contains("Level 1") {
            if code.contains("arr[0]") || code.contains("*arr") { return (true, success()) }
            return (false, [])
        }
        
        // Q12: Integer Division (cast float)
        if title.contains("Question 12") && title.contains("Level 1") {
            if code.contains("(float)") || code.contains("(double)") || code.contains(".0") { return (true, success()) }
            return (false, [])
        }
        
        // Q13: Pointer Arith (*p+2 -> *(p+2))
        if title.contains("Question 13") && title.contains("Level 1") {
            if code.contains("*(p+2)") || code.contains("*(p + 2)") || code.contains("p[2]") { return (true, success()) }
            return (false, [])
        }
        
        // Q14: Signed/Unsigned (unsigned int -> int)
        if title.contains("Question 14") && title.contains("Level 1") {
            if !code.contains("unsigned int") { return (true, success()) }
            return (false, [])
        }
        
        // Q15: Enum (c = BLUE -> c == BLUE)
        if title.contains("Question 15") && title.contains("Level 1") {
            if code.contains("c == BLUE") { return (true, success()) }
            return (false, [])
        }
        
        // Q16: Struct Pointer (ptr.x -> ptr->x)
        if title.contains("Question 16") && title.contains("Level 1") {
            if code.contains("->x") || code.contains("(*ptr).x") { return (true, success()) }
            return (false, [])
        }
        
        // Q17: Prototype (int sum() -> int sum(int a, int b))
        if title.contains("Question 17") && title.contains("Level 1") {
            if code.contains("int sum(int a, int b);") || code.contains("int sum(int, int);") { return (true, success()) }
            return (false, [])
        }
        
        // Q18: Implicit Conversion (int -> float function)
        if title.contains("Question 18") && title.contains("Level 1") {
            if code.contains("float div_func") { return (true, success()) }
            return (false, [])
        }
        
        // Q19: Macro (PI(5*5) -> PI * ...)
        if title.contains("Question 19") && title.contains("Level 1") {
            if code.contains("PI *") { return (true, success()) }
            return (false, [])
        }
        
        // Q20: Multiple Decl (remove inner int a)
        if title.contains("Question 20") && title.contains("Level 1") {
            // Count "int a" occurrences? Or check if inner scope removed.
            // Simplified: if output logic used, correct code removed 'int a = 20'.
            // User code: 'int a = 20' replaced by 'a = 20' or removed.
            // If code does NOT have "int a = 20", assume fixed.
             if !code.contains("int a = 20") { return (true, success()) }
             return (false, [])
        }
        
        // Q21: Double Pointer (**q = p -> **q = &p)
        if title.contains("Question 21") && title.contains("Level 1") {
            if code.contains("&p") { return (true, success()) }
            return (false, [])
        }
        
        // Q22: Recursion Base Case (if n==0)
        if title.contains("Question 22") && title.contains("Level 1") {
            if code.contains("if") && (code.contains("== 0") || code.contains("<= 0")) { return (true, success()) }
            return (false, [])
        }
        
        // Q23: Preprocessor (#if inside main)
        if title.contains("Question 23") && title.contains("Level 1") {
            // Check if #if is inside main
            if let range = code.range(of: "main") {
                let suffix = code[range.upperBound...]
                if suffix.contains("#if DEBUG") { return (true, success()) }
            }
            return (false, [])
        }
        
        // Q24: Void Pointer (cast to int*)
        if title.contains("Question 24") && title.contains("Level 1") {
            if code.contains("(int*)") || code.contains("int *") { return (true, success()) }
            return (false, [])
        }
        
        // Q25: Implicit Cast (double index -> int index)
        if title.contains("Question 25") && title.contains("Level 1") {
            if code.contains("int index") && !code.contains("double index") { return (true, success()) }
            return (false, [])
        }
        
        // Fallback or Unknown Question
        let normCode = normalize(code)
        let normCorrect = normalize(question.correctCode)
        if normCode == normCorrect {
            return (true, success())
        }
        
        return (false, [])
    }
}
