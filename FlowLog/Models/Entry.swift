import Foundation

enum EntryType: String, Codable {
    case urine, bowel
}

struct Entry: Codable, Identifiable {
    var id: Int64
    var type: EntryType
    var date: String        // "YYYY-MM-DD"
    var time: Date

    // Urine fields
    var color: Int?
    var colorLabel: String?
    var colorHex: String?

    // Bowel fields
    var bristol: Int?
    var bristolName: String?
    var bristolVisual: String?
    var healthy: Bool?

    // Shared fields
    var urgency: Int
    var duration: Int
    var symptoms: [String]
    var notes: String
}
