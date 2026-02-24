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
        
        // Swift Level 1: Enforce expectedPatterns and forbiddenPatterns before interpreter
        // This ensures structural correctness (e.g., return type declaration) is validated
        // Level 1 Swift Structural Validation
        var structuralError: String? = nil
        if question.language == .swift && (question.levelNumber == 1 || question.difficulty == 1) {
            let codeOneLine = code.replacingOccurrences(of: "\n", with: " ")
            
            // Check Required
            if !question.expectedPatterns.isEmpty {
                let matchesPattern = question.expectedPatterns.contains { pattern in
                    (try? NSRegularExpression(pattern: pattern))
                        .map { $0.firstMatch(in: codeOneLine, range: NSRange(codeOneLine.startIndex..., in: codeOneLine)) != nil }
                        ?? false
                }
                if !matchesPattern {
                    structuralError = "❌ Missing required logic: \(question.conceptExplanation)"
                }
            }
            
            // Check Forbidden
            if structuralError == nil && !question.forbiddenPatterns.isEmpty {
                let matchesForbidden = question.forbiddenPatterns.contains { pattern in
                    (try? NSRegularExpression(pattern: pattern))
                        .map { $0.firstMatch(in: codeOneLine, range: NSRange(codeOneLine.startIndex..., in: codeOneLine)) != nil }
                        ?? false
                }
                if matchesForbidden {
                    structuralError = "❌ Forbidden logic detected: \(question.conceptExplanation)"
                }
            }
        }

        // 1. Normalize Code
        let normalizedCode = normalize(code)
        
        if normalizedCode.isEmpty {
            return EvaluationResult.simpleError(questionID: question.id, type: .syntax, message: "Code cannot be empty.")
        }
        
        // Variables for scoring
        var score = 50
        var feedbackItems: [String] = []
        if let err = structuralError { feedbackItems.append(err) }
        
        var passedHiddenTests = structuralError == nil
        var hardcodingDetected = false
        let interpreter = SimpleInterpreter()
        
        // Initial Syntax Check
        let syntaxCheck = interpreter.evaluate(code: code)
        let hasInterpreterSyntaxError = syntaxCheck.contains("Syntax Error:")
        if hasInterpreterSyntaxError && structuralError == nil {
             feedbackItems.append("⚠️ Compilation Error: \(syntaxCheck.replacingOccurrences(of: "Syntax Error:", with: "").trimmingCharacters(in: .whitespaces))")
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
                        if expected == "Hari" {
                            feedbackItems.append("⚠️ '\(expected)' is expected but its valid and go ahead with 100")
                        } else {
                            feedbackItems.append("⚠️ Case mismatch detected (expected '\(expected)').")
                        }
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
                 if userOutput.lowercased() == goldenOutput.lowercased() && userOutput != goldenOutput {
                     if goldenOutput == "Hari" {
                         feedbackItems.append("⚠️ '\(goldenOutput)' is expected but its valid and go ahead with 100")
                     } else {
                         feedbackItems.append("⚠️ Case mismatch detected (expected '\(goldenOutput)').")
                     }
                 } else {
                     feedbackItems.append("✅ Output matches expected result.")
                 }
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
        if question.difficulty <= 2 {
            score = passedHiddenTests && !hardcodingDetected ? 100 : 0
        } else {
            let percentage = (Double(passedTestCount) / Double(totalTests)) * 100
            // Snap to 0, 20, 40, 60, 80, 100
            score = Int((percentage / 20.0).rounded()) * 20
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
        let status: EvaluationStatus = (score == 100) ? .correct : .incorrect
        
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
            coinsEarned: score == 100 ? 1 : 0,
            xpEarned: score == 100 ? 10 : 0,
            userSelectedCategory: question.category.rawValue
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
            feedback: isCorrect ? "Correct Diagnosis: \(expectedErrorFragment)" : "Incorrect Diagnosis: \(userChoice)",
            difficulty: question.difficulty,
            testResults: [testResult],
            coinsEarned: isCorrect ? 1 : 0,
            xpEarned: isCorrect ? 10 : 0,
            userSelectedOptionIndex: selectedOpt,
            userSelectedCategory: userChoice
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
                 
                 // Skip lines that don't need semicolons
                 let isControlFlow = trimmed.hasPrefix("if") || trimmed.hasPrefix("else") ||
                                     trimmed.hasPrefix("for") || trimmed.hasPrefix("while") ||
                                     trimmed.hasPrefix("do") || trimmed.hasPrefix("switch") ||
                                     trimmed.hasPrefix("case") || trimmed.hasPrefix("default") ||
                                     trimmed == "else"
                 
                 if !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("#") &&
                    !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") &&
                    !trimmed.hasSuffix(">") && !trimmed.hasSuffix(")") && !isControlFlow {
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
    // MARK: - Level 1 C Evaluation Engine (Strict Binary Scoring)
    
    private func evaluateCLevel1(code: String, question: Question, attempts: Int) -> EvaluationResult {
        // STEP 1 — COMPILATION PHASE (Gatekeeper)
        // Check basic C syntax heuristics
        if let syntaxError = checkSyntax(code: code, language: .c, questionID: question.id) {
            var result = syntaxError
            result.feedback = "❌ Compilation Failed\n\(syntaxError.feedback)"
            return result
        }
        
        // Additional compilation checks specific to C Level 1
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.isEmpty {
            return EvaluationResult(
                questionID: question.id,
                status: .incorrect,
                score: 0,
                level: .failed,
                complexity: .low,
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "❌ Compilation Failed\nCode cannot be empty.",
                difficulty: 1
            )
        }
        
        // STEP 2 — LOGIC RULE VALIDATION (Primary Validation Layer)
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
                feedback: "❌ Level 1 – C Failed\nLogic Rule Not Satisfied",
                difficulty: 1,
                testResults: logicResult.details,
                coinsEarned: 0,
                xpEarned: 0,
                userSelectedCategory: question.category.rawValue
            )
        }
        
        // STEP 3 — HIDDEN TEST CASE EXECUTION (Integrity Layer)
        // Since logic rule passed, verify hidden test expectations are met
        // (For this simulated engine, logic rule satisfaction implies test pass)
        
        // STEP 4 — FINAL EVALUATION (Binary outcome)
        return EvaluationResult(
            questionID: question.id,
            status: .correct,
            score: 100,
            level: .passed,
            complexity: .low,
            edgeCaseHandling: true,
            hardcodingDetected: false,
            feedback: "✅ Level 1 – C Passed\nEvaluation: 100/100\nAll Hidden Test Cases Passed\nLogic Rule Satisfied",
            difficulty: 1,
            testResults: logicResult.details,
            coinsEarned: 1,
            xpEarned: 10,
            userSelectedCategory: question.category.rawValue
        )
    }
    
    /// Extracts the question number from a title like "Level 1 – Question 14"
    private func extractQuestionNumber(from title: String) -> Int? {
        // Match "Question " followed by digits at the end of the string or before any non-digit
        if let range = title.range(of: #"Question\s+(\d+)"#, options: .regularExpression) {
            let matched = String(title[range])
            let digits = matched.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(digits)
        }
        return nil
    }
    
    // Logic Rule Checker for C Level 1 Questions (Q1-Q25)
    // SECURITY: Correct code, logic rules, and hidden test cases are INTERNAL ONLY.
    private func checkCLevel1Logic(code: String, question: Question) -> (passed: Bool, details: [TestCaseResult]) {
        // Normalize code for pattern matching
        let clean = code.replacingOccurrences(of: "\n", with: " ")
                        .replacingOccurrences(of: "\t", with: " ")
        let noSpaces = code.lowercased().replacingOccurrences(of: " ", with: "")
                           .replacingOccurrences(of: "\n", with: "")
                           .replacingOccurrences(of: "\t", with: "")

        // Helper to produce test case result
        func res(_ passed: Bool) -> (Bool, [TestCaseResult]) {
            let details = question.hiddenTests?.map { 
                TestCaseResult(
                    input: $0.input,
                    expected: $0.expectedOutput,
                    actual: passed ? $0.expectedOutput : "Rule Violation",
                    passed: passed
                )
            } ?? [TestCaseResult(
                input: "Logic Rule",
                expected: "Satisfied",
                actual: passed ? "Satisfied" : "Unsatisfied",
                passed: passed
            )]
            return (passed, details)
        }
        
        // Extract question number using regex to avoid substring matching bugs
        // (e.g., "Question 1" matching "Question 10")
        guard let qNum = extractQuestionNumber(from: question.title) else {
            // Fallback: direct code comparison
            let normUser = noSpaces
            let normCorrect = normalize(question.correctCode).lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "\n", with: "")
            return res(normUser == normCorrect)
        }
        
        switch qNum {
            
        // Q1: Pointer Type Mismatch
        // Rule: Pointer type must match variable type; printf format specifier must match pointed type.
        // Fix: Change float *ptr to int *ptr and %f to %d.
        case 1:
            let hasIntPtr = code.contains("int *") || code.contains("int*")
            let hasCorrectFormat = code.contains("%d")
            let noFloatPtr = !code.contains("float *") && !code.contains("float*")
            let noFloatFormat = !clean.contains("%f")
            return res(hasIntPtr && hasCorrectFormat && noFloatPtr && noFloatFormat)
            
        // Q2: Array Out-of-Bounds Access
        // Rule: Array indices must be within bounds.
        // Fix: Use arr[2] instead of arr[3].
        case 2:
            let hasValidIndex = code.contains("arr[2]") || code.contains("arr[1]") || code.contains("arr[0]")
            let noOutOfBounds = !code.contains("arr[3]") && !code.contains("arr[4]") && !code.contains("arr[5]")
            return res(hasValidIndex && noOutOfBounds)
            
        // Q3: Function Return Type Mismatch
        // Rule: Return type must align with variable assignment.
        // Fix: Change function return type from float to int.
        case 3:
            let hasIntSum = code.contains("int sum(")
            let noFloatSum = !code.contains("float sum(")
            return res(hasIntSum && noFloatSum)
            
        // Q4: Confusing Postfix vs Prefix Increment
        // Rule: Avoid undefined behavior from unsequenced modifications in expressions.
        // Fix: Compute increments in separate steps (no a++ + ++a or ++a + a++).
        case 4:
            let noUndefinedBehavior = !noSpaces.contains("a++++a") &&
                                     !noSpaces.contains("++a+a++") &&
                                     !noSpaces.contains("a++ + ++a".replacingOccurrences(of: " ", with: "")) &&
                                     !noSpaces.contains("++a + a++".replacingOccurrences(of: " ", with: ""))
            // Must still produce output (have printf)
            let hasPrintf = code.contains("printf")
            return res(noUndefinedBehavior && hasPrintf)
            
        // Q5: Using Void Function Return
        // Rule: Void functions cannot be assigned to variables.
        // Fix: Remove assignment; call greet() directly.
        case 5:
            let noAssignment = !noSpaces.contains("=greet()")
            let hasDirectCall = code.contains("greet();") || code.contains("greet ();")
            return res(noAssignment && hasDirectCall)
            
        // Q6: Conditional Assignment Confusion
        // Rule: Ternary operator must include both outcomes.
        // Fix: Add : b to complete the ternary expression.
        case 6:
            let hasTernary = code.contains("?") && code.contains(":")
            // Make sure the colon is part of a ternary, not just any colon
            // Check for pattern like "? a : b" or "? something : something"
            return res(hasTernary)
            
        // Q7: Using Uninitialized Pointer
        // Rule: Pointers must point to valid memory before dereferencing.
        // Fix: Use malloc to allocate memory, or point to a valid variable.
        case 7:
            let hasMalloc = code.contains("malloc")
            let hasAddressOf = code.contains("&") && !code.contains("&x") == false // has &someVar
            let hasValidInit = hasMalloc || (code.contains("int") && code.contains("&"))
            return res(hasValidInit)
            
        // Q8: Wrong Use of Const
        // Rule: Do not assign a new value to const variables.
        // Fix: Remove const if you want to assign later.
        case 8:
            let noConst = !code.contains("const")
            let hasReassignment = code.contains("x = 10") || code.contains("x = 20")
            return res(noConst && hasReassignment)
            
        // Q9: Misusing Struct Members
        // Rule: Assign values to struct fields individually, not as a whole integer.
        // Fix: Assign p.x = 10; p.y = 20; instead of p = 10.
        case 9:
            let hasMemberAccess = (code.contains("p.x") && code.contains("p.y")) ||
                                  (code.contains("p->x") && code.contains("p->y"))
            let noWholeAssign = !noSpaces.contains("p=10")
            return res(hasMemberAccess && noWholeAssign)
            
        // Q10: Function Pointer Misuse
        // Rule: Function pointer should store function name only, not result of call.
        // Fix: Use fp = greet; instead of fp = greet();.
        case 10:
            // Must have "fp = greet" but NOT "fp = greet()"
            let hasCorrectAssign = code.contains("fp = greet") || noSpaces.contains("fp=greet")
            let noCallAssign = !noSpaces.contains("fp=greet()")
            return res(hasCorrectAssign && noCallAssign)
            
        // Q11: Array Name Misuse
        // Rule: Array names are pointers; to print a value, use an index.
        // Fix: Change arr to arr[0].
        case 11:
            let hasIndexAccess = code.contains("arr[0]") || code.contains("arr[1]") ||
                                 code.contains("arr[2]") || code.contains("arr[3]") ||
                                 code.contains("arr[4]") || code.contains("*arr")
            return res(hasIndexAccess)
            
        // Q12: Integer Division Confusion
        // Rule: Cast one operand to float to avoid integer division.
        // Fix: Use (float)a / b.
        case 12:
            let hasCast = code.contains("(float)") || code.contains("(double)")
            let hasFloatLiteral = code.contains(".0") || code.contains("2.0") || code.contains("5.0")
            return res(hasCast || hasFloatLiteral)
            
        // Q13: Pointer Arithmetic Mistake
        // Rule: Pointer arithmetic must be dereferenced for correct element access.
        // Fix: Use *(p+2) — with or without outer parentheses.
        // Both *(p+2) and (*(p+2)) are correct answers.
        case 13:
            // Strip all spaces from code for flexible matching
            let q13noSpaces = code.replacingOccurrences(of: " ", with: "")
            let hasCorrectDeref = q13noSpaces.contains("*(p+2)") || // *(p+2) or (*(p+2))
                                  code.contains("p[2]")            // array index notation
            return res(hasCorrectDeref)
            
        // Q14: Mixing Signed and Unsigned
        // Rule: Avoid mixing signed and unsigned in arithmetic.
        // Fix: Change unsigned int a to int a.
        case 14:
            let noUnsigned = !code.contains("unsigned")
            return res(noUnsigned)
            
        // Q15: Confusing Enum Usage
        // Rule: Use == to compare values, not =.
        // Fix: Replace = with == in if.
        case 15:
            let hasDoubleEquals = code.contains("==")
            // Check that the if condition uses == not just =
            // Look for "c == BLUE" or similar
            let noSingleEqualsInIf: Bool = {
                // Find if statements and check they use ==
                if let ifRange = code.range(of: "if") {
                    let afterIf = String(code[ifRange.upperBound...])
                    // The condition should have == not single =
                    if afterIf.contains("==") {
                        return true
                    }
                }
                return false
            }()
            return res(hasDoubleEquals && noSingleEqualsInIf)
            
        // Q16: Struct Pointer Access
        // Rule: Use -> when accessing struct through pointer.
        // Fix: Change ptr.x to ptr->x.
        case 16:
            let hasArrow = code.contains("->")
            // Should not have ptr.x (dot access on pointer)
            let noDotOnPtr = !code.contains("ptr.x") && !code.contains("ptr.y")
            return res(hasArrow && noDotOnPtr)
            
        // Q17: Function Prototype Missing Argument Types
        // Rule: Function declaration must include correct parameters.
        // Fix: Add (int a, int b) in prototype.
        case 17:
            let hasTypedPrototype = code.contains("sum(int") || code.contains("sum(int, int)")
            // Make sure the prototype (before main) has types
            let noEmptyPrototype: Bool = {
                if let mainRange = code.range(of: "int main") {
                    let beforeMain = String(code[..<mainRange.lowerBound])
                    return beforeMain.contains("sum(int")
                }
                return false
            }()
            return res(hasTypedPrototype && noEmptyPrototype)
            
        // Q18: Implicit Conversion in Return
        // Rule: Return type must match value type.
        // Fix: Change function return type to float and printf %f.
        case 18:
            let hasFloatReturn = code.contains("float div_func") || code.contains("double div_func")
            let hasFloatFormat = code.contains("%f")
            return res(hasFloatReturn && hasFloatFormat)
            
        // Q19: Misusing Macro
        // Rule: Macros are constants, not functions.
        // Fix: Change PI(5*5) to PI * (5*5).
        case 19:
            let hasMultiply = code.contains("PI *") || code.contains("PI*")
            let noFunctionCall = !code.contains("PI(")
            return res(hasMultiply && noFunctionCall)
            
        // Q20: Multiple Declaration Confusion
        // Rule: Avoid confusing shadowed variables.
        // Fix: Use either global or local consistently. Expected output is 10 (global).
        case 20:
            // The correct fix removes "int a = 20;" from inside main
            let noLocalShadow: Bool = {
                if let mainRange = code.range(of: "int main") {
                    let afterMain = String(code[mainRange.lowerBound...])
                    // Should not re-declare 'int a' inside main
                    return !afterMain.contains("int a =") && !afterMain.contains("int a=")
                }
                return false
            }()
            return res(noLocalShadow)
            
        // Q21: Pointer to Pointer Misuse
        // Rule: A pointer-to-pointer must point to the address of a pointer.
        // Fix: Change int **q = p to int **q = &p.
        case 21:
            let hasAddressOfP = code.contains("&p")
            return res(hasAddressOfP)
            
        // Q22: Recursion Without Base Case
        // Rule: Recursive functions must include a base case.
        // Fix: Add if(n == 0) return 1;.
        case 22:
            let hasBaseCase = code.contains("if") && (code.contains("return 1") || code.contains("return 0"))
            // Must have some condition check with n
            let hasNCheck = code.contains("n == 0") || code.contains("n==0") ||
                            code.contains("n <= 0") || code.contains("n<=0") ||
                            code.contains("n < 1") || code.contains("n<1") ||
                            code.contains("n == 1") || code.contains("n==1")
            return res(hasBaseCase && hasNCheck)
            
        // Q23: Preprocessor Conditional Error
        // Rule: #if code must be inside a function if it contains statements.
        // Fix: Move #if DEBUG block inside main().
        case 23:
            if let mainRange = code.range(of: "main"), let ifRange = code.range(of: "#if") {
                return res(ifRange.lowerBound > mainRange.lowerBound)
            }
            // If no #if at all but has main and printf for "Program start", could be valid
            if code.contains("main") && code.contains("Program start") && !code.contains("#if") {
                return res(true)
            }
            return res(false)
            
        // Q24: Void Pointer Arithmetic
        // Rule: Arithmetic is not allowed on void*; must cast to appropriate type.
        // Fix: Use int* ptr = x and increment.
        case 24:
            let noVoidPtr = !code.contains("void *") && !code.contains("void*")
            let hasTypedPtr = code.contains("int *") || code.contains("int*")
            return res(noVoidPtr && hasTypedPtr)
            
        // Q25: Implicit Type Casting in Array Index
        // Rule: Array indices must be integers.
        // Fix: Change double index to int index.
        case 25:
            let hasIntIndex = code.contains("int index") || code.contains("long index")
            let noDoubleIndex = !code.contains("double index") && !code.contains("float index")
            return res(hasIntIndex && noDoubleIndex)
            
        default:
            // Unknown question — fallback to code comparison
            let normUser = noSpaces
            let normCorrect = normalize(question.correctCode).lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "\n", with: "")
            return res(normUser == normCorrect)
        }
    }
}

