import Foundation

struct CodeNormalizer {
    static func normalize(_ code: String, language: Language) -> String {
        var processed = code
        
        // 1. Remove Comments
        processed = removeComments(processed, language: language)
        
        // 2. Normalize Whitespace (replace multiple spaces/tabs with single space)
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 3. Standardize Braces/Parentheses (ensure spacing consistency for easy token matching, optional)
        // For strict token validation, usually stripping all whitespace is better, OR ensuring 1 space.
        // Let's strip whitespace around key symbols to make it canonical.
        let symbols = ["{", "}", "(", ")", ";", ",", ":", "+", "-", "*", "/", "=", "==", "!=", "<", ">", "<=", ">="]
        for symbol in symbols {
            processed = processed.replacingOccurrences(of: "\\s*\\\(symbol)\\s*", with: symbol, options: .regularExpression)
        }
        
        return processed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private static func removeComments(_ code: String, language: Language) -> String {
        var pattern = ""
        switch language {
        case .swift, .java, .c, .cpp:
            // Matches // single line and /* multi line */
            pattern = "(//[^\\n]*|/\\*[\\s\\S]*?\\*/)"
        case .python:
            // Matches # single line
            pattern = "(#[^\\n]*)"
        }
        
        return code.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    static func tokenize(_ code: String) -> [String] {
        // Simple tokenizer: split by non-alphanumeric but keep symbols? 
        // Or just return the string chunks?
        // For regex validation, the raw (but normalized) string is often best.
        // But for "missing required syntax", checking for specific keywords is easier on the full string.
        return []
    }
}
