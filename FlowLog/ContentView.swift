import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingLogSheet = false

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(streak: appState.streak())
            TopTabBar(selectedTab: $selectedTab)
            Color.gutBorder.frame(height: 1)

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gutBg)

            BottomNavBar(selectedTab: $selectedTab)
        }
        .overlay(alignment: .bottom) {
            Button(action: { showingLogSheet = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.gutAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.gutAccent.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .padding(.bottom, 62)
        }
        .environmentObject(appState)
        .sheet(isPresented: $showingLogSheet) {
            LogEntrySheet(isPresented: $showingLogSheet)
                .environmentObject(appState)
                .presentationDetents([.large])
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:  TodayView()
        case 1:  HistoryView()
        default: InsightsView()
        }
    }
}

// MARK: - App Header

struct AppHeader: View {
    let streak: Int

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("Flow")
                        .font(.custom("Georgia", size: 26))
                    Text("Log")
                        .font(.custom("Georgia-Italic", size: 26))
                        .foregroundColor(.gutAccent)
                }
                Text(formattedDate())
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundColor(.gutMuted)
            }
            Spacer()
            Text("🔥 \(streak)-day streak")
                .font(.system(size: 11, design: .monospaced))
                .tracking(0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gutAccentLight)
                .foregroundColor(.gutAccent)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .background(Color.gutSurface)
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}

// MARK: - Top Tab Bar

struct TopTabBar: View {
    @Binding var selectedTab: Int
    private let tabs = ["Today", "History", "Insights"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button(action: { selectedTab = i }) {
                    VStack(spacing: 0) {
                        Text(tabs[i].uppercased())
                            .font(.system(size: 11, design: .monospaced))
                            .tracking(0.8)
                            .foregroundColor(selectedTab == i ? .gutText : .gutMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        Rectangle()
                            .fill(selectedTab == i ? Color.gutAccent : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
        .background(Color.gutSurface)
    }
}

// MARK: - Bottom Nav Bar

struct BottomNavBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            navItem(icon: "doc.text",            label: "Today",    index: 0)
            navItem(icon: "calendar",            label: "History",  index: 1)
            navItem(icon: "waveform.path.ecg",   label: "Insights", index: 2)
        }
        .padding(.bottom, 20)
        .padding(.top, 8)
        .background(Color.gutSurface)
        .overlay(alignment: .top) { Color.gutBorder.frame(height: 1) }
    }

    private func navItem(icon: String, label: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(0.6)
            }
            .foregroundColor(selectedTab == index ? .gutAccent : .gutMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}
