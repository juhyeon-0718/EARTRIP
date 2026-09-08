import SwiftUI

/// Concept artwork, not a photograph of a verified real-world location.
struct PhotoPlaceholder: View {
    var height: CGFloat = 320
    var dark = false
    var label = "부산 · 자갈치"
    var body: some View {
        GeometryReader { proxy in
            Image("HarborArtwork")
                .resizable().scaledToFill()
                .frame(width: proxy.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
        .accessibilityLabel("자갈치 여행을 표현한 항구 일러스트")
    }
}
