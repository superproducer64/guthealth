import SwiftUI

// MARK: - Color Theme

extension Color {
    static let gutBg          = Color(hex: "#F5F3EF")
    static let gutSurface     = Color(hex: "#FFFFFF")
    static let gutSurface2    = Color(hex: "#EEF0F2")
    static let gutBorder      = Color(hex: "#E0DDD8")
    static let gutText        = Color(hex: "#1A1A18")
    static let gutMuted       = Color(hex: "#7A7871")
    static let gutAccent      = Color(hex: "#2D6A4F")
    static let gutAccentLight = Color(hex: "#D8EDE4")
    static let gutWarn        = Color(hex: "#C77B3A")
    static let gutWarnLight   = Color(hex: "#FAEBD7")
    static let gutBlue        = Color(hex: "#2C5F8A")
    static let gutBlueLight   = Color(hex: "#D6E8F5")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:  (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - Bristol Scale

struct BristolType: Identifiable {
    let id: Int
    var n: Int { id }
    let name: String
    let desc: String
    let visual: String
    let healthy: Bool
}

let bristolData: [BristolType] = [
    BristolType(id: 1, name: "Separate Hard Lumps",  desc: "Like nuts — hard to pass",        visual: "⚫", healthy: false),
    BristolType(id: 2, name: "Lumpy Sausage",         desc: "Sausage-shaped but lumpy",        visual: "🟤", healthy: false),
    BristolType(id: 3, name: "Cracked Sausage",       desc: "Sausage with surface cracks",     visual: "🟫", healthy: true),
    BristolType(id: 4, name: "Smooth Sausage",        desc: "Smooth, soft — ideal!",           visual: "🟩", healthy: true),
    BristolType(id: 5, name: "Soft Blobs",            desc: "Soft with clear-cut edges",       visual: "🟡", healthy: false),
    BristolType(id: 6, name: "Fluffy Pieces",         desc: "Mushy with ragged edges",         visual: "🟠", healthy: false),
    BristolType(id: 7, name: "Watery",                desc: "No solid pieces — liquid",        visual: "🔴", healthy: false),
]

// MARK: - Urine Color

struct UrineColorInfo: Identifiable {
    let id: Int
    var level: Int { id }
    let label: String
    let color: Color
    let hexColor: String
}

let urineColorData: [UrineColorInfo] = [
    UrineColorInfo(id: 1, label: "Clear — Very well hydrated",       color: Color(hex: "#F5F0C0"), hexColor: "#F5F0C0"),
    UrineColorInfo(id: 2, label: "Pale yellow — Well hydrated",      color: Color(hex: "#F0E070"), hexColor: "#F0E070"),
    UrineColorInfo(id: 3, label: "Light yellow — Good hydration",    color: Color(hex: "#E8C830"), hexColor: "#E8C830"),
    UrineColorInfo(id: 4, label: "Yellow — Drink more water",        color: Color(hex: "#D4A020"), hexColor: "#D4A020"),
    UrineColorInfo(id: 5, label: "Dark yellow — Mildly dehydrated",  color: Color(hex: "#B07010"), hexColor: "#B07010"),
    UrineColorInfo(id: 6, label: "Amber — Dehydrated",               color: Color(hex: "#8B4800"), hexColor: "#8B4800"),
    UrineColorInfo(id: 7, label: "Honey — Very dehydrated",          color: Color(hex: "#5C2E00"), hexColor: "#5C2E00"),
    UrineColorInfo(id: 8, label: "Brown — See a doctor",             color: Color(hex: "#3A1800"), hexColor: "#3A1800"),
]

// MARK: - Urgency

let urgencyLabels = ["", "No rush", "Mild urgency", "Moderate urgency", "Very urgent"]
let urgencyEmojis = ["", "😌", "🤔", "😰", "😱"]
