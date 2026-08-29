import SwiftUI

struct PhotoPlaceholder: View {
    var height: CGFloat = 320
    var dark = false
    var label = "JAGALCHI · BUSAN"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: dark
                    ? [EARColor.forest, Color(red: 0.06, green: 0.09, blue: 0.08)]
                    : [EARColor.sand.opacity(0.65), EARColor.olive.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                for index in 0..<7 {
                    let y = size.height * CGFloat(index + 1) / 8
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width, y: y + CGFloat(index.isMultiple(of: 2) ? 18 : -14)),
                        control1: CGPoint(x: size.width * 0.3, y: y - 16),
                        control2: CGPoint(x: size.width * 0.72, y: y + 24)
                    )
                    context.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
                }
            }
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))
                .padding(20)
        }
        .frame(height: height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) 여행 사진 자리")
    }
}

