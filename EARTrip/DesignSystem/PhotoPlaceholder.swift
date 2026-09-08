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
                    ZStack {
                        EARColor.paper
                        Circle().fill(EARColor.pear).frame(width: 140, height: 140).offset(x: -65, y: 35)
                        Circle().fill(EARColor.apricot).frame(width: 80, height: 80).offset(x: 85, y: -45)
                        TravelCompanion()
                    }
                }
            }.frame(width: proxy.size.width, height: height).clipped()
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
