import SwiftUI

struct TripCompleteView: View {
    let course: Course
    @Environment(TripHistoryStore.self) private var history
    @State private var completedAt = Date.now

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image("CompanionResting").resizable().scaledToFit().frame(height: 240)
                    .accessibilityHidden(true)
                Text("오늘의 여행이\n기록됐어요").font(.largeTitle.bold()).multilineTextAlignment(.center)
                VStack(spacing: 18) {
                    HStack {
                        Text(course.city).font(.headline)
                        Spacer()
                        Text(completedAt, format: .dateTime.year().month().day()).font(.caption)
                    }
                    Text(course.title).font(.title2.bold()).multilineTextAlignment(.center)
                    Divider()
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { metrics }
                        VStack(spacing: 12) { metrics }
                    }
                }.padding(24).frame(maxWidth: .infinity)
                    .background(EARColor.paper.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(EARColor.sand, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                Text("여행의 여운을 오래 간직해요").foregroundStyle(EARColor.olive)
                NavigationLink { MyTripsView() } label: {
                    Text("내 여행 기록 보기 →").font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(EARColor.pear, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
                NavigationLink { ExploreView() } label: {
                    Text("다른 여행 둘러보기").frame(maxWidth: .infinity, minHeight: 54)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(EARColor.forest))
                }.buttonStyle(.plain)
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink)
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("여행 완료").navigationBarTitleDisplayMode(.inline)
        .onAppear { history.add(course: course, elapsedMinutes: 52) }
    }

    @ViewBuilder private var metrics: some View {
        Text("\(course.distanceKilometers, specifier: "%.1f") km")
        Text("이야기 \(course.spots.count)개")
        // No elapsed-time tracking yet; show the course estimate instead.
        Text("약 \(course.estimatedDurationMinutes)분 코스")
    }
}
