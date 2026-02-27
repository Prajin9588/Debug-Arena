import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var selectedTab: Int // Added binding for navigation
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background(isDark: gameManager.isDarkMode).ignoresSafeArea()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 0. App Title
                        VStack(spacing: 4) {
                            Text("THE DEBUG ARENA")
                                .font(Theme.Typography.title)
                                .fontWeight(.black)
                                .foregroundStyle(Theme.Colors.logoGradient)
                                .tracking(2)
                            
                            Text("Spot it. Break it. Own it.")
                                .font(Theme.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // 1. Professional Header
                        HomeHeader(
                            username: gameManager.username,
                            level: (gameManager.totalXP / 1000) + 1,
                            streak: gameManager.currentStreak,
                            selectedTab: $selectedTab
                        )
                        
                        // 2. Progress Overview Card
                        if gameManager.currentLevelIndex < gameManager.levels.count {
                             ProgressOverviewCard(
                                levelIndex: gameManager.currentLevelIndex,
                                completed: gameManager.levelProgress(for: gameManager.currentLevelIndex),
                                required: gameManager.questionsRequiredForNextLevel(levelIndex: gameManager.currentLevelIndex)
                            )
                        }
                        
                        // 3. Language Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SELECT LANGUAGE")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(1)
                                .padding(.horizontal)
                            
                            let columns = horizontalSizeClass == .regular 
                                ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)] 
                                : [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                LanguageGridCard(
                                    language: "Swift",
                                    icon: "swift",
                                    tag: "Rapid Track",
                                    color: Color(hex: "FF9100"),
                                    action: { gameManager.selectLanguage(.swift) },
                                    isSpotlighted: gameManager.showOnboarding && gameManager.onboardingStep == 1,
                                    badge: "Beginner Friendly"
                                )
                                
                                LanguageGridCard(
                                    language: "C",
                                    icon: "c.circle.fill",
                                    tag: "The Architect",
                                    color: .blue,
                                    action: { gameManager.selectLanguage(.c) },
                                    isSpotlighted: gameManager.showOnboarding && gameManager.onboardingStep == 2,
                                    badge: "Core Foundation"
                                )
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // 4. Level Progression List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CAREER PATH")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(1)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(gameManager.levels) { level in
                                    NavigationLink(destination: QuestionDashboardView()) {
                                        LevelListCard(
                                            level: level,
                                            isLocked: !level.unlocked,
                                            progress: gameManager.levelProgress(for: level.number - 1),
                                            total: level.questions.count,
                                            isSpotlighted: gameManager.showLevelOnboarding && gameManager.levelOnboardingStep == level.number
                                        )
                                    }
                                    .disabled(!level.unlocked)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        if level.unlocked {
                                            gameManager.selectLevel(level.number - 1)
                                        }
                                    })
                                }
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                            
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 10)
                }
                
                // Onboarding Overlay
                if gameManager.showOnboarding {
                    OnboardingOverlayView()
                        .transition(.opacity)
                        .zIndex(100)
                }
                
                // Level Onboarding Overlay
                if gameManager.showLevelOnboarding {
                    LevelOnboardingOverlayView()
                        .transition(.opacity)
                        .zIndex(101)
                }
                
                // Streak Reset Notification (Toast)
                if gameManager.showStreakResetNotification {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            
                            Text(gameManager.streakResetMessage ?? "New day. New streak.")
                                .font(Theme.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(200)
                }
            }
        }
        .preferredColorScheme(gameManager.isDarkMode ? .dark : .light)
    }
}

// MARK: - Components

