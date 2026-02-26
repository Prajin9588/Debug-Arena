import SwiftUI


struct ReportView: View {
    @EnvironmentObject var gameManager: GameManager
    let result: EvaluationResult? // Made optional
    var onDismiss: (() -> Void)? = nil // Made optional
    
    // Computed props for display
    private var isPassed: Bool { result?.status == .correct }
    private var statusColor: Color { isPassed ? Theme.Colors.success : Theme.Colors.error }
    private var statusIcon: String { isPassed ? "checkmark.circle.fill" : "xmark.circle.fill" }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dimiss Indicator (Only if modal/result exists)
                if result != nil {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                } else {
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
                }
                
                // Evaluation Result Section
                if let res = result {
                    EvaluationResultView(result: res)
                }
                
                // NEW SECTIONS (Always visible)
                
                // 1. Progress Graph
                progressGraphSection
                
                // 2. Global Metrics
                globalMetricsSection
                
                // 3. Insights
                insightsSection
                
                // Action Button (Only if result exists)
                if let _ = result, let action = onDismiss {
                    Button(action: action) {
                        Text(isPassed ? "CONTINUE" : "TRY AGAIN")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPassed ? Theme.Colors.success : Theme.Colors.action)
                            .cornerRadius(Theme.Layout.cornerRadius)
                            .shadow(color: (isPassed ? Theme.Colors.success : Theme.Colors.action).opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Components
    
    
    // MARK: - New Enhanced Sections
    
    private var progressGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SKILL GROWTH")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: Theme.swiftAccent, label: "Swift")
                    LegendItem(color: .blue, label: "C Language")
                }
            }
            .padding(.horizontal, 4)
            
            // Dual Line Graph
            DualLineGraph(
                swiftData: extractHistory(for: "Swift"),
                cData: extractHistory(for: "C")
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
                    swiftValue: "\(getSolvedCount(for: "Swift"))",
                    cValue: "\(getSolvedCount(for: "C"))"
                )
                
                MetricCard(
                    title: "Avg Accuracy",
                    swiftValue: String(format: "%.0f%%", getAccuracy(for: "Swift")),
                    cValue: String(format: "%.0f%%", getAccuracy(for: "C"))
                )
            }
            
            HStack(spacing: 12) {
                 MetricSingleCard(
                    title: "Total XP Earned",
                    value: "\(gameManager.progressData["Swift"]?.totalXP ?? 0 + (gameManager.progressData["C"]?.totalXP ?? 0))",
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
                    Text(generateInsightTitle())
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(generateInsightBody())
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
    
    // MARK: - Helpers & Data Extraction
    
    private func extractHistory(for language: String) -> [Double] {
        guard let progress = gameManager.progressData[language] else { return [] }
        // Return mostly accuracy or XP. Prompt implies "Accuracy % or Score %"
        // Let's use accuracy history
        // If history is empty, return [0]
        if progress.history.isEmpty { return [0.0] }
        return progress.history.map { $0.accuracy }
    }
    
    private func getSolvedCount(for language: String) -> Int {
        return gameManager.progressData[language]?.completedQuestionIds.count ?? 0
    }
    
    private func getAccuracy(for language: String) -> Double {
        let hist = gameManager.progressData[language]?.history ?? []
        return hist.last?.accuracy ?? 0.0
    }
    
    private func generateInsightTitle() -> String {
        let swiftAcc = getAccuracy(for: "Swift")
        if swiftAcc > 80 { return "Swift Expert!" }
        if swiftAcc > 50 { return "Making Progress" }
        return "Keep Practicing"
    }
    
    private func generateInsightBody() -> String {
        let swiftAcc = getAccuracy(for: "Swift")
        if swiftAcc > 80 { return "Your Swift accuracy is impressive. Try tackling more advanced algorithms in Level 4." }
        if swiftAcc > 50 { return "You're getting better at Swift. Focus on understanding error messages to improve further." }
        return "Don't give up! Debugging is a skill that takes time. Review the hints and explanations carefully."
    }
    
}

// MARK: - Subcomponents

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
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Grid lines
                VStack {
                    Divider()
                    Spacer()
                    Divider()
                    Spacer()
                    Divider()
                }
                
                // C Line (Blue)
                Path { path in
                    drawPath(in: &path, data: cData, rect: proxy.frame(in: .local))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Swift Line (Custom)
                Path { path in
                    drawPath(in: &path, data: swiftData, rect: proxy.frame(in: .local))
                }
                .stroke(Theme.swiftAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Swift Fill
                Path { path in
                    drawPath(in: &path, data: swiftData, rect: proxy.frame(in: .local), closed: true)
                }
                .fill(LinearGradient(colors: [Theme.swiftAccent.opacity(0.2), Theme.swiftAccent.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                
                // Swift Markers
                if swiftData.count > 0 {
                    ForEach(0..<swiftData.count, id: \.self) { index in
                        let stepX = proxy.size.width / CGFloat(max(swiftData.count - 1, 1))
                        let x = CGFloat(index) * stepX
                        let y = proxy.size.height - (CGFloat(swiftData[index]) / 100.0 * proxy.size.height)
                        Circle()
                            .fill(Theme.swiftAccent)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
                
                // Dots for last points
                /* Optional dots */
            }
        }
        .padding(10)
    }
    
    private func drawPath(in path: inout Path, data: [Double], rect: CGRect, closed: Bool = false) {
        guard data.count > 0 else { return }
        
        let stepX = rect.width / CGFloat(max(data.count - 1, 1))
        let maxY = 100.0 // Accuracy is 0-100
        
        // Safe mapping
        let p0 = CGPoint(x: 0, y: rect.height - (CGFloat(data[0]) / maxY * rect.height))
        path.move(to: p0)
        
        for index in 1..<data.count {
            let val = data[index]
            let x = CGFloat(index) * stepX
            let y = rect.height - (CGFloat(val) / maxY * rect.height)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        if closed && data.count > 1 {
            path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: rect.height))
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
            Text(title)
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Swift")
                        .font(.caption2)
                        .foregroundColor(Theme.swiftAccent)
                    Text(swiftValue)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                Divider()
                Spacer()
                VStack(alignment: .leading) {
                    Text("C")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(cValue)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius)
        .frame(maxWidth: .infinity)
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
            HStack {
                icon
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding()
        .background(Theme.Colors.secondaryBackground(isDark: gameManager.isDarkMode))
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Layout.cardShadow(isDark: gameManager.isDarkMode), radius: Theme.Layout.cardShadowRadius)
        .frame(maxWidth: .infinity)
    }
}

