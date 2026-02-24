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
    
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        HStack(spacing: horizontalSizeClass == .compact ? 8 : 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryGradient)
                    .padding(10)
                    .background(Theme.Colors.babyPowder)
                    .clipShape(Circle())
                    .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
            }
            
            Spacer(minLength: 0)
            
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
            .background(Theme.Colors.babyPowder)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 8, x: 0, y: 4)
            
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
                
                HStack(spacing: 4) {
                    BugCoin(size: horizontalSizeClass == .compact ? 16 : 20)
                    Text("\(coins)")
                        .font(horizontalSizeClass == .compact ? Theme.Typography.caption : Theme.Typography.statsFont)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(.horizontal, horizontalSizeClass == .compact ? 10 : 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.babyPowder)
            .clipShape(Capsule())
            .shadow(color: Theme.Layout.cardShadow, radius: 5, x: 0, y: 2)
            .overlay(
                CoinScatterView(trigger: gameManager.scatterTrigger)
            )
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
struct CoinScatterView: View {
    let trigger: UUID
    @State private var coins: [CoinParticle] = []
    
    struct CoinParticle: Identifiable {
        let id = UUID()
        var offset: CGSize
        var opacity: Double
        var scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(coins) { coin in
                BugCoin(size: 16)
                    .scaleEffect(coin.scale)
                    .offset(coin.offset)
                    .opacity(coin.opacity)
            }
        }
        .onChange(of: trigger) { _, _ in
            spawnCoins()
        }
    }
    
    private func spawnCoins() {
        let newCoins = (0..<10).map { _ in
            CoinParticle(offset: .zero, opacity: 0, scale: 0.4)
        }
        self.coins = newCoins
        
        SoundManager.shared.playCoinScatter()
        
        for i in 0..<newCoins.count {
            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.2))) {
                coins[i].offset = CGSize(
                    width: CGFloat.random(in: -70...70),
                    height: CGFloat.random(in: 50...120)
                )
                coins[i].opacity = 1.0
                coins[i].scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.4)) {
                    if coins.indices.contains(i) {
                        coins[i].opacity = 0
                    }
                }
            }
        }
    }
}


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
                // Background Glow
                Circle()
                    .fill(RadialGradient(
                        colors: [.orange.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    ))
                    .frame(width: size * 2, height: size * 2)
                    .scaleEffect(0.8 + flicker * 0.2)
                
                // Outer Heat Layer (Red/Orange)
                flameLayer(color: .red, offset: -2, scale: 1.1, speed: 0.6)
                    .opacity(0.4)
                    .blur(radius: 2)
                
                // Mid Fire Layer (Orange)
                flameLayer(color: .orange, offset: -1, scale: 1.0, speed: 0.45)
                    .opacity(0.8)
                
                // Core Flame (Yellow/White)
                flameLayer(color: .yellow, offset: 0, scale: 0.8, speed: 0.3)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.white)
                            .scaleEffect(0.5 + flicker * 0.1)
                            .offset(y: size * 0.1)
                            .blur(radius: 1)
                    )
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
    
    private func flameLayer(color: Color, offset: CGFloat, scale: CGFloat, speed: Double) -> some View {
        Image(systemName: "flame.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * scale, height: size * scale)
            .foregroundStyle(color)
            .scaleEffect(x: 1.0 + (sway * 0.05), y: 1.0 + (flicker * 0.15), anchor: .bottom)
            .rotationEffect(.degrees(sway * 5), anchor: .bottom)
            .offset(x: sway * 2, y: offset + (lift * -3))
            .animation(.easeInOut(duration: speed).repeatForever(autoreverses: true), value: flicker)
            .animation(.easeInOut(duration: speed * 1.5).repeatForever(autoreverses: true), value: sway)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            flicker = 1.0
        }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            sway = 1.0
        }
        withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
            lift = 1.0
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
