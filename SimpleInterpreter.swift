import Foundation

// MARK: - AST Nodes
protocol ASTNode {}

struct BlockNode: ASTNode {
    let statements: [ASTNode]
}

struct VariableDeclNode: ASTNode {
    let name: String
    let value: ASTNode
}

struct AssignmentNode: ASTNode {
    let name: String
    let value: ASTNode
}

struct PrintNode: ASTNode {
    let expression: ASTNode
}

struct IfNode: ASTNode {
    let condition: ASTNode
    let trueBlock: BlockNode
    let falseBlock: BlockNode?
    let isBinding: Bool // True if "if let"
    let bindingName: String? // Name of var if isBinding
}

struct SwitchNode: ASTNode {
    let expression: ASTNode
    let cases: [(ASTNode, BlockNode)] // (Pattern, Body)
    let defaultCase: BlockNode?
}

struct WhileNode: ASTNode {
    let condition: ASTNode
    let body: BlockNode
}

struct ForNode: ASTNode {
    let variable: String
    let sequence: ASTNode
    let body: BlockNode
}

struct FuncDeclNode: ASTNode {
    let name: String
    let parameters: [String] 
    let body: BlockNode
}

struct ReturnNode: ASTNode {
    let value: ASTNode?
}

struct CallNode: ASTNode {
    let callee: String
    let arguments: [ASTNode] 
}

struct ArrayNode: ASTNode {
    let elements: [ASTNode]
}

struct TupleNode: ASTNode {
    let elements: [(String?, ASTNode)]
}

struct DictionaryNode: ASTNode {
    let elements: [(ASTNode, ASTNode)]
}

struct SubscriptNode: ASTNode {
    let target: ASTNode
    let index: ASTNode
}

struct MethodCallNode: ASTNode {
    let target: ASTNode
    let methodName: String
    let arguments: [ASTNode]
}

struct ForceUnwrapNode: ASTNode {
    let expression: ASTNode
}

// Expressions
// Expressions
struct TryForceNode: ASTNode {
    let expression: ASTNode
}

struct CastForceNode: ASTNode {
    let expression: ASTNode
    let type: String
}

struct BinaryOpNode: ASTNode {
    let left: ASTNode
    let operatorToken: String
    let right: ASTNode
}

struct LiteralNode: ASTNode {
    let value: Any
}

struct VariableNode: ASTNode {
    let name: String
}

// MARK: - Tokenizer
enum TokenType: Equatable {
    case keyword(String)
    case identifier(String)
    case literal(String) // Number or String
    case `operator`(String)
    case punctuation(String)
    case eof
}

class Tokenizer {
    private let inputs: String
    private var position: String.Index
    
    init(_ input: String) {
        self.inputs = input
        self.position = input.startIndex
    }
    
    func tokenize() -> [TokenType] {
        var tokens: [TokenType] = []
        
        while position < inputs.endIndex {
            let char = inputs[position]
            
            if char.isWhitespace {
                position = inputs.index(after: position)
                continue
            }
            
            if char.isLetter || char == "_" {
                tokens.append(readIdentifier())
            } else if char.isNumber {
                tokens.append(readNumber())
            } else if char == "\"" {
                tokens.append(readString())
            } else if "+-*/%=<>!&|.".contains(char) {
                // Check for multi-char operators
                tokens.append(readOperator())
            } else if "(){}[],:".contains(char) {
                tokens.append(.punctuation(String(char)))
                position = inputs.index(after: position)
            } else {
                position = inputs.index(after: position) // Skip unknown
            }
        }
        tokens.append(.eof)
        return tokens
    }
    
    private func readIdentifier() -> TokenType {
        let start = position
        while position < inputs.endIndex { // Loop to advance position
            let char = inputs[position]
            if char.isLetter || char.isNumber || char == "_" {
                position = inputs.index(after: position)
            } else {
                break
            }
        }
        let text = String(inputs[start..<position])
        let keywords = ["if", "else", "while", "for", "switch", "case", "default", "print", "var", "let", "func", "return", "int", "float", "string", "true", "false", "nil", "in", "try", "as"]
        
        if keywords.contains(text.lowercased()) {
            return .keyword(text.lowercased())
        }
        return .identifier(text)
    }
    
    private func readNumber() -> TokenType {
        let start = position
        while position < inputs.endIndex {
            let char = inputs[position]
            if char.isNumber {
                position = inputs.index(after: position)
            } else if char == "." {
                // Check if next is also '.' (range operator)
                let nextIndex = inputs.index(after: position)
                if nextIndex < inputs.endIndex && inputs[nextIndex] == "." {
                    break
                }
                position = inputs.index(after: position)
            } else {
                break
            }
        }
        return .literal(String(inputs[start..<position]))
    }
    
