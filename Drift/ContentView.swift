import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: TimerModel
    @EnvironmentObject private var history: HistoryStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showHistory = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            AnimatedBackground(palette: model.mode.palette)

            VStack(spacing: 0) {
                header
                modePicker.padding(.top, 20)
                Spacer(minLength: 16)
                timerRing
                Spacer(minLength: 16)
                presets
                controls.padding(.top, 28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .environmentObject(history)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.checkExpiry() }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drift")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("\(history.todayMinutes) min focused today")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: history.todayMinutes)
            }
            Spacer()
            Button {
                Haptics.impact(.light)
                showHistory = true
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 8)
    }

    // MARK: Mode picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { m in
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { model.setMode(m) }
                } label: {
                    Text(m.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(model.mode == m ? Color.black : Color.white.opacity(0.75))
                        .background {
                            if model.mode == m {
                                Capsule().fill(Color.white).matchedGeometryEffect(id: "mode", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .disabled(model.state != .idle)
        .opacity(model.state == .idle ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.25), value: model.state)
    }

    // MARK: Ring + time

    private var timerRing: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: model.state != .running)) { ctx in
            let remaining = model.remaining(at: ctx.date)
            let progress = model.duration > 0 ? remaining / model.duration : 0
            let secs = Int(ceil(remaining))

            ZStack {
                RingView(progress: progress, colors: model.mode.ringColors)
                VStack(spacing: 6) {
                    Text(timeString(secs))
                        .font(.system(size: 66, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy(duration: 0.25), value: secs)
                    Text(statusText)
                        .font(.footnote.weight(.medium))
                        .textCase(.uppercase)
                        .tracking(2.5)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: 330)
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: model.state)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: model.minutes)
    }

    private var statusText: String {
        switch model.state {
        case .idle: return "Ready"
        case .running: return model.mode == .focus ? "Focusing" : "Resting"
        case .paused: return "Paused"
        }
    }

    private func timeString(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    // MARK: Presets

    private var presets: some View {
        HStack(spacing: 10) {
            ForEach(model.mode.presets, id: \.self) { m in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { model.setMinutes(m) }
                } label: {
                    Text("\(m)")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(model.minutes == m ? Color.black : Color.white)
                        .background {
                            if model.minutes == m {
                                Capsule().fill(Color.white).matchedGeometryEffect(id: "preset", in: ns)
                            } else {
                                Capsule().fill(Color.white.opacity(0.10))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .disabled(model.state != .idle)
        .opacity(model.state == .idle ? 1 : 0.35)
        .animation(.easeInOut(duration: 0.25), value: model.state)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 28) {
            if model.state != .idle {
                Button {
                    withAnimation { model.reset() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 58, height: 58)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(PressableStyle())
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    if model.state == .running { model.pause() } else { model.start() }
                }
            } label: {
                Image(systemName: model.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 88, height: 88)
                    .background(
                        Circle().fill(
                            LinearGradient(colors: model.mode.ringColors,
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    )
                    .shadow(color: (model.mode.ringColors.first ?? .white).opacity(0.55), radius: 24, y: 10)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressableStyle())
        }
        .frame(height: 90)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: model.state)
    }
}
