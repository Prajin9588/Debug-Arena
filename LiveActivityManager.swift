import Foundation
import ActivityKit

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<ExecutionAttributes>?
    private var simulationTask: Task<Void, Never>?
    
    func startActivity(threadName: String) {
        let attributes = ExecutionAttributes(threadName: threadName)
        let initialState = ExecutionAttributes.ContentState(
            status: .cleaning,
            phase: .compiling,
            progress: 0.0,
            currentLog: "Initializing Analyzer...",
            healthSegments: Array(repeating: true, count: 12),
            xpEarned: 0,
            streak: 0
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            currentActivity = try Activity.request(attributes: attributes, content: content)
            // Start simulation wrapper
            simulationTask = Task {
                await simulateExecutionFlow()
            }
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func simulateExecutionFlow() async {
        // Phase 1: Compiling (Short duration)
        var compileProgress = 0.0
        
        // Loop for compilation
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            compileProgress += 0.1
            
            let state = ExecutionAttributes.ContentState(
                status: .cleaning,
                phase: .compiling,
                progress: compileProgress,
                currentLog: "Compiling Source...",
                healthSegments: Array(repeating: true, count: 12),
                xpEarned: 0,
                streak: 0
            )
            
            let content = ActivityContent(state: state, staleDate: nil)
            await currentActivity?.update(content)
        }
        
        // Transition to Debugging
        await startDebuggingSimulation()
    }
    
    private func startDebuggingSimulation() async {
        var progress = 0.0
        var segments = Array(repeating: true, count: 12)
        
        // Loop for debugging
        while progress < 1.0 && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            progress += 0.1
            
            // Randomly introduce errors during debugging
            if Double.random(in: 0...1) > 0.7 {
                let index = Int.random(in: 0..<segments.count)
                segments[index] = false
            } else if Double.random(in: 0...1) > 0.6 {
                if let errorIndex = segments.firstIndex(of: false) {
                    segments[errorIndex] = true
                }
            }
            
            let status: ExecutionAttributes.ContentState.ExecutionStatus = segments.contains(false) ? .error : .cleaning
            
            let newState = ExecutionAttributes.ContentState(
                status: status,
                phase: .debugging,
                progress: min(progress, 1.0),
                currentLog: "Analyzing Line \(Int(progress * 100))...",
                healthSegments: segments,
                xpEarned: 0,
                streak: 0
            )
            
            let content = ActivityContent(state: newState, staleDate: nil)
            await currentActivity?.update(content)
        }
    }
    
    func endWithSuccess(xp: Int, streak: Int) {
        simulationTask?.cancel()
        
        let finalState = ExecutionAttributes.ContentState(
            status: .fixed,
            phase: .success,
            progress: 1.0,
            currentLog: "Optimization Complete",
            healthSegments: Array(repeating: true, count: 12),
            xpEarned: xp,
            streak: streak
        )
        
        let content = ActivityContent(state: finalState, staleDate: nil)
        
        Task {
            await currentActivity?.update(content)
            // Keep success state visible for a moment
            try? await Task.sleep(nanoseconds: 4_000_000_000) // 4s
            await endActivity()
        }
    }
    
    func endWithFailure(error: String) {
        simulationTask?.cancel()
        
        let finalState = ExecutionAttributes.ContentState(
            status: .error,
            phase: .failed,
            progress: 1.0,
            currentLog: error,
            healthSegments: Array(repeating: false, count: 12), // All red
            xpEarned: 0,
            streak: 0
        )
        
        let content = ActivityContent(state: finalState, staleDate: nil)
        
        Task {
            await currentActivity?.update(content)
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await endActivity()
        }
    }
    
    func endActivity() async {
        let contentState = currentActivity?.content.state ?? ExecutionAttributes.ContentState(
             status: .cleaning, phase: .failed, progress: 0, currentLog: "", healthSegments: [], xpEarned: 0, streak: 0
        )
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        await currentActivity?.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
        simulationTask?.cancel()
    }
}
