import SwiftUI

struct ReportView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dashboard Header
                HStack {
                    Text("PROGRESS REPORT")
                        .font(Theme.Typography.title)
                        .fontWeight(.black)
                        .foregroundStyle(Theme.Colors.primaryGradient)
                        .tracking(2)
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal, 4)
                
                // Analytics Sections
                progressGraphSection
                globalMetricsSection
                insightsSection
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Analytics Components
    
    private var progressGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SKILL GROWTH")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                HStack(spacing: 12) {
                    LegendItem(color: Theme.swiftAccent, label: "Swift")
                    LegendItem(color: .blue, label: "C Language")
                }
            }
            .padding(.horizontal, 4)
            
            DualLineGraph(
                swiftData: gameManager.getLanguageHistory(for: "Swift"),
                cData: gameManager.getLanguageHistory(for: "C")
            )
            .frame(height: 180)
            .padding()
            .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius)
        }
    }
    
    private var globalMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERFORMANCE METRICS")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                MetricCard(
                    title: "Total Solved",
                    swiftValue: "\(gameManager.getLanguageSolvedCount(for: "Swift"))",
                    cValue: "\(gameManager.getLanguageSolvedCount(for: "C"))"
                )
                
                MetricCard(
                    title: "Avg Accuracy",
                    swiftValue: String(format: "%.0f%%", gameManager.getLanguageAccuracy(for: "Swift")),
                    cValue: String(format: "%.0f%%", gameManager.getLanguageAccuracy(for: "C"))
                )
            }
            
            HStack(spacing: 12) {
                 MetricSingleCard(
                    title: "Total XP Earned",
                    value: "\(gameManager.getLanguageXP(for: "Swift") + gameManager.getLanguageXP(for: "C"))",
                    icon: AnyView(Image(systemName: "star.fill")),
                    color: .yellow
                 )
                 
                 MetricSingleCard(
                    title: "Current Streak",
                    value: "\(gameManager.currentStreak) Days",
                    icon: AnyView(StreakFireView(streak: gameManager.currentStreak)),
                    color: Theme.swiftAccent
                 )
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
             Text("AI INSIGHTS")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, 4)
            
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.gold)
                    .padding(10)
                    .background(Theme.Colors.gold.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    let swiftAcc = gameManager.getLanguageAccuracy(for: "Swift")
                    Text(swiftAcc > 80 ? "Swift Expert!" : (swiftAcc > 50 ? "Making Progress" : "Keep Practicing"))
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(swiftAcc > 80 ? "Your Swift accuracy is impressive. Try tackling more advanced algorithms in Level 4." : (swiftAcc > 50 ? "You're getting better at Swift. Focus on understanding error messages to improve further." : "Don't give up! Debugging is a skill that takes time. Review the hints and explanations carefully."))
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
            .cornerRadius(Theme.Layout.cornerRadius)
            .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(Theme.Typography.caption).foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

struct DualLineGraph: View {
    let swiftData: [Double]
    let cData: [Double]
    private let gridFractions: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                ForEach(gridFractions.reversed(), id: \.self) { fraction in
                    Text("\(Int(fraction * 100))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                    if fraction > 0 { Spacer() }
                }
            }
            .frame(width: 35)
            .padding(.vertical, 2)
            
            GeometryReader { proxy in
                ZStack {
                    VStack(spacing: 0) {
                        ForEach(gridFractions, id: \.self) { fraction in
                            Rectangle().fill(Theme.Colors.textSecondary.opacity(0.1)).frame(height: 1)
                            if fraction != gridFractions.last { Spacer() }
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Rectangle().fill(Theme.Colors.textSecondary.opacity(0.05)).frame(width: 1)
                            Spacer()
                        }
                    }
                    chartLine(data: cData, color: Color.blue, rect: proxy.size, showFill: false)
                    chartLine(data: swiftData, color: Theme.swiftAccent, rect: proxy.size, showFill: true)
                }
            }
        }
    }
    
    @ViewBuilder
    private func chartLine(data: [Double], color: Color, rect: CGSize, showFill: Bool) -> some View {
        let count = data.count
        if count > 0 {
            Group {
                if showFill {
                    Path { path in drawPath(in: &path, data: data, rect: rect, closed: true) }
                    .fill(LinearGradient(colors: [color.opacity(0.25), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                }
                Path { path in drawPath(in: &path, data: data, rect: rect) }
                .stroke(color, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 3)
            }
        }
    }
    
    private func getX(index: Int, count: Int, width: CGFloat) -> CGFloat {
        guard count > 1 else { return width }
        return CGFloat(index) * (width / CGFloat(count - 1))
    }
    
    private func getY(value: Double, height: CGFloat) -> CGFloat {
        let normalizedValue = min(max(value, 0), 100.0)
        return height - (CGFloat(normalizedValue) / 100.0 * height)
    }
    
    private func drawPath(in path: inout Path, data: [Double], rect: CGSize, closed: Bool = false) {
        let count = data.count
        guard count > 0 else { return }
        let p0 = CGPoint(x: getX(index: 0, count: count, width: rect.width), y: getY(value: data[0], height: rect.height))
        path.move(to: p0)
        if count == 1 {
            path.addLine(to: CGPoint(x: rect.width, y: p0.y))
        } else {
            for index in 1..<count {
                path.addLine(to: CGPoint(x: getX(index: index, count: count, width: rect.width), y: getY(value: data[index], height: rect.height)))
            }
        }
        if closed {
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
    }
}

struct MetricCard: View {
    @EnvironmentObject var gameManager: GameManager
    let title: String
    let swiftValue: String
    let cValue: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Theme.Typography.caption2).foregroundColor(Theme.Colors.textSecondary)
            HStack {
                VStack(alignment: .leading) {
                    Text("Swift").font(.caption2).foregroundColor(Theme.swiftAccent)
                    Text(swiftValue).font(.headline).fontWeight(.bold)
                }
                Spacer(); Divider(); Spacer()
                VStack(alignment: .leading) {
                    Text("C").font(.caption2).foregroundColor(.blue)
                    Text(cValue).font(.headline).fontWeight(.bold)
                }
            }
        }
        .padding().background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode)).cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius).frame(maxWidth: .infinity)
    }
}

struct MetricSingleCard: View {
    @EnvironmentObject var gameManager: GameManager
    let title: String
    let value: String
    let icon: AnyView
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { icon.foregroundColor(color); Text(title).font(Theme.Typography.caption2).foregroundColor(Theme.Colors.textSecondary) }
            Text(value).font(.headline).fontWeight(.bold).foregroundColor(Theme.Colors.textPrimary)
        }
        .padding().background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode)).cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius).frame(maxWidth: .infinity)
    }
}