    private func readString() -> TokenType {
        position = inputs.index(after: position) // Skip start quote
        let start = position
        while position < inputs.endIndex, inputs[position] != "\"" {
            if inputs[position] == "\\" && position < inputs.index(before: inputs.endIndex) {
                 position = inputs.index(after: position) // Skip escape
            }
            position = inputs.index(after: position)
        }
        let text = String(inputs[start..<position])
        if position < inputs.endIndex {
            position = inputs.index(after: position) // Skip end quote
        }
        return .literal(text) // Stored without quotes
    }
    
    private func readOperator() -> TokenType {
        let start = position
        // Read until not operator char
        while position < inputs.endIndex, "+-*/%=<>!&|.".contains(inputs[position]) {
             position = inputs.index(after: position)
        }
        return .operator(String(inputs[start..<position]))
    }
}

// MARK: - Parser
class Parser {
    private let tokens: [TokenType]
    private var current = 0
    var errors: [String] = []
    
    init(_ tokens: [TokenType]) {
        self.tokens = tokens
    }
    
    func parse() -> BlockNode {
        var statements: [ASTNode] = []
        while !isAtEnd() {
            if let stmt = parseStatement() {
                statements.append(stmt)
            } else {
                advance() // Error recovery
            }
        }
        return BlockNode(statements: statements)
    }
    
    private func parseStatement() -> ASTNode? {
        if match(.keyword("print")) {
            return parsePrint()
        }
        if match(.keyword("if")) {
            return parseIf()
        }
        if match(.keyword("switch")) {
            return parseSwitch()
        }
        if match(.keyword("while")) {
            return parseWhile()
        }
        if match(.keyword("for")) {
            return parseFor()
        }
        if match(.keyword("var")) || match(.keyword("let")) {
            return parseVarDecl()
        }
        if match(.keyword("func")) {
            return parseFuncDecl()
        }
        if match(.keyword("return")) {
            return parseReturn()
        }
        
        // Expression Statements (Assignment, Call)
        let expr = parseExpression()
        
        // Check for Assignment
        if match(.operator("=")) {
            if let v = expr as? VariableNode {
                 let value = parseExpression()
                 return AssignmentNode(name: v.name, value: value)
            }
        } else if match(.operator("+=")) {
            if let v = expr as? VariableNode {
                 let factor = parseExpression()
                 let value = BinaryOpNode(left: v, operatorToken: "+", right: factor)
                 return AssignmentNode(name: v.name, value: value)
            }
        } else if match(.operator("-=")) {
            if let v = expr as? VariableNode {
                 let factor = parseExpression()
                 let value = BinaryOpNode(left: v, operatorToken: "-", right: factor)
                 return AssignmentNode(name: v.name, value: value)
            }
        }
        
        return expr // Return expression statement (like function call)
    }
    
    private func parsePrint() -> ASTNode {
        consume(.punctuation("("))
        let expr = parseExpression()
        consume(.punctuation(")"))
        return PrintNode(expression: expr)
    }
    
    private func parseIf() -> ASTNode {
        var isBinding = false
        var bindingName: String? = nil
        var condition: ASTNode
        
        if match(.keyword("let")) {
             // if let x = ...
             if case .identifier(let name) = advance() {
                 bindingName = name
                 consume(.operator("="), message: "Expected '=' after variable name") // or punctuation?
                 condition = parseExpression()
                 isBinding = true
             } else {
                 condition = LiteralNode(value: false) // Error recovery
             }
        } else {
            condition = parseExpression()
        }
        
        let trueBlock = parseBlock()
        var falseBlock: BlockNode? = nil
        if match(.keyword("else")) {
            if check(.keyword("if")) {
                 let nestedIf = parseIf()
                 falseBlock = BlockNode(statements: [nestedIf])
            } else {
                falseBlock = parseBlock()
            }
        }
        return IfNode(condition: condition, trueBlock: trueBlock, falseBlock: falseBlock, isBinding: isBinding, bindingName: bindingName)
    }
    
