import SwiftUI

struct QuestionDashboardView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var hasTriggeredAppearAnimation = false
    
    var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 8 : 4
        return Array(repeating: GridItem(.fixed(65), spacing: 15), count: count)
    }
    
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
                        
                        let totalQuestions = gameManager.currentLevel.questions.count
                        
                        if totalQuestions <= 25 {
                            // Single Section
                             VStack(alignment: .leading, spacing: 15) {
                                Text("MODULES (1–\(totalQuestions))")
                                    .font(Theme.Typography.caption2)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .tracking(2)
                                    .padding(.leading)
                                
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(0..<totalQuestions, id: \.self) { index in
                                        QuestionTile(index: index)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
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
                                Text("ADVANCED MODULES (26–\(totalQuestions))")
                                    .font(Theme.Typography.caption2)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .tracking(2)
                                    .padding(.leading)
                                
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(25..<totalQuestions, id: \.self) { index in
                                        QuestionTile(index: index)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !hasTriggeredAppearAnimation {
                gameManager.triggerScatter()
                hasTriggeredAppearAnimation = true
            }
        }
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
        VStack(spacing: 16) { // Increased spacing for cleaner look
            HStack {
                // Language Badge
                HStack(spacing: 8) {
                    Image(systemName: gameManager.selectedLanguage.iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.accent)
                    Text(gameManager.selectedLanguage.rawValue.uppercased())
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textPrimary) // Black on White
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.Colors.accent.opacity(0.1))
                .clipShape(Capsule()) // More modern shape
                
                Spacer()
                
                // Coins
                HStack(spacing: 6) {
                    BugCoin(size: 22) // Slightly larger
                    Text("\(gameManager.coinBalance)")
                        .font(Theme.Typography.title3) // Larger font
                        .foregroundColor(Theme.Colors.textPrimary) // Black on White
                }
                .overlay(
                    CoinScatterView(trigger: gameManager.scatterTrigger)
                )
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("COMPLETION")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(progress) / \(gameManager.currentLevel.questions.count)")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .fontWeight(.bold)
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.08)) // Distinct light grey track
                            .frame(height: 10) // Slightly thicker
                        
                        let fillWidth = geo.size.width * CGFloat(Double(progress) / Double(max(1, gameManager.currentLevel.questions.count)))
                        
                        Capsule()
                            .fill(isThresholdReached ? Theme.Colors.success : Theme.Colors.accent)
                            .frame(width: max(10, fillWidth), height: 10) // Ensure min width for visibility
                            .shadow(color: (isThresholdReached ? Theme.Colors.success : Theme.Colors.accent).opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(20)
        .background(Theme.Colors.babyPowder)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5) // Soft, premium shadow
        .padding(.horizontal)
    }
}

struct QuestionTile: View {
    @EnvironmentObject var gameManager: GameManager
    let index: Int
    @State private var isAnimate = false
    
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
        gameManager.attempts[question.title, default: 0] > 0 || shiftProgress > 0
    }
    
    var shiftProgress: Double {
        gameManager.getShiftProgress(for: question)
    }
    
    var body: some View {
        NavigationLink(destination: QuestionWorkspaceView(questionIndex: index)) {
            ZStack { // Default: .center
                // Base Tile
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
                
                // Status Indicators
                if isCompleted {
                    // Completed State
                } else if shiftProgress > 0 {
                    // Standardized Rounded Progress Ring (Matches Tile Shape)
                    RoundedRectangle(cornerRadius: 15)
                        .trim(from: 0, to: shiftProgress)
                        .stroke(Theme.Colors.electricCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: shiftProgress)
                } else if inProgress {
                    // Indicator for non-shift progress
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(Theme.Colors.electricCyan)
                        .neonGlow(color: Theme.Colors.electricCyan)
                        .frame(width: 65, height: 65, alignment: .topTrailing)
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 65, height: 65) // FORCE fixed size to prevent grid shifting
            .opacity(isAnimate ? 1 : 0)
            .scaleEffect(isAnimate ? 1 : 0.7)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.75)
                .delay(Double(index % 25) * 0.04),
                value: isAnimate
            )
            .onAppear {
                isAnimate = true
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
