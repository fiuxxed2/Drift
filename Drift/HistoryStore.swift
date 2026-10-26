import SwiftUI

struct Session: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var minutes: Int
    var mode: Mode
}

struct DayStat: Identifiable {
    let day: Date
    let minutes: Int
    var id: Date { day }
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var sessions: [Session] = []

    private let key = "drift.sessions.v1"

    init() { load() }

    func add(mode: Mode, minutes: Int) {
        sessions.insert(Session(date: Date(), minutes: minutes, mode: mode), at: 0)
        save()
    }

    func remove(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    // MARK: Stats (focus sessions only)

    func focusMinutes(on day: Date) -> Int {
        let cal = Calendar.current
        return sessions
            .filter { $0.mode == .focus && cal.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.minutes }
    }

    var todayMinutes: Int { focusMinutes(on: Date()) }

    var focusSessionCount: Int { sessions.filter { $0.mode == .focus }.count }

    func lastSevenDays() -> [DayStat] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayStat(day: day, minutes: focusMinutes(on: day))
        }
    }

    var weekMinutes: Int { lastSevenDays().reduce(0) { $0 + $1.minutes } }

    // MARK: Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
