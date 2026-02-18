import SwiftUI

struct QuestionDashboardView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 65), spacing: 15)
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(Theme.Colors.accent)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    
                    Text(gameManager.currentLevel.title.uppercased())
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .tracking(2)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)

                // Header Stats - Moved outside ScrollView to be sticky/always visible
                DashboardHeader()
                    .padding(.bottom, 15)

                ScrollView {
                    VStack(spacing: 30) {
                        // Header Stats removed from here
                        
                        // Section A
                        VStack(alignment: .leading, spacing: 15) {
                            Text("CORE MODULES (1–25)")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(2)
                                .padding(.leading)
                            
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(0..<25, id: \.self) { index in
                                    QuestionTile(index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Section B
                        VStack(alignment: .leading, spacing: 15) {
                            Text("ADVANCED MODULES (26–50)")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(2)
                                .padding(.leading)
                            
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(25..<50, id: \.self) { index in
                                    QuestionTile(index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct DashboardHeader: View {
    @EnvironmentObject var gameManager: GameManager
    
    var progress: Int {
        gameManager.levelProgress(for: gameManager.currentLevelIndex)
    }
    
    var isThresholdReached: Bool {
        gameManager.unlockThresholdReached(for: gameManager.currentLevelIndex)
    }
    
    var body: some View {
        GlassBar {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: gameManager.selectedLanguage.iconName)
                            .foregroundColor(Theme.Colors.accent)
                        Text(gameManager.selectedLanguage.rawValue.uppercased())
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        BugCoin(size: 18)
                        Text("\(gameManager.coinBalance)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.gold)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("COMPLETION: \(progress) / 50")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        Spacer()
                        if isThresholdReached {
                            Text("NEXT LEVEL GO")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.success)
                        }
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        Capsule()
                            .fill(isThresholdReached ? Theme.Colors.success : Theme.Colors.accent)
                            .frame(width: (UIScreen.main.bounds.width - 80) * CGFloat(Double(progress) / 50.0), height: 8)
                            .neonGlow(color: isThresholdReached ? Theme.Colors.success : Theme.Colors.accent, radius: 4)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct QuestionTile: View {
    @EnvironmentObject var gameManager: GameManager
    let index: Int
    
    var question: Question {
        if gameManager.currentLevel.questions.indices.contains(index) {
            return gameManager.currentLevel.questions[index]
        }
        return gameManager.currentLevel.questions[0]
    }
    
    var isCompleted: Bool {
        gameManager.completedQuestionIds.contains(question.title)
    }
    
    var inProgress: Bool {
        gameManager.attempts[question.title, default: 0] > 0
    }
    
    var body: some View {
        NavigationLink(destination: QuestionWorkspaceView(questionIndex: index)) {
            ZStack(alignment: .topTrailing) {
                Text("\(index + 1)")
                    .font(Theme.Typography.headline)
                    .frame(width: 65, height: 65)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(borderColor, lineWidth: 2)
                    )
                
                if inProgress && !isCompleted {
                    Circle()

                        .frame(width: 12, height: 12)
                        .offset(x: 4, y: -4)
                        .neonGlow(color: Theme.Colors.electricCyan)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var backgroundColor: Color {
        if isCompleted { return Theme.Colors.success.opacity(0.15) }
        if inProgress { return Theme.Colors.electricCyan.opacity(0.1) }
        return Theme.Colors.secondaryBackground
    }
    
    var borderColor: Color {
        if isCompleted { return Theme.Colors.success }
        if inProgress { return Theme.Colors.electricCyan }
        if index == gameManager.currentQuestionIndex { return Theme.Colors.accent }
        return Color.white.opacity(0.1)
    }
    
    var textColor: Color {
        if isCompleted { return Theme.Colors.success }
        if inProgress { return Theme.Colors.electricCyan }
        return Theme.Colors.textPrimary
    }
}
