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

        // 1. Normalize Code (Token-based approach) - kept for structural hints if needed
        let normalizedCode = normalize(code)
        
        // 2. Initial Structure Check
        if normalizedCode.isEmpty {
            return EvaluationResult.simpleError(type: .syntax, message: "Code cannot be empty.")
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
                status: .incorrect, // Mapped from isSuccess: false
                score: 0,
                level: .failed,
                complexity: .low, // Default
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "Compilation Failed:\n\(syntaxCheck)"
            )
        }
        
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
                
                if actual == expected {
                    passedTestCount += 1
                } else if actual.lowercased() == expected.lowercased() {
                    // Soft Pass (Case insensitive)
                    passedTestCount += 1
                    feedbackItems.append("⚠️ Test \(index + 1): Case mismatch. (Expected: \(expected), Got: \(actual))")
                } else {
                    passedHiddenTests = false
                    // Only show detail for the first failure to avoid overwhelming user
                    if feedbackItems.filter({ $0.contains("❌") }).isEmpty {
                        feedbackItems.append("❌ Test \(index + 1) Failed")
                        feedbackItems.append("Input: \(driverCode.isEmpty ? "(Standard Execution)" : driverCode)")
                        feedbackItems.append("Expected: \(expected)")
                        feedbackItems.append("Got: \(actual)")
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
            
            if userOutput == goldenOutput {
                 passedTestCount = 1
                 passedHiddenTests = true
                 feedbackItems.append("✅ Output matches expected result.")
            } else if userOutput.lowercased() == goldenOutput.lowercased() {
                 passedTestCount = 1
                 passedHiddenTests = true
                 feedbackItems.append("⚠️ Output matched but case differs. (Expected: \(goldenOutput), Got: \(userOutput))")
            } else {
                 passedHiddenTests = false
                 feedbackItems.append("❌ Output Mismatch")
                 feedbackItems.append("Expected: \(goldenOutput)")
                 feedbackItems.append("Got: \(userOutput)")
            }
        }

        // 5. Anti-Hardcoding / Concept Validation (Secondary)
        if isHardcoded(code: code, question: question) {
             hardcodingDetected = true
             // passedHiddenTests = false // Don't fail explicitly, but cap score?
             // User requirement: If any test fail -> success is false. 
             // Hardcoding is a form of logic failure.
             passedHiddenTests = false 
             score = 30
             feedbackItems.append("⚠️ Hardcoding detected. Please use the required logic constructs (loops / conditions).")
        }
        
        // 6. Logic & Complexity Analysis
        let complexityScore = analyzeComplexity(code: code, language: question.language)
        
        // 7. Dynamic Scoring Logic
        // Base Score Calculation (max 70 points for logic)
        let logicScore = (Double(passedTestCount) / Double(totalTests)) * 70.0
        
        score = Int(logicScore) + 20 // Base 20 for compiling
        
        if passedHiddenTests && !hardcodingDetected {
             // Bonus for perfection
             score = max(score, 90) 
        }
        
        if complexityScore.optimizedFuncs {
            score += 10
            feedbackItems.append("✨ Optimized Approach")
        }
        
        // Scale/Clamp
        score = max(0, min(100, score))
        
        // 8. Level Classification
        let level: UserLevel
        switch score {
        case 90...100: level = .expert
        case 75...89: level = .advanced
        case 50...74: level = .intermediate
        case 30...49: level = .beginner
        default: level = .failed
        }
        
        let finalFeedback = feedbackItems.joined(separator: "\n")
        
        return EvaluationResult(
            status: level == .failed ? .incorrect : .correct,
            score: score,
            level: level,
            complexity: complexityScore.level,
            edgeCaseHandling: passedHiddenTests,
            hardcodingDetected: hardcodingDetected,
            feedback: finalFeedback
        )
    }
    
    // MARK: - Helper Methods
    
    private func normalize(_ code: String) -> String {
        return code
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: ";", with: "\n") // Treat semicolons as line breaks for analysis
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
        // Try regex match
        if let _ = code.range(of: pattern, options: .regularExpression) {
            return true
        }
        // Fallback to simple contains
        return code.contains(pattern)
    }
    
    private func evaluateLevel2(code: String, question: Question) -> EvaluationResult {
        // Parse Selected Option
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
        
        // Determine Expected Error Type
        guard question.conceptOptions.indices.contains(question.conceptCorrectAnswer) else {
             return EvaluationResult.simpleError(type: .unknown, message: "Invalid Question Configuration")
        }
        let expectedErrorFragment = question.conceptOptions[question.conceptCorrectAnswer]
        
        // Verify User Selection
        if selectedOpt == question.conceptCorrectAnswer {
             // For Level 2, we return a correct result if the user matched the diagnosis.
             return EvaluationResult(
                status: .correct,
                score: 100,
                level: .passed,
                complexity: .medium,
                edgeCaseHandling: true,
                hardcodingDetected: false,
                feedback: "Correct! You identified the error type: \(expectedErrorFragment)\n\nConcept: \(question.conceptExplanation)"
            )
        } else {
            let userChoice = question.conceptOptions.indices.contains(selectedOpt) ? question.conceptOptions[selectedOpt] : "None Selected"
             return EvaluationResult(
                status: .incorrect,
                score: 0,
                level: .failed,
                complexity: .medium,
                edgeCaseHandling: false,
                hardcodingDetected: false,
                feedback: "Incorrect diagnosis.\n\nActual Type: \(expectedErrorFragment)\nYou Selected: \(userChoice)\n\nTry analyzing the code structure again."
            )
        }
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
    
    private func checkSyntax(code: String, language: Language) -> EvaluationResult? {
         let lines = code.components(separatedBy: .newlines)
         
         switch language {
         case .c, .cpp:
             // Check for main
             if !code.contains("int main") {
                 return EvaluationResult.simpleError(type: .syntax, message: "Missing 'int main()' function")
             }
             // Check for semicolon
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("#") && !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") && !trimmed.hasSuffix(">") {
                     return EvaluationResult.simpleError(type: .syntax, message: "Missing semicolon ';'", line: index + 1)
                 }
             }
         case .java:
             // Check for class
             if !code.contains("class ") {
                  return EvaluationResult.simpleError(type: .syntax, message: "Missing class definition")
             }
             if !code.contains("public static void main") {
                 return EvaluationResult.simpleError(type: .syntax, message: "Missing 'public static void main'")
             }
             // Check for semicolon
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("@") && !trimmed.hasSuffix(";") && !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") {
                      return EvaluationResult.simpleError(type: .syntax, message: "Missing semicolon ';'", line: index + 1)
                 }
             }
         case .python:
             for (index, line) in lines.enumerated() {
                 let trimmed = line.trimmingCharacters(in: .whitespaces)
                 if (trimmed.hasPrefix("if") || trimmed.hasPrefix("for") || trimmed.hasPrefix("while") || trimmed.hasPrefix("def") || trimmed.hasPrefix("class")) && !trimmed.hasSuffix(":") {
                     return EvaluationResult.simpleError(type: .syntax, message: "Missing colon ':'", line: index + 1)
                 }
             }
         case .swift:
              if code.contains("int ") || code.contains("String ") {
                   // return EvaluationResult.simpleError(type: .syntax, message: "Use 'var' or 'let' in Swift.")
              }
         }
         return nil
    }
}
