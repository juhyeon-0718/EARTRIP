import SwiftUI
import UIKit

/// Concept artwork, not a photograph of a verified real-world location.
struct PhotoPlaceholder: View {
    var height: CGFloat = 320
    var imageName: String? = nil
    var label = "새로운 여행을 준비하는 EAR TRIP"
    var body: some View {
        GeometryReader { proxy in
            Group {
                if let imageName, let image = UIImage(named: imageName) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image("TravelHero").resizable().scaledToFill()
                }
            }.frame(width: proxy.size.width, height: height).clipped()
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
