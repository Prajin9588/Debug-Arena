
// Mock or Include SimpleInterpreter here to make it runnable as a script
// In a real project context, we'd run `swift test` or similar.
// For now, let's assume the user will run the App to verify.
// But to clear the error, I should comment out top-level code or wrap it.


// Assuming this is pasted into a context where SimpleInterpreter is available, 
// or we need to instantiate it if we can import it.
// For the sake of this script being valid syntax in isolation:
// let interpreter = SimpleInterpreter() 

struct SyntaxVerifier {
    static func runTests(interpreter: SimpleInterpreter) {
        print("Running Syntax Strictness Tests...")

        // Test 1: Missing braces in if
        test("if true print(\"hi\")", expectedError: "Expected '{'", interpreter: interpreter)

        // Test 2: Missing braces in while
        test("while true print(\"hi\")", expectedError: "Expected '{'", interpreter: interpreter)

        // Test 3: Missing colon in switch case
        test("switch x { case 1 print(\"one\") }", expectedError: "Expected ':'", interpreter: interpreter)

        // Test 4: Missing parenthesis in function decl
        test("func myFunc { }", expectedError: "Expected '('", interpreter: interpreter)

        // Test 5: Missing closing brace
        test("if true { print(\"hi\")", expectedError: "Expected '}'", interpreter: interpreter)

        print("Tests Complete.")
    }

    static func test(_ code: String, expectedError: String, interpreter: SimpleInterpreter) {
        let result = interpreter.evaluate(code: code)
        if result.contains(expectedError) {
            print("✅ Passed: Detected error '\(expectedError)'")
        } else {
            print("❌ Failed: Expected error '\(expectedError)', got: '\(result)'")
        }
    }
}

// runTests() // Uncomment to run if supported context
