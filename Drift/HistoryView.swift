import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.07, blue: 0.22), Color.black],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        statTiles
                        chartCard
                        sessionList
                    }
                    .padding(20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Stat tiles

    private var statTiles: some View {
        HStack(spacing: 12) {
            tile(title: "Today", value: "\(history.todayMinutes)", unit: "min")
            tile(title: "7 days", value: "\(history.weekMinutes)", unit: "min")
            tile(title: "Sessions", value: "\(history.focusSessionCount)", unit: "")
        }
    }

    private func tile(title: String, value: String, unit: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 days")
                    .font(.headline)
                Chart(history.lastSevenDays()) { stat in
                    BarMark(
                        x: .value("Day", stat.day, unit: .day),
                        y: .value("Minutes", stat.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: Mode.focus.ringColors, startPoint: .bottom, endPoint: .top)
                    )
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: Sessions

    private var sessionList: some View {
        let groups = Dictionary(grouping: history.sessions) { Calendar.current.startOfDay(for: $0.date) }
        let days = groups.keys.sorted(by: >)

        return VStack(alignment: .leading, spacing: 14) {
            if days.isEmpty {
                GlassCard {
                    Text("No sessions yet. Start your first one!")
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            } else {
                ForEach(days, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .padding(.leading, 4)
                        ForEach(groups[day] ?? []) { session in
                            row(session)
                        }
                    }
                }
            }
        }
    }

    private func row(_ session: Session) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: session.mode == .focus ? "scope" : "cup.and.saucer.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: session.mode.ringColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28)
                Text("\(session.minutes) min \(session.mode.title)")
                    .font(.system(.body, design: .rounded).weight(.medium))
                Spacer()
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.55))
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { history.remove(session) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
