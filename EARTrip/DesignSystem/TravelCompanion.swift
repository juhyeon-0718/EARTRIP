import SwiftUI

struct TravelCompanion: View {
    var walking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !walking || reduceMotion)) { timeline in
            let step = walking && !reduceMotion ? sin(timeline.date.timeIntervalSinceReferenceDate * 9) : 0
            Image("CompanionWalking")
                .resizable().scaledToFit()
                .rotationEffect(.degrees(step * 2))
                .offset(y: CGFloat(abs(step)) * -2)
                .frame(width: 76, height: 84)
        }.accessibilityHidden(true)
    }
}

struct PreparationArtwork: View {
    var walking = true
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 35, y: 215))
                    path.addCurve(to: CGPoint(x: geometry.size.width - 50, y: 30),
                                  control1: CGPoint(x: geometry.size.width + 30, y: 170),
                                  control2: CGPoint(x: 40, y: 90))
                }.stroke(EARColor.sand.opacity(0.45), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                Ellipse().fill(EARColor.pear).frame(width: 54, height: 24).position(x: geometry.size.width - 50, y: 30)
                TravelCompanion(walking: walking).scaleEffect(1.4).position(x: 70, y: 176)
            }
        }.frame(height: 250).accessibilityHidden(true)
    }
}

#Preview { PreparationArtwork().padding().background(EARColor.ivory) }
