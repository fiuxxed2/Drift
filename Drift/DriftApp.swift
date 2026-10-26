import SwiftUI

@main
struct DriftApp: App {
    @StateObject private var model = TimerModel()
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(history)
                .preferredColorScheme(.dark)
                .onAppear {
                    model.onComplete = { [history] mode, minutes in
                        history.add(mode: mode, minutes: minutes)
                    }
                }
        }
    }
}
