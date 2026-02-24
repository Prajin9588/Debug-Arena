import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var selectedTab: Int // Added binding for navigation
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background (Light Gray)
                Theme.Colors.background.ignoresSafeArea()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 0. App Title
                        Text("THE DEBUG ARENA")
                            .font(Theme.Typography.title)
                            .fontWeight(.black)
                            .foregroundStyle(Theme.Colors.primaryGradient)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        // 1. Professional Header
                        HomeHeader(
                            username: gameManager.username,
                            level: (gameManager.totalXP / 1000) + 1,
                            streak: gameManager.dailyStreak,
                            coins: gameManager.coinBalance,
                            selectedTab: $selectedTab
                        )
                        
                        // 2. Progress Overview Card
                        if gameManager.currentLevelIndex < gameManager.levels.count {
                             ProgressOverviewCard(
                                levelIndex: gameManager.currentLevelIndex,
                                completed: gameManager.levelProgress(for: gameManager.currentLevelIndex),
                                required: gameManager.questionsRequiredForNextLevel(levelIndex: gameManager.currentLevelIndex)
                            )
                        } else {
                            // All levels complete state could go here
                        }
                        
                        // 3. Language Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SELECT LANGUAGE")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .tracking(1)
                                .padding(.horizontal)
                            
                            let columns = horizontalSizeClass == .regular 
                                ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())] 
                                : [GridItem(.flexible()), GridItem(.flexible())]
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                // Swift (Master)
                                LanguageGridCard(
                                    language: "Swift",
                                    icon: "swift",
                                    tag: "MASTER",
                                    color: Theme.Colors.accent,
                                    action: { gameManager.selectLanguage(.swift) }
                                )
                                
                                // C (Foundation)
                                LanguageGridCard(
                                    language: "C",
                                    icon: "c.circle.fill", // SF Symbol
                                    tag: "FOUNDATION",
                                    color: .blue, // Placeholder for gradient, will be styled in card
                                    action: { gameManager.selectLanguage(.c) }
                                )
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                            .frame(maxWidth: .infinity)
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
                                            total: level.questions.count
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
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .preferredColorScheme(.light) // Force Light Mode
    }
}

// MARK: - Components

// MARK: - Components

struct HomeHeader: View {
    let username: String
    let level: Int
    let streak: Int
    let coins: Int
    @Binding var selectedTab: Int // NEW: Binding to switch tabs
    
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            // Left: Profile (Interactive)
            Button(action: {
                selectedTab = 2 // Switch to Profile Tab (Index 2)
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.babyPowder)
                            .frame(width: 44, height: 44)
                            .shadow(color: Theme.Layout.cardShadow, radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(username.uppercased())
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .tracking(0.5)
                        
                        Text("Level \(level)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle()) // Keep original look
            
            Spacer()
            
            // Right: Stats
            HStack(spacing: 12) {
                // Streak Capsule
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
                .background(Theme.Colors.babyPowder)
                .clipShape(Capsule())
                .shadow(color: Theme.Layout.cardShadow, radius: 4, x: 0, y: 2)
                
                // Coin Capsule
                HStack(spacing: 4) {
                    Image(systemName: "centsign.circle.fill") // Using standard symbol for now
                        .foregroundColor(Theme.Colors.gold)
                        .font(.caption)
                    Text("\(coins)")
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.babyPowder)
                .clipShape(Capsule())
                .shadow(color: Theme.Layout.cardShadow, radius: 4, x: 0, y: 2)
                .overlay(
                    CoinScatterView(trigger: gameManager.scatterTrigger)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear {
            if !gameManager.hasTriggeredLaunchAnimation {
                gameManager.triggerScatter()
                gameManager.hasTriggeredLaunchAnimation = true
            }
        }
    }
}

struct ProgressOverviewCard: View {
    let levelIndex: Int
    let completed: Int
    let required: Int
    
    var progress: Double {
        return required > 0 ? min(Double(completed) / Double(required), 1.0) : 0
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Theme.Colors.background, lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.Colors.electricCyan,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                
                if completed >= required && required > 0 {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.electricCyan)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Progress Overview")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if required > 0 {
                    Text("\(completed) / \(required) to unlock Level \(levelIndex + 2)")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                } else {
                    Text("Max Level Reached")
                         .font(Theme.Typography.subheadline)
                         .foregroundColor(Theme.Colors.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "trophy")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.electricCyan)
                    Text("Keep debugging!")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.electricCyan)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Theme.Colors.babyPowder)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        .padding(.horizontal)
    }
}

struct LanguageGridCard: View {
    let language: String
    let icon: String // SF Symbol name
    let tag: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(language)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .padding(16)
            .background(Theme.Colors.babyPowder)
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        }
    }
}

struct LevelListCard: View {
    let level: Level
    let isLocked: Bool
    let progress: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon / Number
            ZStack {
                Circle()
                    .fill(isLocked ? Color.gray.opacity(0.1) : Theme.Colors.accent.opacity(0.1))
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
                Text(level.title)
                    .font(Theme.Typography.headline)
                    .foregroundColor(isLocked ? .gray : Theme.Colors.textPrimary)
                
                if isLocked {
                    Text("Unlock after previous level")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("\(progress) / \(total) Completed")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if !isLocked {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(Theme.Colors.babyPowder)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow, radius: Theme.Layout.cardShadowRadius)
        .opacity(isLocked ? 0.6 : 1.0)
    }
}
