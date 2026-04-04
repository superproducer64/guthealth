import SwiftUI

struct TodayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HydrationCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("TODAY'S LOG")
                        .font(.system(size: 10, design: .monospaced))
                        .tracking(1.0)
                        .foregroundColor(.gutMuted)
                        .padding(.horizontal, 20)

                    let todayEntries = appState.todayEntries()
                    if todayEntries.isEmpty {
                        VStack(spacing: 12) {
                            Text("📋")
                                .font(.system(size: 40))
                            Text("No entries yet today.\nTap + to log a movement.")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gutMuted)
                                .multilineTextAlignment(.center)
                                .tracking(0.4)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 110)
        }
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: Entry
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                Text(icon)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 12, design: .monospaced))
                    .fontWeight(.medium)
                    .tracking(0.3)
                    .foregroundColor(.gutText)
                if !detailText.isEmpty {
                    Text(detailText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gutMuted)
                        .tracking(0.2)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(formatTime(entry.time))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gutMuted)

            Button(action: { appState.deleteEntry(id: entry.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(.gutMuted)
                    .padding(4)
            }
        }
        .padding(12)
        .background(Color.gutSurface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gutBorder, lineWidth: 1))
        .cornerRadius(8)
    }

    private var icon: String {
        entry.type == .urine ? "🚿" : (entry.bristolVisual ?? "🟤")
    }

    private var iconBg: Color {
        entry.type == .urine ? Color.gutWarnLight : Color.gutAccentLight
    }

    private var titleText: String {
        if entry.type == .urine {
            var s = "Urine — Level \(entry.color ?? 0)"
            if entry.urgency > 1 { s += " · \(urgencyEmojis[entry.urgency])" }
            return s
        } else {
            var s = "Bowel — Type \(entry.bristol ?? 0)"
            if entry.urgency > 1 { s += " · \(urgencyEmojis[entry.urgency])" }
            return s
        }
    }

    private var detailText: String {
        var parts: [String] = []
        if entry.type == .urine {
            if let label = entry.colorLabel { parts.append(label) }
        } else {
            if let name = entry.bristolName { parts.append(name) }
        }
        if entry.duration > 0 { parts.append("\(entry.duration)min") }
        if !entry.symptoms.isEmpty { parts.append(entry.symptoms.joined(separator: ", ")) }
        if !entry.notes.isEmpty { parts.append(entry.notes) }
        return parts.joined(separator: " · ")
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
