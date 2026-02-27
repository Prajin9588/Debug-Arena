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
                .toolbarColorScheme(gameManager.isDarkMode ? .dark : .light, for: .tabBar)
            
            // Tab 1: Reports (Analytics & Dashboard)
            ReportView()
            .tabItem {
                Label("Reports", systemImage: "chart.bar.fill")
            }
            .tag(1)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(gameManager.isDarkMode ? .dark : .light, for: .tabBar)
            
            // Tab 2: Profile
            ProfileView(gameManager: gameManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            .tag(2)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(gameManager.isDarkMode ? .dark : .light, for: .tabBar)
        }
        .environmentObject(gameManager)
        .accentColor(gameManager.isDarkMode ? Theme.Colors.electricCyan : .blue) // Global Tint
    }
}
