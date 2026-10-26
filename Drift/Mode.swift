import SwiftUI

enum Mode: String, Codable, CaseIterable, Identifiable {
    case focus, rest

    var id: String { rawValue }

    var title: String { self == .focus ? "Focus" : "Break" }

    var presets: [Int] { self == .focus ? [15, 25, 45, 60] : [5, 10, 15] }

    var defaultMinutes: Int { self == .focus ? 25 : 5 }

    /// Three colors used by the flowing background.
    var palette: [Color] {
        switch self {
        case .focus:
            return [Color(red: 0.36, green: 0.22, blue: 0.95),
                    Color(red: 0.88, green: 0.28, blue: 0.72),
                    Color(red: 0.10, green: 0.45, blue: 0.95)]
        case .rest:
            return [Color(red: 0.05, green: 0.70, blue: 0.62),
                    Color(red: 0.20, green: 0.85, blue: 0.45),
                    Color(red: 0.10, green: 0.50, blue: 0.90)]
        }
    }

    /// Two colors used by the ring and the main button.
    var ringColors: [Color] {
        switch self {
        case .focus:
            return [Color(red: 0.62, green: 0.45, blue: 1.0), Color(red: 1.0, green: 0.45, blue: 0.80)]
        case .rest:
            return [Color(red: 0.30, green: 0.95, blue: 0.75), Color(red: 0.35, green: 0.75, blue: 1.0)]
        }
    }
}
