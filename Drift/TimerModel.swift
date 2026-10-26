import SwiftUI
import UIKit
import UserNotifications

/// Timer based on an end date (not a tick counter), so it stays accurate
/// when the app is backgrounded, and the ring can animate at full frame rate.
@MainActor
final class TimerModel: ObservableObject {
    enum RunState { case idle, running, paused }

    @Published private(set) var state: RunState = .idle
    @Published private(set) var mode: Mode = .focus
    @Published private(set) var minutes: Int = Mode.focus.defaultMinutes

    var onComplete: (@MainActor (Mode, Int) -> Void)?

    private var endDate: Date?
    private var pausedRemaining: TimeInterval = 0
    private var finishTask: Task<Void, Never>?
    private let notificationID = "drift.finish"

    var duration: TimeInterval { TimeInterval(minutes * 60) }

    func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle: return duration
        case .paused: return pausedRemaining
        case .running: return max(0, (endDate ?? now).timeIntervalSince(now))
        }
    }

    // MARK: Controls

    func start() {
        guard state != .running else { return }
        let left = state == .paused ? pausedRemaining : duration
        endDate = Date().addingTimeInterval(left)
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        scheduleFinish(after: left)
        scheduleNotification(after: left)
        Haptics.impact(.medium)
    }

    func pause() {
        guard state == .running else { return }
        pausedRemaining = remaining(at: Date())
        finishTask?.cancel()
        cancelNotification()
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
        Haptics.impact(.light)
    }

    func reset() {
        finishTask?.cancel()
        cancelNotification()
        endDate = nil
        pausedRemaining = 0
        state = .idle
        UIApplication.shared.isIdleTimerDisabled = false
        Haptics.impact(.rigid)
    }

    func setMinutes(_ value: Int) {
        guard state == .idle, value != minutes else { return }
        minutes = value
        Haptics.selection()
    }

    func setMode(_ newMode: Mode) {
        guard state == .idle, newMode != mode else { return }
        mode = newMode
        minutes = newMode.defaultMinutes
        Haptics.selection()
    }

    /// Call when the app returns to the foreground.
    func checkExpiry() {
        if state == .running, let end = endDate, end <= Date() {
            complete()
        }
    }

    // MARK: Completion

    private func scheduleFinish(after seconds: TimeInterval) {
        finishTask?.cancel()
        finishTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.complete()
        }
    }

    private func complete() {
        guard state == .running else { return }
        finishTask?.cancel()
        cancelNotification()
        let finishedMode = mode
        let finishedMinutes = minutes
        endDate = nil
        pausedRemaining = 0
        state = .idle
        UIApplication.shared.isIdleTimerDisabled = false
        onComplete?(finishedMode, finishedMinutes)
        Haptics.success()
        // Flip to the other mode so the next tap starts the natural next step.
        mode = finishedMode == .focus ? .rest : .focus
        minutes = mode.defaultMinutes
    }

    // MARK: Notifications

    private func scheduleNotification(after seconds: TimeInterval) {
        let isFocus = mode == .focus
        let id = notificationID
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            Task { @MainActor in
                // The user may have paused or reset while the permission prompt was open.
                guard let self, self.state == .running else { return }
                let content = UNMutableNotificationContent()
                content.title = isFocus ? "Focus complete" : "Break's over"
                content.body = isFocus ? "Nice work. Time to drift for a bit." : "Ready for another round?"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
