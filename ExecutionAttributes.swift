import Foundation
import ActivityKit

struct ExecutionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        enum ExecutionStatus: String, Codable {
            case cleaning = "CLEANING"
            case error = "ERROR"
            case fixed = "FIXED"
        }
        
        enum Phase: String, Codable {
            case compiling
            case debugging
            case success
            case failed
        }
        
        var status: ExecutionStatus
        var phase: Phase
        var progress: Double // 0.0 to 1.0
        var currentLog: String
        var healthSegments: [Bool] // true = clean, false = error
        
        // Rewards
        var xpEarned: Int
        var coinsEarned: Int
        var streak: Int
    }
    
    var threadName: String
}