    private func parseSwitch() -> ASTNode {
         let expr = parseExpression()
         consume(.punctuation("{"), message: "Expected '{' after switch expression")
         var cases: [(ASTNode, BlockNode)] = []
         var defaultCase: BlockNode? = nil
         
         while !check(.punctuation("}")) && !isAtEnd() {
             if match(.keyword("case")) {
                 let pattern = parseExpression()
                 consume(.punctuation(":"))
                 let body = parseCaseBlock()
                 cases.append((pattern, body))
             } else if match(.keyword("default")) {
                 consume(.punctuation(":"), message: "Expected ':' after default")
                 defaultCase = parseCaseBlock()
             } else {
                 advance() 
             }
         }
         consume(.punctuation("}"), message: "Expected '}' at end of switch block")
         return SwitchNode(expression: expr, cases: cases, defaultCase: defaultCase)
    }
    
    private func parseWhile() -> ASTNode {
        let condition = parseExpression()
        let body = parseBlock()
        return WhileNode(condition: condition, body: body)
    }
    
    private func parseFor() -> ASTNode {
        guard case .identifier(let name) = advance() else { return BlockNode(statements: []) }
        consume(.keyword("in"), message: "Expected 'in' after for loop variable")
        let sequence = parseExpression() 
        let body = parseBlock()
        return ForNode(variable: name, sequence: sequence, body: body)
    }
    
    private func parseVarDecl() -> ASTNode {
        guard case .identifier(let name) = advance() else { return BlockNode(statements: []) }
        
        // Skip type annotation check : Type
        if match(.punctuation(":")) {
             _ = advance() // type name
        }

        var value: ASTNode = LiteralNode(value: "nil") // Default to "nil" string for Swift
        if match(.operator("=")) {
            value = parseExpression()
        }
        return VariableDeclNode(name: name, value: value)
    }
    
    private func parseFuncDecl() -> ASTNode {
        guard case .identifier(let name) = advance() else { return BlockNode(statements: []) }
        consume(.punctuation("("), message: "Expected '(' after function name")
        var params: [String] = []
        while !check(.punctuation(")")) && !isAtEnd() {
            // Handle labels (label name: Type)
            if case .identifier(let pName) = advance() {
                params.append(pName)
                if match(.punctuation(":")) {
                    _ = advance() // type 
                }
            }
            if match(.punctuation(",")) { continue }
        }
        consume(.punctuation(")"), message: "Expected ')' after parameters")
        
        if match(.operator("->")) {
             _ = advance() // Return type
        }
        
        let body = parseBlock()
        return FuncDeclNode(name: name, parameters: params, body: body)
    }
    
    private func parseReturn() -> ASTNode {
        if !check(.punctuation("}")) && !isAtEnd() { // Assuming implicit statement end
             let value = parseExpression()
             return ReturnNode(value: value)
        }
        return ReturnNode(value: nil)
    }

    private func parseBlock() -> BlockNode {
        consume(.punctuation("{"), message: "Expected '{' to start block")
        var stmts: [ASTNode] = []
        while !check(.punctuation("}")) && !isAtEnd() {
            if let stmt = parseStatement() {
                stmts.append(stmt)
            }
        }
        consume(.punctuation("}"), message: "Expected '}' to end block")
        return BlockNode(statements: stmts)
    }
    
    private func parseCaseBlock() -> BlockNode {
         var stmts: [ASTNode] = []
         while !check(.keyword("case")) && !check(.keyword("default")) && !check(.punctuation("}")) && !isAtEnd() {
             if let stmt = parseStatement() {
                 stmts.append(stmt)
             }
         }
         return BlockNode(statements: stmts)
    }
    
    // Expressions
    
    private func parseExpression() -> ASTNode {
        return parseEquality()
    }
    
    private func parseEquality() -> ASTNode {
        var expr = parseComparison()
        while match(.operator("==")) || match(.operator("!=")) {
            let op = previous()
            let right = parseComparison()
            expr = BinaryOpNode(left: expr, operatorToken: op == .operator("==") ? "==" : "!=", right: right)
        }
        return expr
    }
    
    private func parseComparison() -> ASTNode {
        var expr = parseTerm()
        while match(.operator("<")) || match(.operator(">")) || match(.operator("<=")) || match(.operator(">=")) {
            if case .operator(let op) = previous() {
                let right = parseTerm()
                expr = BinaryOpNode(left: expr, operatorToken: op, right: right)
            }
        }
        if match(.operator("..<")) || match(.operator("...")) {
             if case .operator(let op) = previous() {
                 let right = parseTerm()
                 expr = BinaryOpNode(left: expr, operatorToken: op, right: right)
             }
        }
        return expr
    }
    
    private func parseTerm() -> ASTNode {
        var expr = parseFactor()
        while match(.operator("+")) || match(.operator("-")) {
            if case .operator(let op) = previous() {
                 let right = parseFactor()
                 expr = BinaryOpNode(left: expr, operatorToken: op, right: right)
            }
        }
        return expr
    }
    
