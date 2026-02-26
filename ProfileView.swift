import SwiftUI

struct ProfileView: View {
    @ObservedObject var gameManager: GameManager
    
    // Animation State
    @State private var progressAnimated: CGFloat = 0.0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // UI State
    @State private var showingNameEditor = false
    @State private var newUsername = ""
    
    // Derived Stats
    private var rankTitle: String {
        // High priority rule for Swift and C
        if gameManager.selectedLanguage == .swift || gameManager.selectedLanguage == .c {
            // Level-based titles (Strictly after full successful completion)
            for levelIndex in (0..<gameManager.levels.count).reversed() {
                let solved = gameManager.levelProgress(for: levelIndex)
                let total = gameManager.levels[levelIndex].totalQuestions
                
                if solved >= total && total > 0 {
                    switch levelIndex + 1 {
                    case 4: return "Debug Master"
                    case 3: return "Code Detective"
                    case 2: return "Logic Apprentice"
                    case 1: return "Rookie Coder"
                    default: break
                    }
                }
            }
            return "Rookie Coder"
        } else {
            // Legacy / Other languages logic
            switch gameManager.totalXP {
            case 0..<100: return "Novice Debugger"
            case 100..<500: return "Code Detective"
            case 500..<1000: return "Bug Hunter"
            case 1000..<2500: return "System Architect"
            default: return "Grandmaster"
            }
        }
    }
    
    private var nextRankXP: Int {
        switch gameManager.totalXP {
        case 0..<100: return 100
        case 100..<500: return 500
        case 500..<1000: return 1000
        case 1000..<2500: return 2500
        default: return gameManager.totalXP // Max rank
        }
    }
    
    private var xpProgress: CGFloat {
        let currentLevelBase: Int
        switch gameManager.totalXP {
        case 0..<100: currentLevelBase = 0
        case 100..<500: currentLevelBase = 100
        case 500..<1000: currentLevelBase = 500
        case 1000..<2500: currentLevelBase = 1000
        default: return 1.0
        }
        
        let progress = Double(gameManager.totalXP - currentLevelBase)
        let total = Double(nextRankXP - currentLevelBase)
        return CGFloat(progress / total)
    }
    
    private var accuracyValue: Int {
        let totalAttempts = gameManager.attempts.values.reduce(0, +)
        let solved = gameManager.completedQuestionIds.count
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(solved) / Double(totalAttempts)) * 100)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. Header Section
                headerSection
                
                // 2. XP Progress Section
                xpProgressSection
                
                // 3. Stats Section (Linear Stack)
                statsStackSection
                
                // 4. Performance Summary
                performanceSummarySection
                
                // 5. Settings Section
                settingsSection
                
                Spacer(minLength: 50)
            }
            .padding(Theme.Layout.padding)
            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.Colors.background(isDark: gameManager.isDarkMode).ignoresSafeArea())
        .alert("Change Username", isPresented: $showingNameEditor) {
            TextField("Username", text: $newUsername)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                gameManager.updateUsername(newUsername)
            }
        } message: {
            Text("Enter your new debugger name.")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                progressAnimated = xpProgress
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 110, height: 110)
                    .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 5)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55)
                    .foregroundColor(Theme.Colors.accent)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(gameManager.username)
                        .font(Theme.Typography.title2)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Button(action: {
                        newUsername = gameManager.username
                        showingNameEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(Theme.Colors.accent)
                            .font(.title3)
                    }
                }
                
                Text(rankTitle.uppercased())
                    .font(Theme.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.electricCyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.electricCyan.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
    
    private var xpProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("XP PROGRESS")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(1)
                Spacer()
                Text("\(gameManager.totalXP) / \(nextRankXP) XP")
                    .font(Theme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 16)
                    
                    Capsule()
                        .fill(Theme.Colors.primaryGradient)
                        .frame(width: geo.size.width * progressAnimated, height: 16)
                        .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
            .frame(height: 16)
        }
        .padding(20)
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
    }
    
    private var statsStackSection: some View {
        VStack(spacing: 16) {
            StatRow(
                title: "Total Attempts",
                value: "\(gameManager.attempts.values.reduce(0, +))",
                icon: AnyView(Image(systemName: "hammer.fill")),
                color: Theme.Colors.action
            )
            
            StatRow(
                title: "Challenges Solved",
                value: "\(gameManager.completedQuestionIds.count)",
                icon: AnyView(Image(systemName: "checkmark.seal.fill")),
                color: Theme.Colors.success
            )
            
            StatRow(
                title: "Current Streak",
                value: "\(gameManager.currentStreak) Days",
                icon: AnyView(StreakFireView(streak: gameManager.currentStreak)),
                color: .orange
            )
            
            StatRow(
                title: "Accuracy Rate",
                value: "\(accuracyValue)%",
                icon: AnyView(Image(systemName: "target")),
                color: Theme.Colors.accent
            )
        }
    }
    
    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERFORMANCE OVERVIEW")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .tracking(1)
                .padding(.leading, 5)
            
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(performanceTitle)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(performanceMessage)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
        }
    }
    
    // Performance Logic
    private var performanceTitle: String {
        if accuracyValue < 40 { return "Room for Improvement" }
        if accuracyValue < 70 { return "Steady Progress" }
        return "Excellent Performance"
    }
    
    private var performanceMessage: String {
        if accuracyValue < 40 { return "Keep practicing! Focus on understanding the error messages to improve your accuracy." }
        if accuracyValue < 70 { return "You're getting there! Try to double-check your logic before running the code." }
        return "You're crushing it! Your debugging skills are becoming sharp and efficient."
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .tracking(1)
                .padding(.leading, 5)
            
            HStack {
                Image(systemName: gameManager.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.accent)
                
                Text(gameManager.isDarkMode ? "Dark Mode" : "Light Mode")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { gameManager.isDarkMode },
                    set: { newValue in
                        gameManager.isDarkMode = newValue
                        Theme.isDarkMode = newValue
                        gameManager.saveProgress()
                    }
                ))
                .labelsHidden()
                .tint(Theme.Colors.accent)
            }
            .padding(20)
            .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
            
            Button(action: {
                gameManager.onboardingStep = 0
                gameManager.replayOnboarding()
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    Text("Replay Career Path Intro")
                        .font(Theme.Typography.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .foregroundColor(Theme.Colors.textPrimary.opacity(0.8))
                .padding(20)
                .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
                .cornerRadius(Theme.Layout.cornerRadius)
                .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
            }
            
            Button(action: {
                gameManager.replayLevelOnboarding()
            }) {
                HStack {
                    Image(systemName: "map.fill")
                        .font(.title2)
                    Text("Replay Level Progression Intro")
                        .font(Theme.Typography.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .foregroundColor(Theme.Colors.textPrimary.opacity(0.8))
                .padding(20)
                .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
                .cornerRadius(Theme.Layout.cornerRadius)
                .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
            }
        }
    }
}

// MARK: - Reusable Components

struct StatRow: View {
    @EnvironmentObject var gameManager: GameManager
    let title: String
    let value: String
    let icon: AnyView
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                icon
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(title)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.Layout.padding)
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius, y: 2)
    }
}
