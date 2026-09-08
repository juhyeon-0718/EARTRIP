import SwiftUI

struct ExploreView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialLabel(text: "도시별 여행")
                Text("어느 도시를\n걸어볼까요?")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))

                ForEach(Array(MockCatalog.cities.enumerated()), id: \.element) { index, city in
                    if city == "부산" {
                        NavigationLink(value: AppRoute.course(MockCatalog.jagalchi)) {
                            CityRow(city: city, number: index + 1, available: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        CityRow(city: city, number: index + 1, available: false)
                    }
                }
            }
            .padding(EARSpacing.page)
            .padding(.top, 20)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("둘러보기")
        .navigationBarTitleDisplayMode(.inline)
        .earTripDestinations()
    }
}

private struct CityRow: View {
    let city: String
    let number: Int
    let available: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(String(format: "%02d", number)).font(.caption).monospaced().foregroundStyle(EARColor.stone)
            Text(city).font(.system(.largeTitle, design: .default, weight: .medium))
            Spacer()
            Text(available ? "여행 1개" : "준비 중")
                .font(.caption2.weight(.semibold)).tracking(1.2).foregroundStyle(available ? EARColor.forest : EARColor.stone)
        }
        .foregroundStyle(EARColor.ink)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) { Rectangle().fill(EARColor.sand).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

#Preview { NavigationStack { ExploreView() } }
