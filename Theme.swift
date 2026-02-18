import SwiftUI

struct Theme {
    struct Colors {
        // LIGHT MODE PALETTE
        static let background = Color(uiColor: .systemGroupedBackground) // Light Gray for visual hierarchy
        static let secondaryBackground = Color.white // Cards
        static let codeBackground = Color.white // Editor background
        static let terminalBackground = Color(hex: "F2F2F7") // Light Gray for Terminal/Console
        
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        
        // Accents
        static let accent = Color(hex: "5856D6") // Purple-Blue
        static let electricCyan = Color(hex: "007AFF") // Electric Blue (Primary Brand)
        static let action = Color(hex: "007AFF")
        
        // Status
        static let success = Color(hex: "34C759") // Soft Green
        static let error = Color(hex: "FF3B30") // Soft Red
        static let warning = Color(hex: "FF9500") // Orange
        static let gold = Color(hex: "FFCC00") // Gold
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    struct Typography {
        // SF Mono for Data / Code
        static let codeFont = Font.system(.body, design: .monospaced)
        static let terminalCodeFont = Font.system(.subheadline, design: .monospaced).weight(.medium)
        static let statsFont = Font.system(.callout, design: .monospaced).weight(.medium)
        
        // SF Pro (System) for Headers
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded) // Rounded for friendly feel
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 15, weight: .medium, design: .default)
        static let body = Font.system(size: 17, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let caption2 = Font.system(size: 11, weight: .bold, design: .default)
    }
    
    struct Layout {
        static let cornerRadius: CGFloat = 20
        static let cardShadow: Color = Color.black.opacity(0.05)
        static let cardShadowRadius: CGFloat = 10
        static let padding: CGFloat = 20
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
