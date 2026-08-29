import SwiftUI

struct CourseDetailView: View {
    let course: Course

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PhotoPlaceholder(height: 410)
                VStack(alignment: .leading, spacing: 24) {
                    EditorialLabel(text: course.city)
                    Text(course.title)
                        .font(.system(size: 38, weight: .medium, design: .serif))
                        .tracking(-0.8)
                    Text(course.description)
                        .font(.body).lineSpacing(6).foregroundStyle(EARColor.olive)

                    HStack(spacing: 34) {
                        MetricItem(value: String(format: "%.1f", course.distanceKilometers), label: "KM")
                        MetricItem(value: "약 \(course.estimatedDurationMinutes)", label: "MIN")
                        MetricItem(value: "\(course.spots.count)", label: "STORIES")
                    }
                    .padding(.vertical, 10)

                    StoryTimeline(spots: course.spots)

                    NavigationLink(value: AppRoute.preparation(course)) {
                        HStack {
                            Text("이 여행 시작하기").font(.headline)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(.horizontal, 22).frame(minHeight: 58)
                        .foregroundStyle(.white).background(EARColor.forest)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                }
                .padding(EARSpacing.page)
            }
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .earTripDestinations()
    }
}

private struct StoryTimeline: View {
    let spots: [StorySpot]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EditorialLabel(text: "Story sequence")
                .padding(.bottom, 22)
            ForEach(spots) { spot in
                HStack(alignment: .top, spacing: 18) {
                    Text(String(format: "%02d", spot.order))
                        .font(.caption).monospaced().foregroundStyle(EARColor.olive)
                        .frame(width: 28, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spot.title).font(.system(.title3, design: .serif, weight: .medium))
                        Text(spot.subtitle).font(.caption).foregroundStyle(EARColor.stone)
                    }
                    Spacer()
                }
                .padding(.vertical, 18)
                .overlay(alignment: .bottom) { Rectangle().fill(EARColor.sand).frame(height: 1) }
            }
        }
    }
}

#Preview { NavigationStack { CourseDetailView(course: MockCatalog.jagalchi) } }
