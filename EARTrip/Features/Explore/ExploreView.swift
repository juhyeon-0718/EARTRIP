import SwiftUI

struct ExploreView: View {
    @Environment(CourseCatalog.self) private var catalog
    private var cities: [String] { catalog.cities }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("어느 도시가 궁금하세요?")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))

                ForEach(Array(cities.enumerated()), id: \.element) { index, city in
                    let courses = catalog.courses(in: city)
                    VStack(alignment: .leading, spacing: 12) {
                        PhotoPlaceholder(height: 170, imageName: artwork(for: city), label: "\(city) 여행 일러스트")
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        CityRow(city: city, number: index + 1, count: courses.count)
                    }
                    ForEach(courses) { course in
                        NavigationLink(value: AppRoute.course(course)) {
                            HStack {
                                Text(course.title).font(.headline)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }.frame(minHeight: 44)
                        }.buttonStyle(.plain)
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

    private func artwork(for city: String) -> String? {
        switch city {
        case "서울": "SeoulArtwork"
        case "부산": "HarborArtwork"
        case "경주": "GyeongjuArtwork"
        default: catalog.courses(in: city).first?.coverImage
        }
    }
}

private struct CityRow: View {
    let city: String
    let number: Int
    let count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(city).font(.title2.bold())
            Spacer()
            Text(count > 0 ? "여행 \(count)개" : "준비 중")
                .font(.caption2.weight(.semibold)).tracking(1.2).foregroundStyle(count > 0 ? EARColor.forest : EARColor.stone)
        }
        .foregroundStyle(EARColor.ink)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview { NavigationStack { ExploreView() }.environment(CourseCatalog(courses: MockCatalog.courses, cities: MockCatalog.cities)) }
