import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var weekOffset = 0

    private var weekDates: [Date] { appState.weekDates(offset: weekOffset) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Week navigation
                HStack {
                    Button(action: { weekOffset -= 1 }) {
                        Image(systemName: "chevron.left")
                            .frame(width: 34, height: 34)
                            .background(Color.gutSurface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gutBorder, lineWidth: 1.5))
                            .cornerRadius(8)
                    }
                    .foregroundColor(.gutText)

                    Spacer()

                    Text(weekLabel)
                        .font(.system(size: 12, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.gutMuted)

                    Spacer()

                    Button(action: {
                        if weekOffset < 0 { weekOffset += 1 }
                    }) {
                        Image(systemName: "chevron.right")
                            .frame(width: 34, height: 34)
                            .background(Color.gutSurface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gutBorder, lineWidth: 1.5))
                            .cornerRadius(8)
                    }
                    .foregroundColor(weekOffset < 0 ? .gutText : .gutMuted)
                    .disabled(weekOffset >= 0)
                }
                .padding(.horizontal, 20)

                // Mini calendar
                VStack(spacing: 4) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                        spacing: 4
                    ) {
                        ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                            Text(d)
                                .font(.system(size: 9, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(.gutMuted)
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(weekDates.indices, id: \.self) { i in
                            CalendarDayCell(
                                date: weekDates[i],
                                isToday: appState.dateKey(weekDates[i]) == appState.todayKey(),
                                hasWater: (appState.waterByDay[appState.dateKey(weekDates[i])] ?? 0) > 0,
                                hasUrine: appState.entriesForDate(appState.dateKey(weekDates[i])).contains { $0.type == .urine },
                                hasBowel: appState.entriesForDate(appState.dateKey(weekDates[i])).contains { $0.type == .bowel }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Bar chart + legend
                VStack(alignment: .leading, spacing: 12) {
                    Text("WEEKLY ACTIVITY")
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.gutMuted)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(weekDates.indices, id: \.self) { i in
                            barGroup(for: weekDates[i])
                        }
                    }
                    .frame(height: 80)

                    HStack(spacing: 12) {
                        legendDot(color: .gutBlue,   label: "Water")
                        legendDot(color: .gutWarn,   label: "Urine")
                        legendDot(color: .gutAccent, label: "Bowel")
                    }
                }
                .padding(18)
                .background(Color.gutSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gutBorder, lineWidth: 1))
                .cornerRadius(12)
                .padding(.horizontal, 20)

                // Stats row
                HStack(spacing: 8) {
                    statBox(value: avgWater, label: "Avg Glasses")
                    statBox(value: "\(totalUrine)", label: "Urine Events")
                    statBox(value: "\(totalBowel)", label: "Bowel Events")
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 110)
        }
    }

    // MARK: - Bar Group

    private func barGroup(for date: Date) -> some View {
        let key = appState.dateKey(date)
        let water = Double(appState.waterByDay[key] ?? 0)
        let urine = Double(appState.entriesForDate(key).filter { $0.type == .urine }.count)
        let bowel = Double(appState.entriesForDate(key).filter { $0.type == .bowel }.count)
        let maxW = max(Double(AppState.waterGoal), water)
        let maxU = max(4, urine)
        let maxB = max(4, bowel)
        let dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let dayIdx = (weekday + 5) % 7

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 2) {
                bar(ratio: water / maxW, color: .gutBlue)
                bar(ratio: urine / maxU, color: .gutWarn)
                bar(ratio: bowel / maxB, color: .gutAccent)
            }
            Text(dayNames[dayIdx])
                .font(.system(size: 9, design: .monospaced))
                .tracking(0.3)
                .foregroundColor(.gutMuted)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func bar(ratio: Double, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 8, height: max(2, CGFloat(min(1, ratio) * 60)))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .tracking(0.2)
                .foregroundColor(.gutMuted)
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 28))
                .foregroundColor(.gutText)
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .tracking(0.7)
                .foregroundColor(.gutMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gutSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gutBorder, lineWidth: 1))
        .cornerRadius(10)
    }

    // MARK: - Computed Stats

    private var weekLabel: String {
        guard !weekDates.isEmpty else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: weekDates.first!)) – \(f.string(from: weekDates.last!))"
    }

    private var avgWater: String {
        let vals = weekDates.map { appState.waterByDay[appState.dateKey($0)] ?? 0 }
        let avg = Double(vals.reduce(0, +)) / 7.0
        return String(format: "%.1f", avg)
    }

    private var totalUrine: Int {
        weekDates.reduce(0) { $0 + appState.entriesForDate(appState.dateKey($1)).filter { $0.type == .urine }.count }
    }

    private var totalBowel: Int {
        weekDates.reduce(0) { $0 + appState.entriesForDate(appState.dateKey($1)).filter { $0.type == .bowel }.count }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let hasWater: Bool
    let hasUrine: Bool
    let hasBowel: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isToday ? .white : .gutText)
            HStack(spacing: 2) {
                if hasWater { dot(color: .gutBlue) }
                if hasUrine { dot(color: .gutWarn) }
                if hasBowel { dot(color: .gutAccent) }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(isToday ? Color.gutAccent : Color.gutSurface)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isToday ? Color.gutAccent : Color.gutBorder, lineWidth: 1.5))
        .cornerRadius(6)
    }

    private func dot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 4, height: 4)
    }
}
