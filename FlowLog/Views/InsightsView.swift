import SwiftUI

// MARK: - Insights Model

struct InsightItem: Identifiable {
    enum Style { case good, warn, info }
    let id = UUID()
    let style: Style
    let icon: String
    let title: String
    let text: String
}

// MARK: - Insights View

struct InsightsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Health Insights card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("🔬").font(.system(size: 20))
                        Text("Health Insights").font(.custom("Georgia", size: 18))
                        Spacer()
                    }
                    ForEach(insights) { item in
                        InsightCard(item: item)
                    }
                }
                .padding(18)
                .background(Color.gutSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gutBorder, lineWidth: 1))
                .cornerRadius(12)
                .padding(.horizontal, 20)

                // Bristol Reference card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("📊").font(.system(size: 20))
                        Text("Bristol Scale Reference").font(.custom("Georgia", size: 18))
                        Spacer()
                    }
                    ForEach(bristolData) { b in
                        BristolRefRow(type: b)
                    }
                }
                .padding(18)
                .background(Color.gutSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gutBorder, lineWidth: 1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 110)
        }
    }

    // MARK: - Computed Insights

    private var insights: [InsightItem] {
        var items: [InsightItem] = []
        let water = appState.waterToday()

        // Hydration insight
        if water >= AppState.waterGoal {
            items.append(InsightItem(style: .good, icon: "💧",
                title: "Hydration goal reached!",
                text: "You've had \(water) glasses today — excellent hydration."))
        } else if water >= 4 {
            items.append(InsightItem(style: .info, icon: "💧",
                title: "Halfway to hydration goal",
                text: "\(water) of \(AppState.waterGoal) glasses today. Try to drink \(AppState.waterGoal - water) more."))
        } else {
            items.append(InsightItem(style: .warn, icon: "⚠️",
                title: "Low hydration today",
                text: "Only \(water) glasses so far. Aim for at least \(AppState.waterGoal) glasses daily."))
        }

        // Bowel insight
        let recentBowel = Array(appState.entries.filter { $0.type == .bowel }.prefix(5))
        if recentBowel.isEmpty {
            items.append(InsightItem(style: .info, icon: "📋",
                title: "No bowel data yet",
                text: "Start logging bowel movements to get personalized health insights."))
        } else {
            let types = recentBowel.compactMap { $0.bristol }
            let healthyCount = types.filter { $0 == 3 || $0 == 4 }.count
            if healthyCount == types.count {
                items.append(InsightItem(style: .good, icon: "✅",
                    title: "Healthy bowel pattern",
                    text: "Your recent bowel movements are Types 3–4 — the ideal range on the Bristol Scale."))
            } else if types.contains(where: { $0 <= 2 }) {
                items.append(InsightItem(style: .warn, icon: "🌾",
                    title: "Signs of constipation",
                    text: "Recent Type 1–2 stools suggest you may be constipated. Increase fiber and water intake."))
            } else if types.contains(where: { $0 >= 6 }) {
                items.append(InsightItem(style: .warn, icon: "⚡",
                    title: "Loose stools detected",
                    text: "Type 6–7 stools may indicate diarrhea. Stay hydrated and consider dietary adjustments."))
            }
        }

        // Urine insight
        let recentUrine = Array(appState.entries.filter { $0.type == .urine }.prefix(5))
        if !recentUrine.isEmpty {
            let colors = recentUrine.compactMap { $0.color }
            if !colors.isEmpty {
                let avg = Double(colors.reduce(0, +)) / Double(colors.count)
                if avg <= 3 {
                    items.append(InsightItem(style: .good, icon: "🟡",
                        title: "Well hydrated based on urine",
                        text: "Your recent urine color suggests good hydration levels."))
                } else if avg >= 5 {
                    items.append(InsightItem(style: .warn, icon: "🟠",
                        title: "Dark urine — drink water",
                        text: "Your urine color suggests dehydration. Increase water intake throughout the day."))
                }
            }
        }

        items.append(InsightItem(style: .info, icon: "🩺",
            title: "Disclaimer",
            text: "FlowLog is a personal tracking tool. Consult a healthcare provider for medical concerns."))

        return items
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let item: InsightItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.icon)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 11, design: .monospaced))
                    .fontWeight(.semibold)
                    .tracking(0.2)
                    .foregroundColor(.gutText)
                Text(item.text)
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(0.2)
                    .foregroundColor(.gutText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(bgColor)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
        .cornerRadius(10)
    }

    private var bgColor: Color {
        switch item.style {
        case .good: return Color.gutAccentLight
        case .warn: return Color.gutWarnLight
        case .info: return Color.gutBlueLight
        }
    }

    private var borderColor: Color {
        switch item.style {
        case .good: return Color(hex: "#b2d8c8")
        case .warn: return Color(hex: "#e8c8a0")
        case .info: return Color(hex: "#a8ccec")
        }
    }
}

// MARK: - Bristol Reference Row

struct BristolRefRow: View {
    let type: BristolType

    var body: some View {
        HStack(spacing: 12) {
            Text("\(type.n)")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(.gutAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(type.name)
                        .font(.system(size: 12, design: .monospaced))
                        .fontWeight(.medium)
                        .tracking(0.3)
                        .foregroundColor(.gutText)
                    if type.healthy {
                        Text("✓")
                            .font(.system(size: 10))
                            .foregroundColor(.gutAccent)
                    }
                }
                Text(type.desc)
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(0.2)
                    .foregroundColor(.gutMuted)
            }
            Spacer()
            Text(type.visual)
                .font(.system(size: 20))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(type.healthy ? Color.gutAccentLight : Color.clear)
        .cornerRadius(8)
    }
}