    private func parseFactor() -> ASTNode { // * /
        var expr = parseCallOrSubscript()
        while match(.operator("*")) || match(.operator("/")) {
             if case .operator(let op) = previous() {
                 let right = parseCallOrSubscript()
                 expr = BinaryOpNode(left: expr, operatorToken: op, right: right)
             }
        }
        return expr
    }
    
    private func parseCallOrSubscript() -> ASTNode {
        var expr = parsePrimary()
        
        while true {
            if match(.punctuation("(")) {
                // Parse arguments
                var args: [ASTNode] = []
                while !check(.punctuation(")")) && !isAtEnd() {
                     // Check for label:
                     if case .identifier = peek(), peekNext() == .punctuation(":") {
                          _ = advance() // label
                          _ = advance() // :
                     }
                     args.append(parseExpression())
                     match(.punctuation(","))
                }
                consume(.punctuation(")"), message: "Expected ')' after function arguments")
                
                if let varNode = expr as? VariableNode {
                     expr = CallNode(callee: varNode.name, arguments: args)
                } else if expr is MethodCallNode {
                     // Chained call? Not handled simply
                }
            } else if match(.punctuation("[")) {
                let index = parseExpression()
                consume(.punctuation("]"), message: "Expected ']' after subscript index")
                expr = SubscriptNode(target: expr, index: index)
            } else if match(.operator(".")) {
                 if case .identifier(let method) = advance() {
                     // We need to parse optional call arguments if it's a method call
                     if check(.punctuation("(")) {
                         consume(.punctuation("("), message: "Expected '(' for method call")
                         var args: [ASTNode] = []
                         while !check(.punctuation(")")) && !isAtEnd() {
                             if case .identifier = peek(), peekNext() == .punctuation(":") {
                                  _ = advance() // label
                                  _ = advance() // :
                             }
                             args.append(parseExpression())
                             match(.punctuation(","))
                         }
                         consume(.punctuation(")"), message: "Expected ')' after method arguments")
                         expr = MethodCallNode(target: expr, methodName: method, arguments: args)
                     } else {
                         // Property access - treat as variable/method with no args?
                         expr = MethodCallNode(target: expr, methodName: method, arguments: [])
                     }
                 }
            } else if match(.operator("!")) {
                expr = ForceUnwrapNode(expression: expr)
            } else if match(.keyword("as")) {
                 if match(.operator("!")) {
                     guard case .identifier(let typeName) = advance() else {
                         errors.append("Expected type after 'as!'")
                         return expr
                     }
                     expr = CastForceNode(expression: expr, type: typeName)
                 } else {
                     // as? or just as not supported in this sim fully
                     _ = advance() // type
                 }
            } else {
                break
            }
        }
        return expr
    }
    

    
    private func parseTry() -> ASTNode {
        // Handle try! 
        // We only support try! for this level
        if match(.operator("!")) {
            let expr = parseExpression()
            return TryForceNode(expression: expr)
        }
        // Fallback for just try
        return parseExpression()
    }
    
    private func parsePrimary() -> ASTNode {
        if match(.keyword("try")) { return parseTry() }
        if match(.keyword("true")) { return LiteralNode(value: true) }
        if match(.keyword("false")) { return LiteralNode(value: false) }
        
        if case .literal(let v) = peek() {
            advance()
            // Try to convert to Int/Double
            if let intVal = Int(v) { return LiteralNode(value: intVal) }
            if let doubleVal = Double(v) { return LiteralNode(value: doubleVal) }
            return LiteralNode(value: v)
        }
        if case .identifier(let name) = peek() {
            advance()
            return VariableNode(name: name)
        }
        if match(.punctuation("(")) {
            // Check if it's a tuple or just parenthesized expr
            // Tuple has labels "x: 1" or multiple elements "1, 2"
            // Parenthesized expr is just "(1)"
            
            // We need to look ahead or parse optimistically
            // Let's rely on comma or label
            var elements: [(String?, ASTNode)] = []
            
            if !check(.punctuation(")")) {
                repeat {
                    var label: String? = nil
                    if case .identifier(let name) = peek(), peekNext() == .punctuation(":") {
                        label = name
                        advance() // name
                        advance() // :
                    }
                    
                    let expr = parseExpression()
                    elements.append((label, expr))
                } while match(.punctuation(","))
            }
            consume(.punctuation(")"), message: "Expected ')' after tuple elements")
            
            if elements.count == 1 && elements[0].0 == nil {
                return elements[0].1 // Just parenthesized expression
            }
            return TupleNode(elements: elements)
        }
        if match(.punctuation("[")) { // Array or Dictionary
             // Peek next to decide?
             // Simple array [1,2,3]
             // Dictionary ["a": 1]
             var elements: [ASTNode] = []
             var isDict = false
             var dictElements: [(ASTNode, ASTNode)] = []
             
             if !check(.punctuation("]")) {
                  let first = parseExpression()
                  if match(.punctuation(":")) {
                      isDict = true
                      let val = parseExpression()
                      dictElements.append((first, val))
                  } else {
                      elements.append(first)
                  }
                  
                  while match(.punctuation(",")) {
                      let keyOrVal = parseExpression()
                      if isDict {
                          consume(.punctuation(":"))
                          let val = parseExpression()
                          dictElements.append((keyOrVal, val))
                      } else {
                          elements.append(keyOrVal)
                      }
                  }
             }
             consume(.punctuation("]"), message: "Expected ']' after array or dictionary definition")
             
             return isDict ? DictionaryNode(elements: dictElements) : ArrayNode(elements: elements)
        }
        
        advance() // Fail safe
        return LiteralNode(value: 0)
    }

