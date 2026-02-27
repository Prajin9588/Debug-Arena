import SwiftUI

struct Theme {
    // Global theme state
    static var isDarkMode: Bool = false
    static var selectedLanguage: Language = .python
    
    static var swiftAccent: Color {
        Theme.selectedLanguage == .swift ? Color(hex: "FF9100") : Color.orange
    }
    
    struct Colors {
        // Core Palette
        static let babyPowder = Color(hex: "FEFEFA")
        static let midnightIndigo = Color(hex: "0A0C10") // Refined Deep Indigo
        static let deepSlate = Color(hex: "161A22")      // Refined Slate surface
        static let slateWhite = Color(hex: "F8FAFC")
        static let coolGray = Color(hex: "94A3B8")
        
        static var background: Color {
            Theme.isDarkMode ? midnightIndigo : Color(hex: "F8F8F7")
        }
        
        static var secondaryBackground: Color {
            Theme.isDarkMode ? deepSlate : babyPowder
        }
        
        // Helper functions for explicit dependency tracking in views
        static func background(isDark: Bool) -> Color {
            return isDark ? midnightIndigo : Color(hex: "F8F8F7")
        }
        
        static func secondaryBackground(isDark: Bool) -> Color {
            return isDark ? deepSlate : babyPowder
        }
        
        static var codeBackground: Color {
            Theme.isDarkMode ? Color(hex: "0F1115") : Color(hex: "F3F4F6")
        }
        
        static func codeBackground(isDark: Bool) -> Color {
            return isDark ? Color(hex: "0F1115") : Color(hex: "F3F4F6")
        }
        
        static var terminalBackground: Color {
            Theme.isDarkMode ? Color(hex: "0A0B10") : Color(hex: "F2F2F7")
        }
        
        static var textPrimary: Color {
            Theme.isDarkMode ? slateWhite : Color(hex: "111827")
        }
        
        static func textPrimary(isDark: Bool) -> Color {
            return isDark ? slateWhite : Color(hex: "111827")
        }
        
        static var textSecondary: Color {
            Theme.isDarkMode ? coolGray : Color(hex: "64748B")
        }
        
        static func textSecondary(isDark: Bool) -> Color {
            return isDark ? coolGray : Color(hex: "64748B")
        }
        
        // Accents (Indigo / Cyan)
        static var accent: Color {
            if Theme.selectedLanguage == .swift {
                return Theme.swiftAccent
            }
            return Theme.isDarkMode ? Color(hex: "818CF8") : Color(hex: "5856D6")
        }
        
        static var electricCyan: Color {
            if Theme.selectedLanguage == .swift {
                return Theme.swiftAccent
            }
            return Theme.isDarkMode ? Color(hex: "38BDF8") : Color(hex: "007AFF")
        }
        
        static var action: Color {
            if Theme.selectedLanguage == .swift {
                return Theme.swiftAccent
            }
            return Theme.isDarkMode ? Color(hex: "38BDF8") : Color(hex: "007AFF")
        }
        
        // Status Colors
        static let success = Color(hex: "10B981") // Emerald 500
        static let error = Color(hex: "EF4444")   // Red 500
        static let warning = Color(hex: "F59E0B") // Amber 500
        static let gold = Color(hex: "FBBF24")    // Amber 400
        
        static let softGreen = Color(red: 0.1, green: 0.7, blue: 0.3)
        static let mutedRed = Color(red: 0.9, green: 0.3, blue: 0.3)
        
        // Gradients
        static var primaryGradient: LinearGradient {
            if Theme.selectedLanguage == .swift {
                return LinearGradient(
                    colors: [Color(hex: "E65100"), Color(hex: "FF9100"), Color(hex: "FFD600")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return Theme.isDarkMode ? 
                LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        static var failureGradient: LinearGradient {
            LinearGradient(
                colors: [Color(hex: "B71C1C"), Color(hex: "EF4444"), Color(hex: "FF5252")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        static var logoGradient: LinearGradient {
            LinearGradient(
                colors: [Color(hex: "4A7DFF"), Color(hex: "8B5CF6"), Color(hex: "C048FF")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    struct Typography {
        static let codeFont = Font.system(.body, design: .monospaced)
        static let terminalCodeFont = Font.system(.subheadline, design: .monospaced).weight(.medium)
        static let statsFont = Font.system(size: 15, weight: .medium)
        
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let subheadline = Font.system(size: 15, weight: .medium)
        static let body = Font.system(size: 17)
        static let caption = Font.system(size: 12, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .bold)
    }
    
    struct Layout {
        static let cornerRadius: CGFloat = 20
        static func cardShadow(isDark: Bool) -> Color {
            return isDark ? Color.black.opacity(0.5) : Color.black.opacity(0.06)
        }
        static var cardShadow: Color {
            Theme.isDarkMode ? Color.black.opacity(0.5) : Color.black.opacity(0.06)
        }
        static let cardShadowRadius: CGFloat = 12
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
