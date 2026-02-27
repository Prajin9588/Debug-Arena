import SwiftUI
import WidgetKit
import ActivityKit

struct ExecutionMonitorWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExecutionAttributes.self) { context in
            // Lock Screen UI
            ExecutionMonitorLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region
                DynamicIslandExpandedRegion(.leading) {
                    Group {
                        if context.state.phase == .success {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(Theme.Colors.accent)
                                Text("STREAK \(context.state.streak)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        } else if context.state.phase == .compiling {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Theme.Colors.textSecondary)
                        } else {
                            HStack {
                                Image(systemName: "cpu.fill")
                                    .foregroundColor(Theme.Colors.accent)
                                Text("DEBUG LAB")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == .success {
                        VStack(alignment: .trailing) {
                            Text("+\(context.state.xpEarned) XP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.Colors.accent)
                        }
                    } else if context.state.phase == .failed {
                        Text("FAILED")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Theme.Colors.error)
                    } else {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.accent)
                            .bold()
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .center, spacing: 10) {
                        if context.state.phase == .success {
                            Text("Bug Squashed! 🐛")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.success)
                                .padding(.top, 5)
                        } else if context.state.phase == .compiling {
                            Text("Compiling System...")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.textSecondary)
                        } else {
                            // Debugging / Standard View
                            VStack(alignment: .leading, spacing: 8) {
                                // Health Bar
                                HStack(spacing: 4) {
                                    ForEach(0..<context.state.healthSegments.count, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(context.state.healthSegments[index] ? Theme.Colors.success : Theme.Colors.error)
                                            .frame(height: 6)
                                    }
                                }
                                
                                // Log
                                Text("> \(context.state.currentLog)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            } compactLeading: {
                if context.state.phase == .success {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Theme.Colors.accent)
                } else if context.state.phase == .compiling {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Theme.Colors.textSecondary)
                } else {
                    StatusPulseView(status: context.state.status)
                }
            } compactTrailing: {
                if context.state.phase == .success {
                    Text("+\(context.state.xpEarned) XP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.accent)
                } else {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.accent)
                }
            } minimal: {
                StatusPulseView(status: context.state.status)
            }
        }
    }
}

struct StatusPulseView: View {
    let status: ExecutionAttributes.ContentState.ExecutionStatus
    
    var body: some View {
        ZStack {
            if status == .fixed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.Colors.success)
            } else if status == .error {
                 Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(Theme.Colors.error)
            } else {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct ExecutionMonitorLockScreenView: View {
    let context: ActivityViewContext<ExecutionAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.threadName)
                        .font(.system(size: 17, weight: .semibold))
                    Text(context.state.status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.accent)
                }
                Spacer()
                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(size: 22, weight: .bold))
                    .bold()
            }
            
            ProgressView(value: context.state.progress)
                .accentColor(Theme.Colors.accent)
            
            Text(context.state.currentLog)
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
    }
}

// Mock Intent for compilation (AppIntents not available in simple SPM without setup)
import AppIntents
struct StopExecutionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Execution"
    func perform() async throws -> some IntentResult {
        // Logic to stop handled by manager
        return .result()
    }
}
