import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .foregroundColor(Theme.Colors.accent)
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                        }
                        
                        Text("MISSION SELECT")
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .tracking(2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(gameManager.levels.indices, id: \.self) { index in
                            LevelNode(levelIndex: index)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

struct LevelNode: View {
    @EnvironmentObject var gameManager: GameManager
    let levelIndex: Int
    
    var level: Level {
        gameManager.levels[levelIndex]
    }
    
    var progress: Int {
        gameManager.levelProgress(for: levelIndex)
    }
    
    var progressPercent: Double {
        Double(progress) / 50.0
    }
    
    var body: some View {
        Group {
            if level.unlocked {
                NavigationLink(destination: QuestionDashboardView().onAppear { gameManager.selectLevel(levelIndex) }) {
                    nodeContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                nodeContent
            }
        }
    }
    
    private var nodeContent: some View {
        VStack(spacing: 15) {
            ZStack {
                CircularProgressRing(progress: progressPercent, color: ringColor, strokeWidth: 6)
                    .frame(width: 80, height: 80)
                
                if level.unlocked {
                    Text("\(level.number)")
                        .font(Theme.Typography.title.weight(.black))
                        .foregroundColor(Theme.Colors.textPrimary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .padding(10)
            .background(
                Circle()
                    .fill(Theme.Colors.secondaryBackground)
                    .shadow(color: level.unlocked ? Theme.Colors.accent.opacity(0.3) : .clear, radius: 10)
            )
            .overlay(
                Circle()
                    .stroke(level.unlocked ? Theme.Colors.accent.opacity(0.5) : .clear, lineWidth: 1)
            )
            
            VStack(spacing: 4) {
                Text(level.title.uppercased())
                    .font(Theme.Typography.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(level.unlocked ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .tracking(1)
                
                if level.unlocked {
                    Text("\(progress)/50 OK")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(progress == 50 ? Theme.Colors.success : Theme.Colors.accent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.Colors.secondaryBackground.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(level.unlocked ? Theme.Colors.accent.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .opacity(level.unlocked ? 1.0 : 0.6)
    }
    
    var ringColor: Color {
        if !level.unlocked { return Theme.Colors.textSecondary }
        if progress == 50 { return Theme.Colors.success }
        return Theme.Colors.accent
    }
}
