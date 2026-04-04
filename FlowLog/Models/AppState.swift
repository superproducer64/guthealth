import Foundation
import Combine

class AppState: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var waterByDay: [String: Int] = [:]

    static let waterGoal = 8
    private let storageKey = "flowlog_v2_data"

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        loadData()
        if entries.isEmpty { seedDemo() }
    }

    // MARK: - Date Keys

    func todayKey() -> String { dateFmt.string(from: Date()) }
    func dateKey(_ d: Date) -> String { dateFmt.string(from: d) }

    // MARK: - Hydration

    func waterToday() -> Int { waterByDay[todayKey()] ?? 0 }

    func addWater(delta: Int) {
        let key = todayKey()
        waterByDay[key] = max(0, min(12, (waterByDay[key] ?? 0) + delta))
        saveData()
    }

    func setWater(_ count: Int) {
        waterByDay[todayKey()] = max(0, min(12, count))
        saveData()
    }

    // MARK: - Entries

    func todayEntries() -> [Entry] {
        entries.filter { $0.date == todayKey() }
    }

    func entriesForDate(_ key: String) -> [Entry] {
        entries.filter { $0.date == key }
    }

    func submitEntry(_ entry: Entry) {
        entries.insert(entry, at: 0)
        saveData()
    }

    func deleteEntry(id: Int64) {
        entries.removeAll { $0.id == id }
        saveData()
    }

    // MARK: - Streak

    func streak() -> Int {
        let today = Date()
        var count = 0
        for i in 0..<365 {
            guard let d = Calendar.current.date(byAdding: .day, value: -i, to: today) else { break }
            let key = dateKey(d)
            if entries.contains(where: { $0.date == key }) || (waterByDay[key] ?? 0) > 0 {
                count += 1
            } else {
                break
            }
        }
        return max(1, count)
    }

    // MARK: - Week Helpers

    func weekDates(offset: Int = 0) -> [Date] {
        let cal = Calendar.current
        let today = Date()
        // Weekday: 1=Sun, 2=Mon … adjust so week starts Monday
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday + offset * 7, to: today) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    // MARK: - Persistence

    private struct StorageData: Codable {
        var entries: [Entry]
        var waterByDay: [String: Int]
    }

    func saveData() {
        if let data = try? JSONEncoder().encode(StorageData(entries: entries, waterByDay: waterByDay)) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(StorageData.self, from: data)
        else { return }
        entries = decoded.entries
        waterByDay = decoded.waterByDay
    }

    // MARK: - Demo Seed

    private func seedDemo() {
        let cal = Calendar.current
        let today = Date()
        for i in stride(from: 6, through: 0, by: -1) {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let key = dateKey(d)
            waterByDay[key] = Int.random(in: 4...8)

            let urineCount = Int.random(in: 2...4)
            for u in 0..<urineCount {
                var c = cal.dateComponents([.year, .month, .day], from: d)
                c.hour = 7 + u * 3
                c.minute = Int.random(in: 0...59)
                guard let t = cal.date(from: c) else { continue }
                let colorIdx = Int.random(in: 1...4)
                let ud = urineColorData[colorIdx - 1]
                entries.append(Entry(
                    id: Int64(t.timeIntervalSince1970 * 1000) + Int64(u),
                    type: .urine, date: key, time: t,
                    color: colorIdx, colorLabel: ud.label, colorHex: ud.hexColor,
                    bristol: nil, bristolName: nil, bristolVisual: nil, healthy: nil,
                    urgency: 1, duration: 1, symptoms: [], notes: ""
                ))
            }

            if i % 2 == 0 {
                var c = cal.dateComponents([.year, .month, .day], from: d)
                c.hour = 8; c.minute = 30
                guard let t = cal.date(from: c) else { continue }
                let bristol = Bool.random() ? Int.random(in: 3...4) : Int.random(in: 1...7)
                let bd = bristolData[bristol - 1]
                entries.append(Entry(
                    id: Int64(t.timeIntervalSince1970 * 1000),
                    type: .bowel, date: key, time: t,
                    color: nil, colorLabel: nil, colorHex: nil,
                    bristol: bristol, bristolName: bd.name, bristolVisual: bd.visual, healthy: bd.healthy,
                    urgency: 1, duration: 5, symptoms: [], notes: ""
                ))
            }
        }
        entries.sort { $0.time > $1.time }
        saveData()
    }
}
