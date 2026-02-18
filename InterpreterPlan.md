import Foundation

// MARK: - AST Nodes
// ... (Previous nodes remain, adding new ones)

struct FuncDeclNode: ASTNode {
    let name: String
    let parameters: [(String, String?)] // (InternalName, ExternalName?) - Simplified to just names for now
    let body: BlockNode
    let returnType: String?
}

struct CallNode: ASTNode {
    let callee: String
    let arguments: [(String?, ASTNode)] // (Label?, Value)
}

struct ReturnNode: ASTNode {
    let value: ASTNode?
}

struct ArrayNode: ASTNode {
    let elements: [ASTNode]
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
    let arguments: [(String?, ASTNode)]
}

// ... (Existing AST Nodes: BlockNode, VariableDeclNode, AssignmentNode, PrintNode, IfNode, SwitchNode, WhileNode, ForNode, BinaryOpNode, LiteralNode, VariableNode)

// MARK: - Tokenizer
// Update tokenizer to handle brackets [] and colon : (already done), and arrow ->
// Update readIdentifier to handle parameters labels if needed.

// MARK: - Parser
// Update parseStatement to check for "func", "return"
// Update parseExpression to identifier -> check for "(" (Call) or "[" (Subscript) or "." (Method)

// MARK: - Executor
// Context needs to store Functions.
class ExecutionContext {
    var variables: [String: Any] = [:]
    var functions: [String: FuncDeclNode] = [:]
    var parent: ExecutionContext?
    
    init(parent: ExecutionContext? = nil) {
        self.parent = parent
    }
    
    func getVariable(_ name: String) -> Any? {
        return variables[name] ?? parent?.getVariable(name)
    }
    
    func setVariable(_ name: String, _ value: Any) {
        if variables.keys.contains(name) {
            variables[name] = value
        } else if let p = parent, p.getVariable(name) != nil {
            p.setVariable(name, value)
        } else {
            variables[name] = value
        }
    }
    
    func defineVariable(_ name: String, _ value: Any) {
        variables[name] = value
    }
    
    func getFunction(_ name: String) -> FuncDeclNode? {
        return functions[name] ?? parent?.getFunction(name)
    }
}

// Update Executor to use ExecutionContext
// Implement eval for new nodes.