    // MARK: - Helpers
    @discardableResult
    private func match(_ type: TokenType) -> Bool {
        if check(type) {
            advance()
            return true
        }
        return false
    }
    
    private func check(_ type: TokenType) -> Bool {
        if isAtEnd() { return false }
        if case .keyword = type, case .keyword = peek() { return peek() == type }
        if case .operator = type, case .operator = peek() { return peek() == type }
        if case .punctuation = type, case .punctuation = peek() { return peek() == type }
        return peek() == type
    }
    
    @discardableResult
    private func advance() -> TokenType {
        if !isAtEnd() { current += 1 }
        return previous()
    }
    
    private func isAtEnd() -> Bool {
        return peek() == .eof
    }
    
    private func peek() -> TokenType {
        return tokens[current]
    }
    
    private func peekNext() -> TokenType {
        if current + 1 >= tokens.count { return .eof }
        return tokens[current + 1]
    }
    
    private func previous() -> TokenType {
        return tokens[current - 1]
    }
    
    private func consume(_ type: TokenType, message: String? = nil) {
        if check(type) {
            advance()
        } else {
            let errorMsg = message ?? "Expected \(type)"
            errors.append("Syntax Error: \(errorMsg)")
        }
    }
}

// MARK: - Executor
class Executor {
    var output: String = ""
    private var stack: [[String: Any]] = [[:]] // Stack of scopes
    private var functions: [String: FuncDeclNode] = [:]
    private var shouldReturn = false
    private var returnValue: Any? = nil
    