struct HomeHeader: View {
    let username: String
    let level: Int
    let streak: Int
    @Binding var selectedTab: Int
    
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            Button(action: {
                selectedTab = 2
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
                            .frame(width: 44, height: 44)
                            .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(username.uppercased())
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("Level \(level)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    StreakFireView(streak: streak)
                        .font(.caption)
                    Text("\(streak)")
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
                .clipShape(Capsule())
                .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ProgressOverviewCard: View {
    let levelIndex: Int
    let completed: Int
    let required: Int
    @EnvironmentObject var gameManager: GameManager
    
    var progress: Double {
        return required > 0 ? min(Double(completed) / Double(required), 1.0) : 0
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.background(isDark: gameManager.isDarkMode), lineWidth: 8)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colors.electricCyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                
                Text("\(Int(progress * 100))%")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Progress Overview")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                if levelIndex == 3 {
                    Text("Keep sharpening your logic in Level 4")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                } else {
                    Text("\(completed) / \(required) to unlock Level \(levelIndex + 2)")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                Text("STAY SHARP.")
                    .font(Theme.Typography.caption)
                    .fontWeight(.black)
                    .foregroundColor(Theme.Colors.electricCyan)
                    .tracking(1.5)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding(20)
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius)
        .padding(.horizontal)
    }
}

struct LanguageGridCard: View {
    let language: String
    let icon: String
    let tag: String
    let color: Color
    let action: () -> Void
    var isSpotlighted: Bool = false
    var badge: String? = nil
    
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 20 : 12) {
                HStack {
                    if language == "C" {
                        CLogoView(size: horizontalSizeClass == .regular ? 36 : 28)
                    } else {
                        Image(systemName: icon)
                            .font(horizontalSizeClass == .regular ? .title : .title2)
                            .foregroundColor(color)
                    }
                    Spacer()
                    Text(tag)
                        .font(.system(size: horizontalSizeClass == .regular ? 12 : 9, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(color.opacity(0.1)).cornerRadius(4)
                }
                
                Text(language)
                    .font(horizontalSizeClass == .regular ? .title2 : Theme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if let badge = badge, isSpotlighted {
                    Text(badge)
                        .font(Theme.Typography.caption2)
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(horizontalSizeClass == .regular ? 24 : 16)
            .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: isSpotlighted ? color.opacity(0.5) : Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), 
                    radius: isSpotlighted ? 20 : Theme.Layout.cardShadowRadius)
            .scaleEffect(isSpotlighted ? 1.05 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(color.opacity(isSpotlighted ? 0.6 : 0), lineWidth: 2)
            )
            .animation(.spring(), value: isSpotlighted)
        }
    }
}

// MARK: - Onboarding Components

struct OnboardingOverlayView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                Spacer() // Doubled top spacer to push content lower
                
                if gameManager.onboardingStep == 0 {
                    onboardingScene1
                } else if gameManager.onboardingStep == 1 {
                    onboardingScene2
                } else if gameManager.onboardingStep == 2 {
                    onboardingScene3
                } else if gameManager.onboardingStep == 3 {
                    onboardingScene4
                }
                Spacer()
            }
            .padding(horizontalSizeClass == .regular ? 60 : 40)
            .multilineTextAlignment(.center)
            .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var onboardingScene1: some View {
        VStack(spacing: 24) {
            Text("Every Debugger must choose a path.")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Text("Two roads. Two styles. One Arena.\nYour journey begins with a decision.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: { gameManager.onboardingStep = 1 }) {
                Text("Reveal the Paths")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primaryGradient)
                    .cornerRadius(12)
            }
        }
    }
    
    private var onboardingScene2: some View {
        VStack(spacing: 24) {
            VStack(spacing: 15) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.accent)
                    .neonGlow(color: Theme.Colors.accent, radius: 10)
                
                Text("Path of Swift")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Theme.Colors.accent)
            }
            
            Text("Modern. Expressive. Fast to learn.\nPerfect for building apps and mastering clean logic.\nRecommended if you're starting your journey.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
            
            Button(action: { gameManager.onboardingStep = 2 }) {
                Text("Next: Path of C")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
    }
    
    private var onboardingScene3: some View {
        VStack(spacing: 24) {
            VStack(spacing: 15) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .neonGlow(color: .blue, radius: 10)
                
                Text("Path of C")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            Text("Foundational. Precise. Powerful.\nUnderstand how code works at its core.\nGreat for building deep programming strength.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
            
            Button(action: { gameManager.onboardingStep = 3 }) {
                Text("Decision Clarifier")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
    }
    
    private var onboardingScene4: some View {
        VStack(spacing: 24) {
            Text("Your progress in each path is tracked separately.")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Text("You can switch paths anytime.\nThere are no wrong choices — only different journeys.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
            
            Button(action: { gameManager.completeOnboarding() }) {
                Text("Choose Your Path")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primaryGradient)
                    .cornerRadius(12)
            }
        }
    }
}

struct LevelListCard: View {
    let level: Level
    let isLocked: Bool
    let progress: Int
    let total: Int
    var isSpotlighted: Bool = false
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isLocked ? Color.gray.opacity(0.1) : (isSpotlighted ? Theme.Colors.accent.opacity(0.2) : Theme.Colors.accent.opacity(0.1)))
                    .frame(width: 50, height: 50)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                } else {
                    Text("\(level.number)")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.accent)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(level.title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(isLocked ? .gray : Theme.Colors.textPrimary)
                    
                    if isSpotlighted && !isLocked {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.accent)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(progress) / \(total) Completed")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            if !isLocked {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: isSpotlighted ? Theme.Colors.accent.opacity(0.3) : Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), 
                radius: isSpotlighted ? 15 : Theme.Layout.cardShadowRadius)
        .scaleEffect(isSpotlighted ? 1.02 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .stroke(Theme.Colors.accent.opacity(isSpotlighted ? 0.5 : 0), lineWidth: 2)
        )
        .opacity(isLocked ? 0.6 : 1.0)
        .animation(.spring(), value: isSpotlighted)
    }
}

