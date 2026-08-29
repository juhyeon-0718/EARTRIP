import SwiftUI

struct HomeView: View {
    private let course = MockCatalog.jagalchi

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("EAR TRIP").font(.headline).tracking(2.8)
                    Spacer()
                    Text("35.0968° N").font(.caption).monospaced().foregroundStyle(EARColor.stone)
                }
                .padding(.horizontal, EARSpacing.page)
                .padding(.top, 18)

                Text("걸을수록,\n도시는 이야기를\n시작합니다.")
                    .font(.system(size: 42, weight: .medium, design: .serif))
                    .tracking(-1.2)
                    .foregroundStyle(EARColor.ink)
                    .padding(.horizontal, EARSpacing.page)
                    .padding(.top, 42)
                    .padding(.bottom, 32)

                NavigationLink(value: AppRoute.course(course)) {
                    VStack(alignment: .leading, spacing: 0) {
                        PhotoPlaceholder(height: 370)
                        VStack(alignment: .leading, spacing: 10) {
                            EditorialLabel(text: "Featured walk · 부산")
                            Text(course.title)
                                .font(.system(.title, design: .serif, weight: .semibold))
                                .foregroundStyle(EARColor.ink)
                            Text(course.subtitle).font(.subheadline).foregroundStyle(EARColor.olive)
                            HStack(spacing: 24) {
                                Text("\(course.distanceKilometers, specifier: "%.1f") KM")
                                Text("약 \(course.estimatedDurationMinutes) MIN")
                                Text("\(course.spots.count) STORIES")
                            }
                            .font(.caption.weight(.medium)).tracking(1)
                            .foregroundStyle(EARColor.stone)
                            .padding(.top, 6)
                        }
                        .padding(24)
                    }
                    .background(EARColor.paper)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 16) {
                    EditorialLabel(text: "How it works")
                    Text("코스를 고르고,\n휴대폰을 내려놓고,\n도시의 목소리를 기다리세요.")
                        .font(.system(.title2, design: .serif))
                        .lineSpacing(7)
                    Text("장소에 가까워지면 이야기가 자동으로 시작됩니다.")
                        .font(.subheadline).foregroundStyle(EARColor.olive)
                }
                .padding(EARSpacing.page)
                .padding(.vertical, 28)
            }
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .earTripDestinations()
    }
}

#Preview { NavigationStack { HomeView() } }

