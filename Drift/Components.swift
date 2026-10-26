import SwiftUI

/// Slow, flowing blobs of color. Cross-fades when the palette changes.
struct AnimatedBackground: View {
    let palette: [Color]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    Color.black
                    ForEach(0..<palette.count, id: \.self) { i in
                        let phase = t * (0.10 + Double(i) * 0.04) + Double(i) * 2.1
                        Circle()
                            .fill(palette[i])
                            .frame(width: geo.size.width * 1.15, height: geo.size.width * 1.15)
                            .offset(x: CGFloat(cos(phase)) * geo.size.width * 0.32,
                                    y: CGFloat(sin(phase * 1.3)) * geo.size.height * 0.28)
                            .blur(radius: 90)
                            .opacity(0.70)
                    }
                    // Darken slightly so white text always stays readable.
                    Color.black.opacity(0.28)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
        .animation(.easeInOut(duration: 1.2), value: palette)
        .ignoresSafeArea()
    }
}

struct RingView: View {
    /// 1 = full ring, 0 = empty.
    let progress: Double
    let colors: [Color]
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (colors.first ?? .white).opacity(0.55), radius: 14)
        }
        .padding(lineWidth / 2)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