    func execute(_ node: ASTNode, initialContext: [String: Any] = [:]) -> String {
        // Only initialize if stack is empty or we want to force reset
        if stack.isEmpty || (stack.count == 1 && stack[0].isEmpty) {
            stack = [initialContext]
            functions = [:]
        } else {
            // Merge initialContext into current top scope
            for (k, v) in initialContext {
                defineVar(k, v)
            }
        }
        
        output = ""
        shouldReturn = false
        returnValue = nil
        
        eval(node)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func resolveInterpolation(_ text: String) -> String {
        var result = text
        var searchRange = result.startIndex..<result.endIndex
        
        while let range = result.range(of: "\\\\\\((.*?)\\)", options: .regularExpression, range: searchRange) {
            let exprRange = result.index(range.lowerBound, offsetBy: 2)..<result.index(range.upperBound, offsetBy: -1)
            let exprString = String(result[exprRange])
            
            let tokenizer = Tokenizer(exprString)
            let tokens = tokenizer.tokenize()
            let parser = Parser(tokens)
            let ast = parser.parse()
            
            if let first = ast.statements.first {
                let val = evalExpression(first)
                let valStr = "\(val)"
                result.replaceSubrange(range, with: valStr)
                
                // Update search range to after the replacement to avoid infinite loops if replacement contains interpolation patterns
                let newStart = result.index(range.lowerBound, offsetBy: valStr.count)
                searchRange = newStart..<result.endIndex
            } else {
                result.replaceSubrange(range, with: "")
                searchRange = range.lowerBound..<result.endIndex
            }
        }
        return result
    }
    
    private func getVar(_ name: String) -> Any? {
        let key = name.lowercased()
        // Search stack top to bottom
        for scope in stack.reversed() {
            if let val = scope[key] { return val }
        }
        return nil
    }
    
    private func setVar(_ name: String, _ value: Any) {
        let key = name.lowercased()
         // Update existing
        for i in (0..<stack.count).reversed() {
             if stack[i].keys.contains(key) {
                 stack[i][key] = value
                 return
             }
        }
        // Else define in current (top)
        stack[stack.count - 1][key] = value
    }
    
    private func defineVar(_ name: String, _ value: Any) {
        stack[stack.count - 1][name.lowercased()] = value
    }
    
    private func eval(_ node: ASTNode) {
        if shouldReturn { return }
        
        if let block = node as? BlockNode {
            for stmt in block.statements {
                eval(stmt)
                if shouldReturn { return }
            }
        } else if let printNode = node as? PrintNode {
            let val = evalExpression(printNode.expression)
            output += "\(val)\n"
        } else if let varDecl = node as? VariableDeclNode {
            let val = evalExpression(varDecl.value)
            defineVar(varDecl.name, val)
        } else if let assignment = node as? AssignmentNode {
            let val = evalExpression(assignment.value)
            setVar(assignment.name, val)
        } else if let ifNode = node as? IfNode {

            
            if ifNode.isBinding, let name = ifNode.bindingName {
                let val = evalExpression(ifNode.condition)
                // Check for nil/"nil"
                let isNil = (val as? String) == "nil" || (val as? String) == "Optional(nil)"
                // Also could be actual nil if we supported Optional type properly
                // Our interpreter uses "nil" string for nil.
                
                if !isNil {
                    // Unwrap: if "Optional(x)", extract x? 
                    // Or if simple value, bind it.
                    // Let's execute block with new scope
                    var unwrapped = val
                    if let str = val as? String, str.hasPrefix("Optional("), str.hasSuffix(")") {
                        unwrapped = String(str.dropFirst(9).dropLast())
                    }
                    
                    // Push scope
                    stack.append([name: unwrapped])
                    eval(ifNode.trueBlock)
                    stack.removeLast()
                    return // Done
                }
            } else {
                if isTruthy(evalExpression(ifNode.condition)) {
                     eval(ifNode.trueBlock)
                     return
                }
            }
            
            // Else
            if let elseBlock = ifNode.falseBlock {
                eval(elseBlock)
            }
        } else if let switchNode = node as? SwitchNode {
            let val = evalExpression(switchNode.expression)
            var matched = false
            for (pattern, block) in switchNode.cases {
                let patternVal = evalExpression(pattern)
                if isEqual(val, patternVal) {
                    eval(block)
                    matched = true
                    break
                }
            }
            if !matched, let def = switchNode.defaultCase {
                eval(def)
            }
        } else if let whileNode = node as? WhileNode {
            var limit = 0
            while isTruthy(evalExpression(whileNode.condition)) && limit < 1000 {
                eval(whileNode.body)
                limit += 1
                if shouldReturn { return }
            }
        } else if let forNode = node as? ForNode {
            let seq = evalExpression(forNode.sequence)

             if let range = seq as? Range<Int> {
                 for i in range {
                     defineVar(forNode.variable, i)
                     eval(forNode.body)
                     if shouldReturn { return }
                 }
             } else if let arr = seq as? [Any] {
                 for item in arr {
                     defineVar(forNode.variable, item)
                     eval(forNode.body)
                     if shouldReturn { return }
                 }
             }
        } else if let funcDecl = node as? FuncDeclNode {
            functions[funcDecl.name.lowercased()] = funcDecl
        } else if let returnNode = node as? ReturnNode {
            if let valExpr = returnNode.value {
                returnValue = evalExpression(valExpr)
            }
            shouldReturn = true
        } else if let call = node as? CallNode { // Standalone call statement
            _ = evalFunctionCall(call)
        } else if let method = node as? MethodCallNode {
             _ = evalMethodCall(method)
        }
    }
    
    private func evalExpression(_ node: ASTNode) -> Any {
        if let literal = node as? LiteralNode {
            if let str = literal.value as? String {
                return resolveInterpolation(str)
            }
            return literal.value
        }
        if let varNode = node as? VariableNode {
            return getVar(varNode.name) ?? "nil"
        }
        if let binary = node as? BinaryOpNode {
            let left = evalExpression(binary.left)
            let right = evalExpression(binary.right)
            

            switch binary.operatorToken {
            case "+": return add(left, right)
            case "-": return sub(left, right)
            case "*": return mul(left, right)
            case "/": 
                // Division by zero check
                if let i2 = right as? Int, i2 == 0 {
                    output += "Runtime Error: Division by zero\n"
                    shouldReturn = true
                    return 0
                }
                return div(left, right)
            case "==": return isEqual(left, right)
            case "!=": return !isEqual(left, right)
            case ">": return compare(left, right, >)
            case "<": return compare(left, right, <)
            case ">=": return compare(left, right, >=)
            case "<=": return compare(left, right, <=)
            case "..<": 
                if let l = left as? Int, let r = right as? Int { return l..<r }
                return left
            case "...":
                if let l = left as? Int, let r = right as? Int { return l...r }
                return left
            default: return 0
            }
        }
        if let array = node as? ArrayNode {
            return array.elements.map { evalExpression($0) }
        }
        if let dict = node as? DictionaryNode {
             var d: [AnyHashable: Any] = [:]
             for (k, v) in dict.elements {
                 if let key = evalExpression(k) as? AnyHashable {
                     d[key] = evalExpression(v)
                 }
             }
             return d
        }
        if let tuple = node as? TupleNode {
            var d: [String: Any] = [:]
            for (i, (label, valExpr)) in tuple.elements.enumerated() {
                let val = evalExpression(valExpr)
                d["\(i)"] = val
                if let lbl = label {
                    d[lbl] = val
                }
            }
            return d
        }
        if let sub = node as? SubscriptNode {
             let target = evalExpression(sub.target)
             let index = evalExpression(sub.index)
             if let arr = target as? [Any], let i = index as? Int {
                 if i >= 0 && i < arr.count {
                     return arr[i]
                 } else {
                     output += "Runtime Error: Index out of range\n"
                     shouldReturn = true
                     return "nil"
                 }
             }
             if let d = target as? [AnyHashable: Any], let k = index as? AnyHashable {
                 if let val = d[k] {
                     // Check if it's already an Optional string to avoid double wrapping
                     let valStr = "\(val)"
                     if valStr.hasPrefix("Optional(") && valStr.hasSuffix(")") {
                         return valStr
                     }
                     return "Optional(\(val))"
                 }
                 return "nil"
             }
             // String indexing simulation?
             if let str = target as? String, let i = index as? Int {
                 // Simulate string index
                 if i >= 0 && i < str.count {
                     let idx = str.index(str.startIndex, offsetBy: i)
                     return String(str[idx])
                 } else {
                     output += "Fatal error: String index out of range\n"
                     shouldReturn = true
                     return "nil"
                 }
             }
             
             return "nil"
        }

        if let call = node as? CallNode {
            return evalFunctionCall(call)
        }
        if let method = node as? MethodCallNode {
             return evalMethodCall(method)
        }
        if let unwrap = node as? ForceUnwrapNode {
            let val = evalExpression(unwrap.expression)
            let valStr = "\(val)"
            if valStr == "nil" || valStr == "Optional(nil)" {
                output += "Fatal error: Unexpectedly found nil while unwrapping an Optional value\n"
                shouldReturn = true
                return "nil"
            }
            if valStr.hasPrefix("Optional("), valStr.hasSuffix(")") {
                return String(valStr.dropFirst(9).dropLast())
            }
            return val

        }
        if let tryForce = node as? TryForceNode {
             // Simulate specific errors based on expression
             // E.g. File read
             // We'll evaluate expression. If it's a call to readFile, we check input.
             // But evaluateExpression evaluates it.
             // We need to implement readFile in `evalFunctionCall` or logic here.
             // Let's assume standard eval. If standard eval returns an error string (simulated), we crash.
             let val = evalExpression(tryForce.expression)
             if let str = val as? String, str.hasPrefix("Error:") {
                 output += "Fatal error: 'try!' expression unexpectedly raised an error: \(str)\n"
                 shouldReturn = true
                 return "nil"
             }
             return val
        }
        if let castForce = node as? CastForceNode {
            let val = evalExpression(castForce.expression)
            // Simple type check simulation
            // If type is "Int" and val is String -> Crash
            // If type is "String" and val is Int -> Crash
            let targetType = castForce.type
            var isMatch = false
            
            if targetType == "Int" && val is Int { isMatch = true }
            if targetType == "String" && val is String { isMatch = true }
            if targetType == "Double" && val is Double { isMatch = true }
            if targetType == "Any" { isMatch = true }
            
            if !isMatch {
                output += "Could not cast value of type '\(type(of: val))' to '\(targetType)'\n"
                shouldReturn = true
                return "nil"
            }
            return val
        }
        return 0
    }
    
    private func evalFunctionCall(_ call: CallNode) -> Any {
        guard let funcDecl = functions[call.callee.lowercased()] else { return "nil" }
        
        // Stack Depth Check
        if stack.count > 100 {
            output += "Fatal error: Stack overflow\n"
            shouldReturn = true
            return "nil"
        }
        
        // New Scope
        var newScope: [String: Any] = [:]
        for (i, argExpr) in call.arguments.enumerated() {
            if i < funcDecl.parameters.count {
                newScope[funcDecl.parameters[i]] = evalExpression(argExpr)
            }
        }
        
        stack.append(newScope)
        
        let prevReturn = shouldReturn
        shouldReturn = false
        
        eval(funcDecl.body)
        
        let ret = returnValue
        
        // Restore state
        shouldReturn = prevReturn
        returnValue = nil
        stack.removeLast()
        
        return ret ?? "nil"
    }
    
    private func evalMethodCall(_ method: MethodCallNode) -> Any {
        let target = evalExpression(method.target)
        
        // Handle Tuple Property Access (e.g. point.x)
        if let d = target as? [String: Any], method.arguments.isEmpty {
            if let val = d[method.methodName] {
                 return val
            }
        }
        
        // Arrays
        if let arr = target as? [Any] {
            if method.methodName == "count" {
                return arr.count
            } else if method.methodName == "append" {
                 if var newArr = target as? [Any], let val = method.arguments.first {
                     let valueToAppend = evalExpression(val)
                     newArr.append(valueToAppend)
                     
                     // Try to update variable if target is variable
                     if let varNode = method.target as? VariableNode {
                         setVar(varNode.name, newArr)
                     }
                     return newArr // Return new array (though usually append returns Void/Self)
                 }
            } else if method.methodName == "removeFirst" {
                 if var newArr = target as? [Any] {
                     if newArr.isEmpty {
                         output += "Runtime Error: Can't remove first element from an empty collection\n"
                         shouldReturn = true
                         return "nil"
                     }
                     let val = newArr.removeFirst()
                     if let varNode = method.target as? VariableNode {
                         setVar(varNode.name, newArr)
                     }
                     return val
                 }
            } else if method.methodName == "removeLast" {
                 if var newArr = target as? [Any] {
                     if newArr.isEmpty {
                         output += "Runtime Error: Can't remove last element from an empty collection\n"
                         shouldReturn = true
                         return "nil"
                     }
                     let val = newArr.removeLast()
                     if let varNode = method.target as? VariableNode {
                         setVar(varNode.name, newArr)
                     }
                     return val
                 }
            }
        }
        
        return "nil"
    }
    
    // Helpers
    private func add(_ a: Any, _ b: Any) -> Any {
        if let s1 = a as? String { return s1 + "\(b)" }
        if let s2 = b as? String { return "\(a)" + s2 }
        if let i1 = a as? Int, let i2 = b as? Int { return i1 + i2 }
        if let d1 = a as? Double, let d2 = b as? Double { return d1 + d2 }
        return 0
    }
    private func sub(_ a: Any, _ b: Any) -> Any {
        if let i1 = a as? Int, let i2 = b as? Int { return i1 - i2 }
        return 0
    }
    private func mul(_ a: Any, _ b: Any) -> Any {
        if let i1 = a as? Int, let i2 = b as? Int { return i1 * i2 }
        return 0
    }
    private func div(_ a: Any, _ b: Any) -> Any {
        if let i1 = a as? Int, let i2 = b as? Int { return i2 == 0 ? 0 : i1 / i2 }
        return 0
    }
    private func isEqual(_ a: Any, _ b: Any) -> Bool {
        return "\(a)" == "\(b)"
    }
    private func compare(_ a: Any, _ b: Any, _ op: (Double, Double) -> Bool) -> Bool {
        let v1 = Double("\(a)") ?? 0
        let v2 = Double("\(b)") ?? 0
        return op(v1, v2)
    }
    private func isTruthy(_ a: Any) -> Bool {
        if let b = a as? Bool { return b }
        if let i = a as? Int { return i != 0 }
        return false
    }
}

class SimpleInterpreter {
    private let executor = Executor()
    
    func evaluate(code: String, context: [String: Any] = [:]) -> String {
        let tokenizer = Tokenizer(code)
        let tokens = tokenizer.tokenize()
        let parser = Parser(tokens)
        let ast = parser.parse()
        
        if !parser.errors.isEmpty {
            return parser.errors.joined(separator: "\n")
        }
        
        return executor.execute(ast, initialContext: context)
    }
}