// MARK: - Level Onboarding Overlay

struct LevelOnboardingOverlayView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                Spacer()
                
                if gameManager.levelOnboardingStep == 0 {
                    introScene
                } else {
                    progressionScene
                }
                Spacer()
            }
            .padding(horizontalSizeClass == .regular ? 60 : 40)
            .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var introScene: some View {
        VStack(spacing: 20) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.accent)
            
            Text("LEVEL PROGRESSION")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Text("Complete each level 100% to unlock the next rank in your journey.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: { 
                withAnimation { gameManager.levelOnboardingStep = 1 }
            }) {
                Text("View Ranks")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Theme.Colors.accent)
                    .cornerRadius(12)
            }
        }
    }
    
    private var progressionScene: some View {
        let step = gameManager.levelOnboardingStep
        let config = progressionConfig(for: step)
        
        return VStack(spacing: 25) {
            VStack(spacing: 15) {
                Image(systemName: config.icon)
                    .font(.largeTitle)
                    .foregroundColor(config.color)
                
                Text(config.rank)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                
                Text(config.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Text("Requires 100% completion of previous level.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(config.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(config.color.opacity(0.1))
                .cornerRadius(5)
            
            HStack(spacing: 15) {
                if step < 4 {
                    Button(action: { 
                        withAnimation { gameManager.levelOnboardingStep += 1 }
                    }) {
                        Text("Next Level")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: { 
                        withAnimation { gameManager.completeLevelOnboarding() }
                    }) {
                        Text("Start Journey")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Theme.Colors.accent)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .transition(.opacity)
    }
    
    private struct LevelConfig {
        let rank: String
        let icon: String
        let color: Color
        let description: String
    }
    
    private func progressionConfig(for step: Int) -> LevelConfig {
        switch step {
        case 1:
            return LevelConfig(rank: "BUG HUNTER", icon: "terminal", color: .green, 
                               description: "Master simple syntax and basic structure errors.")
        case 2:
            return LevelConfig(rank: "LOGIC BREAKER", icon: "arrow.triangle.merge", color: .blue, 
                               description: "Solve logic flow and data handling challenges.")
        case 3:
            return LevelConfig(rank: "CODE FIXER", icon: "magnifyingglass", color: .purple, 
                               description: "Hunt down multiple complex errors in one block.")
        default:
            return LevelConfig(rank: "DEBUG MASTER", icon: "crown", color: .red, 
                               description: "Optimize and fix high-level architectural bugs.")
        }
    }
}
