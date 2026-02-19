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
            
            // Tab 1: Reports (Dashboard)
            ReportView(result: gameManager.lastEvaluationResult, onDismiss: {
                gameManager.lastEvaluationResult = nil // Clear result on dismiss
            })
            .tabItem {
                Label("Reports", systemImage: "chart.bar.fill")
            }
            .tag(1)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.light, for: .tabBar)
            
            // Tab 2: Profile
            ProfileView(gameManager: gameManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
        }
        .environmentObject(gameManager)
        .accentColor(.blue) // Global Tint
    }
}
