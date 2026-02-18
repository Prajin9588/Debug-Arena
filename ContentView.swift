import SwiftUI

struct ContentView: View {
    @StateObject var gameManager = GameManager()
    @State private var selectedTab = 0 // Manage tab state
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Home (house)
            MainMenuView(selectedTab: $selectedTab)
                .environmentObject(gameManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
            
            // Tab 1: Reports
            if let result = gameManager.lastEvaluationResult {
                ReportView(result: result, onDismiss: {
                    // Optional: maybe clear result or just do nothing in tab mode
                })
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
            } else {
                // Empty State for Reports
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("No Reports Yet")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("Complete a coding challenge to see your detailed analysis here.")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
            }
            
            // Tab 2: Profile
            ProfileView(gameManager: gameManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
        }
        .accentColor(.blue) // Global Tint
    }
}
