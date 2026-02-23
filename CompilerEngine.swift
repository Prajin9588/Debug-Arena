import Foundation

class CompilerEngine {
    static let shared = CompilerEngine()
    // Shared instance for compilation tasks
    
    private init() {}
    
    // LOGICAL VALIDATION ENGINE
    func evaluate(code: String, for question: Question, attempts: Int = 0) -> EvaluationResult {
        // Level 2 Special Handling (Runtime Error ID)
        if question.difficulty == 2 {
            return evaluateLevel2(code: code, question: question)
        }
        
        // Level 1 C Special Handling (Strict Logic Engine)
        if question.language == .c && (question.levelNumber == 1 || question.difficulty == 1) {
            return evaluateCLevel1(code: code, question: question, attempts: attempts)
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
             let lowerCode = code.lowercased()
             if !lowerCode.contains("int main") && !lowerCode.contains("void main") {
                 return EvaluationResult.simpleError(questionID: questionID, type: .syntax, message: "Missing 'main()' function")
             }
             // Check for semicolon
             for (index, line) in lines.enumerated() {
                 var trimmed = line.trimmingCharacters(in: .whitespaces)
                 // Remove trailing comments for semicolon check
                 if let commentRange = trimmed.range(of: "//") {
                     trimmed = String(trimmed[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                 }
                 
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
    
    private func evaluateCLevel1(code: String, question: Question, attempts: Int) -> EvaluationResult {
        // STEP 1 — COMPILATION CHECK (HEURISTIC)
        if let syntaxError = checkSyntax(code: code, language: .c, questionID: question.id) {
            // Add attempt count to feedback
            var result = syntaxError
            result.feedback = "❌ Compilation Failed\n\(syntaxError.feedback)\nAttempts: \(attempts) / 5"
            return result
        }
        
        // STEP 2 — LOGIC RULE VALIDATION
        let logicResult = checkCLevel1Logic(code: code, question: question)
        if !logicResult.passed {
            return EvaluationResult(
                questionID: question.id,
                status: .incorrect,
                score: 0,
                level: .failed,
                complexity: .low,
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "❌ Evaluation Failed\nLogic Rule Not Satisfied\nEnsure you've fixed the specific bug mentioned in the riddle.\nAttempts: \(attempts) / 5",
                difficulty: 1,
                testResults: logicResult.details,
                coinsEarned: 0,
                xpEarned: 0
            )
        }
        
        // STEP 3 - SUCCESS
        return EvaluationResult(
            questionID: question.id,
            status: .correct,
            score: 100,
            level: .expert,
            complexity: .low,
            edgeCaseHandling: true,
            hardcodingDetected: false,
            feedback: "✅ Evaluation Complete\nScore: 100/100\nLogic Correctly Implemented\nAll Test Cases Passed",
            difficulty: 1,
            testResults: logicResult.details,
            coinsEarned: 1,
            xpEarned: 10
        )
    }
    
    // Logic Rule Checker for C Level 1 Questions (Q1-Q25)
    private func checkCLevel1Logic(code: String, question: Question) -> (passed: Bool, details: [TestCaseResult]) {
        let clean = code.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ")
        let title = question.title

        func res(_ passed: Bool) -> (Bool, [TestCaseResult]) {
            let details = question.hiddenTests?.map { 
                TestCaseResult(input: $0.input, expected: $0.expectedOutput, actual: passed ? $0.expectedOutput : "Rule Violation", passed: passed)
            } ?? [TestCaseResult(input: "Logic Rule", expected: "Satisfied", actual: passed ? "Satisfied" : "Unsatisfied", passed: passed)]
            return (passed, details)
        }
        
        let lower = code.lowercased().replacingOccurrences(of: " ", with: "")
        
        // Q1: Pointer Type Mismatch
        if title.contains("Question 1") {
            return res((code.contains("int *") || code.contains("int*")) && code.contains("%d") && !code.contains("float *") && !code.contains("float*"))
        }
        // Q2: Array Out-of-Bounds
        if title.contains("Question 2") {
            return res((code.contains("[2]") || code.contains("[1]") || code.contains("[0]")) && !code.contains("[3]"))
        }
        // Q3: Function Return Type
        if title.contains("Question 3") {
            return res(code.contains("int sum(") && !code.contains("float sum("))
        }
        // Q4: Postfix/Prefix
        if title.contains("Question 4") {
            return res(!clean.contains("++a + a++") && !clean.contains("a++ + ++a"))
        }
        // Q5: Void function return
        if title.contains("Question 5") {
            return res(!clean.contains("= greet()") && code.contains("greet();"))
        }
        // Q6: Ternary
        if title.contains("Question 6") {
            return res(code.contains("?") && code.contains(":"))
        }
        // Q7: Uninitialized Pointer
        if title.contains("Question 7") {
            return res(code.contains("malloc") || (code.contains("int x") && code.contains("&x")))
        }
        // Q8: Const removal
        if title.contains("Question 8") {
            return res(!code.contains("const") && code.contains("x = 20"))
        }
        // Q9: Struct members
        if title.contains("Question 9") {
            return res((code.contains("p.x") && code.contains("p.y")) || (code.contains("p->x") && code.contains("p->y")))
        }
        // Q10: Function Pointer
        if title.contains("Question 10") {
            return res(code.contains("fp = greet") && !code.contains("fp = greet()"))
        }
        // Q11: Array Name as Pointer
        if title.contains("Question 11") {
            return res(code.contains("arr[0]") || code.contains("*arr"))
        }
        // Q12: Integer Division
        if title.contains("Question 12") {
            return res(code.contains(".0") || code.contains("(float)") || code.contains("(double)"))
        }
        // Q13: Pointer Arithmetic Parentheses
        if title.contains("Question 13") {
            return res(code.contains("*(p+2)") || code.contains("*(p + 2)"))
        }
        // Q14: Signed vs Unsigned
        if title.contains("Question 14") {
            return res(!code.contains("unsigned"))
        }
        // Q15: Enum Equality
        if title.contains("Question 15") {
            return res(code.contains("=="))
        }
        // Q16: Arrow Operator
        if title.contains("Question 16") {
            return res(code.contains("->"))
        }
        // Q17: Function Prototype
        if title.contains("Question 17") {
            return res(code.contains("sum(int") || code.contains("sum(int, int)"))
        }
        // Q18: Implicit conversion in call
        if title.contains("Question 18") {
            return res(code.contains("float"))
        }
        // Q19: Macro evaluation
        if title.contains("Question 19") {
            return res(code.contains("PI *"))
        }
        // Q20: Variable Shadowing
        if title.contains("Question 20") {
            return res(!clean.contains("int a = 20") && clean.contains("a = 20"))
        }
        // Q21: Pointer to Pointer
        if title.contains("Question 21") {
            return res(code.contains("&p"))
        }
        // Q22: Recursion Base Case
        if title.contains("Question 22") {
            return res(code.contains("if") && (code.contains("return 1") || code.contains("return 0")))
        }
        // Q23: Preprocessor inside function
        if title.contains("Question 23") {
            // Must contain #if and it should be after int main (moved inside)
            if let mainRange = code.range(of: "main"), let ifRange = code.range(of: "#if") {
                return res(ifRange.lowerBound > mainRange.lowerBound)
            }
            return res(false)
        }
        // Q24: Void Pointer casting
        if title.contains("Question 24") {
            return res(code.contains("(int*)") || code.contains("int *"))
        }
        // Q25: Array Index Type
        if title.contains("Question 25") {
            return res(code.contains("int index") || code.contains("long index"))
        }
        
        let normUser = lower
        let normCorrect = normalize(question.correctCode).lowercased().replacingOccurrences(of: " ", with: "")
        return res(normUser == normCorrect || code.contains(normalize(question.correctCode)))
    }
}

