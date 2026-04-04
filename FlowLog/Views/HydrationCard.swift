import SwiftUI

struct HydrationCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            // Title
            HStack {
                Text("💧")
                    .font(.system(size: 20))
                Text("Hydration")
                    .font(.custom("Georgia", size: 18))
                Spacer()
            }

            // Count + progress
            VStack(spacing: 6) {
                Text("\(appState.waterToday())")
                    .font(.custom("Georgia", size: 52))
                    .foregroundColor(.gutBlue)
                    .lineLimit(1)

                Text("GLASSES TODAY")
                    .font(.system(size: 12, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(.gutMuted)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gutBorder)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gutBlue)
                            .frame(
                                width: geo.size.width * CGFloat(min(1.0, Double(appState.waterToday()) / Double(AppState.waterGoal))),
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.3), value: appState.waterToday())
                    }
                }
                .frame(height: 4)

                Text(waterGoalText)
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(.gutMuted)
            }

            // Glasses grid
            let water = appState.waterToday()
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: AppState.waterGoal),
                spacing: 6
            ) {
                ForEach(0..<AppState.waterGoal, id: \.self) { i in
                    Button(action: {
                        let newCount = i + 1 > water ? i + 1 : i
                        appState.setWater(newCount)
                    }) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i < water ? Color.gutBlueLight : Color.gutSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(i < water ? Color.gutBlue : Color.gutBorder, lineWidth: 2)
                            )
                            .overlay(
                                Text(i < water ? "💧" : "")
                                    .font(.system(size: 14))
                            )
                            .aspectRatio(0.82, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: water)
                }
            }

            // Buttons
            HStack(spacing: 8) {
                Button(action: { appState.addWater(delta: -1) }) {
                    Text("− Remove")
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundColor(.gutText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.gutSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gutBorder, lineWidth: 1.5))
                        .cornerRadius(8)
                }
                Button(action: { appState.addWater(delta: 1) }) {
                    Text("+ Add Glass")
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.gutAccent)
                        .cornerRadius(8)
                }
            }
        }
        .padding(18)
        .background(Color.gutSurface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gutBorder, lineWidth: 1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    private var waterGoalText: String {
        let water = appState.waterToday()
        let msgs = ["Start hydrating!", "Keep going!", "Good progress!", "Halfway there!",
                    "Almost there!", "Great job!", "Nearly full!", "Goal reached! 🎉", "Above and beyond!"]
        return "\(water) / \(AppState.waterGoal) glasses — \(msgs[min(water, msgs.count - 1)])"
    }
}
