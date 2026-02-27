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


// MARK: - Shared Workspace Header
struct WorkspaceHeader: View {
    let levelNumber: Int
    let questionNumber: Int
    let streak: Int
    let onBack: () -> Void
    
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    
    var body: some View {
        HStack(spacing: horizontalSizeClass == .compact ? 8 : 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryGradient)
                    .padding(10)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(Circle())
                    .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
            }
            
            Spacer(minLength: 0)
            
            VStack(spacing: 2) {
                // Level Goal Pill
                HStack(spacing: horizontalSizeClass == .compact ? 6 : 12) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.electricCyan)
                    
                    Text(horizontalSizeClass == .compact ? "L\(levelNumber) : Q\(questionNumber)" : "LEVEL \(levelNumber) : Question \(questionNumber)")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 12 : 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(Capsule())
                .shadow(color: Theme.Layout.cardShadow, radius: 8, x: 0, y: 4)
            }
            
            Spacer(minLength: 0)
            
            // Stats Pill
            HStack(spacing: horizontalSizeClass == .compact ? 8 : 16) {
                HStack(spacing: 4) {
                    StreakFireView(streak: streak)
                        .font(horizontalSizeClass == .compact ? .caption : .body)
                    Text("\(streak)")
                        .font(horizontalSizeClass == .compact ? Theme.Typography.caption : Theme.Typography.statsFont)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(.horizontal, horizontalSizeClass == .compact ? 10 : 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Entrance Animation
struct EntranceAnimation: ViewModifier {
    let delay: Double
    let isVisible: Bool
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 35)
                .animation(.easeOut(duration: 0.6).delay(delay), value: isVisible)
        } else {
            content
        }
    }
}

extension View {
    func entranceAnimation(delay: Double, isVisible: Bool, isEnabled: Bool) -> some View {
        self.modifier(EntranceAnimation(delay: delay, isVisible: isVisible, isEnabled: isEnabled))
    }
}

// MARK: - Decorative Animations


struct MovingFlameStreakIcon: View {
    let size: CGFloat
    let isActive: Bool
    
    @State private var flicker: Double = 0.0
    @State private var sway: Double = 0.0
    @State private var lift: Double = 0.0
    
    private var flameColor: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow, .white],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    var body: some View {
        ZStack {
            if isActive {
                // Soft Ambient Glow
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    ))
                    .frame(width: size * 2, height: size * 2)
                    .scaleEffect(0.9 + flicker * 0.1)
                
                // Main Flame Body
                Image(systemName: "flame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B00"), .orange, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(x: 1.0 + (sway * 0.03), y: 1.0 + (flicker * 0.08), anchor: .bottom)
                    .rotationEffect(.degrees(sway * 2), anchor: .bottom)
                
                // Subtle Soft Core
                Image(systemName: "flame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.4, height: size * 0.4)
                    .foregroundStyle(.white.opacity(0.8))
                    .blur(radius: 0.5)
                    .offset(y: size * 0.15)
            } else {
                Image(systemName: "flame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            flicker = 1.0
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            sway = 1.0
        }
    }
}

struct StreakFireView: View {
    let streak: Int
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        MovingFlameStreakIcon(
            size: horizontalSizeClass == .compact ? 16 : 22,
            isActive: streak > 0
        )
    }
}

struct CLogoView: View {
    var size: CGFloat = 28
    
    var body: some View {
        ZStack {
            HexagonShape()
                .fill(LinearGradient(
                    colors: [Color(hex: "5685BB"), Color(hex: "2D558E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Shading triangle on the right
            HexagonRightShading()
                .fill(Color(hex: "1B355B"))
            
            Text("C")
                .font(.system(size: size * 0.65, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .offset(x: -size * 0.05)
        }
        .frame(width: size, height: size)
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let x = rect.midX
        let y = rect.midY
        let side = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let pt = CGPoint(x: x + side * cos(angle), y: y + side * sin(angle))
            if i == 0 { path.move(to: pt) }
            else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct HexagonRightShading: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let x = rect.midX
        let y = rect.midY
        let side = min(rect.width, rect.height) / 2
        
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + side * cos(0), y: y + side * sin(0)))
        path.addLine(to: CGPoint(x: x + side * cos(.pi/3), y: y + side * sin(.pi/3)))
        path.closeSubpath()
        
        // Add the top triangle too
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + side * cos(0), y: y + side * sin(0)))
        path.addLine(to: CGPoint(x: x + side * cos(-.pi/3), y: y + side * sin(-.pi/3)))
        path.closeSubpath()
        
        return path
    }
}
