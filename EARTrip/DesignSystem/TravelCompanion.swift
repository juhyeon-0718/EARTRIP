import SwiftUI

struct TravelCompanion: View {
    var walking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !walking || reduceMotion)) { timeline in
            let step = walking && !reduceMotion ? sin(timeline.date.timeIntervalSinceReferenceDate * 9) : 0
            ZStack {
                Ellipse().fill(EARColor.ivory)
                    .overlay(Ellipse().stroke(EARColor.forest, lineWidth: 3))
                    .frame(width: 48, height: 57).offset(y: -3)
                Capsule().fill(EARColor.forest).frame(width: 9, height: 21).rotationEffect(.degrees(step * 24)).offset(x: -12, y: 29)
                Capsule().fill(EARColor.forest).frame(width: 9, height: 21).rotationEffect(.degrees(-step * 24)).offset(x: 12, y: 29)
                HStack(spacing: 12) {
                    Capsule().frame(width: 4, height: 7)
                    Capsule().frame(width: 4, height: 7)
                }.foregroundStyle(EARColor.forest)
                Image(systemName: "headphones").font(.system(size: 64, weight: .light)).foregroundStyle(EARColor.forest).offset(y: -7)
            }.offset(y: CGFloat(abs(step)) * -2).frame(width: 76, height: 84)
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
                TravelCompanion(walking: walking).position(x: 70, y: 176)
            }
        }.frame(height: 250).accessibilityHidden(true)
    }
}

#Preview { PreparationArtwork().padding().background(EARColor.ivory) }
