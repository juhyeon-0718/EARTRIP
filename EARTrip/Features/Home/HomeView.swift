import SwiftUI

struct HomeView: View {
    @Environment(CourseCatalog.self) private var catalog
    private var courses: [Course] { catalog.courses }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Label("EAR TRIP", systemImage: "waveform").font(.headline)
                    Spacer()
                    NavigationLink { ExploreView() } label: {
                        Label("도시 선택", systemImage: "chevron.down").font(.subheadline)
                    }
                }.foregroundStyle(EARColor.forest)
                VStack(alignment: .leading, spacing: 10) {
                    Text("오늘, 어디로\n떠나볼까요?").font(.largeTitle.bold())
                    Text("걸음마다 새로운 이야기").foregroundStyle(EARColor.olive)
                }.padding(.top, 12)
                PhotoPlaceholder(height: 240, imageName: "TravelHero")
                    .padding(.horizontal, -EARSpacing.page)
                Text("추천 여행").font(.title2.bold())
                ForEach(courses) { course in
                    VStack(alignment: .leading, spacing: 12) {
                        PhotoPlaceholder(height: 165, imageName: course.coverImage, label: course.title)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Text(course.city).font(.subheadline).foregroundStyle(EARColor.olive)
                        Text(course.title).font(.title2.bold())
                        Text("\(course.distanceKilometers, specifier: "%.1f")km · \(course.estimatedDurationMinutes)분 · 이야기 \(course.spots.count)개")
                            .font(.subheadline).foregroundStyle(EARColor.olive)
                        NavigationLink(value: AppRoute.course(course)) {
                            HStack {
                                Text("이 여행 만나보기")
                                Image(systemName: "arrow.right")
                            }.font(.headline).frame(maxWidth: .infinity, minHeight: 56)
                                .foregroundStyle(EARColor.ink)
                                .background(EARColor.pear, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                }
                if courses.isEmpty { Text("새로운 여행을 준비하고 있어요.") }
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink)
        .background(EARColor.ivory.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .earTripDestinations()
    }
}
#Preview { NavigationStack { HomeView() }.environment(CourseCatalog(courses: MockCatalog.courses)) }
