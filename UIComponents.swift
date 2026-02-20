import SwiftUI

struct GlassBar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                BlurView(style: .systemThinMaterialDark)
                Color.white.opacity(0.15)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        self.modifier(NeonGlow(color: color, radius: radius))
    }
}

struct CircularProgressRing: View {
    let progress: Double // 0 to 1
    let color: Color
    var strokeWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: strokeWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

struct MissionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .tracking(2)
            
            content
        }
        .padding(25)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(LinearGradient(colors: [Theme.Colors.accent.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

struct BugCoin: View {
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Coin Base with Gradient
            Circle()
                .fill(LinearGradient(
                    colors: [Theme.Colors.gold, Color(hex: "FFD700")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .shadow(color: Theme.Colors.gold.opacity(0.3), radius: size * 0.1)
            
            // Inner Detailed Ring
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .frame(width: size * 0.85, height: size * 0.85)
            
            // Bug Symbol
            Image(systemName: "ladybug.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.55, height: size * 0.55)
                .foregroundColor(Theme.Colors.background.opacity(0.8))
        }
    }
}

// MARK: - Shared Workspace Header
struct WorkspaceHeader: View {
    let levelNumber: Int
    let questionNumber: Int
    let streak: Int
    let coins: Int
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryGradient)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            // Level Goal Pill
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.electricCyan)
                
                Text("LEVEL \(levelNumber) : Question \(questionNumber)")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 8, x: 0, y: 4)
            
            Spacer()
            
            // Stats Pill
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak)")
                        .font(Theme.Typography.statsFont)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                HStack(spacing: 4) {
                    BugCoin(size: 20)
                    Text("\(coins)")
                        .font(Theme.Typography.statsFont)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
        }
        .padding()
    }
}
