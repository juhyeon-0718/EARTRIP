import SwiftUI

enum EARColor {
    static let forest = Color(red: 23 / 255, green: 60 / 255, blue: 50 / 255)
    static let ivory = Color(red: 255 / 255, green: 253 / 255, blue: 245 / 255)
    static let pear = Color(red: 202 / 255, green: 218 / 255, blue: 153 / 255)
    static let apricot = Color(red: 246 / 255, green: 199 / 255, blue: 173 / 255)
    static let ink = Color(red: 23 / 255, green: 25 / 255, blue: 24 / 255)
    static let olive = Color(red: 108 / 255, green: 113 / 255, blue: 86 / 255)
    static let sand = Color(red: 220 / 255, green: 207 / 255, blue: 179 / 255)
    static let stone = Color(red: 139 / 255, green: 136 / 255, blue: 127 / 255)
    static let paper = Color(red: 238 / 255, green: 232 / 255, blue: 218 / 255)
}

enum EARSpacing {
    static let page: CGFloat = 24
    static let section: CGFloat = 40
    static let compact: CGFloat = 12
}

struct EditorialLabel: View {
    let text: String
    var color: Color = EARColor.olive

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .accessibilityLabel(text)
    }
}

struct MetricItem: View {
    let value: String
    let label: String
    var light = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.weight(.medium)).monospacedDigit()
            Text(label.uppercased()).font(.caption2).tracking(1.5).opacity(0.65)
        }
        .foregroundStyle(light ? Color.white : EARColor.ink)
    }
}

struct PrimaryActionButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }
            .padding(.horizontal, 22)
            .frame(minHeight: 58)
            .foregroundStyle(EARColor.forest)
            .background(EARColor.pear, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
