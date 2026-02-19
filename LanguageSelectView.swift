import SwiftUI

struct LanguageSelectView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToLevels = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 40) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(Theme.Colors.accent)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    
                    Text("ENVIRONMENT")
                        .font(Theme.Typography.title2)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .tracking(2)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Text("CHOOSE YOUR RUNTIME")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .tracking(4)

                LazyVGrid(columns: columns, spacing: 25) {
                    ForEach(Language.allCases) { language in
                        Button(action: {
                            gameManager.selectLanguage(language)
                            navigateToLevels = true
                        }) {
                            VStack(spacing: 20) {
                                Image(systemName: language.iconName)
                                    .font(.system(size: 45))
                                    .foregroundColor(Theme.Colors.accent)
                                    .neonGlow(color: Theme.Colors.accent, radius: 10)
                                
                                Text(language.rawValue.uppercased())
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .tracking(2)
                            }
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToLevels) {
            LevelSelectView()
        }
        .navigationBarHidden(true)
    }
}
