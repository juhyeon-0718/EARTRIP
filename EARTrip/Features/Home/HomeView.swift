import SwiftUI

struct HomeView: View {
    private let courses = MockCatalog.courses
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label("EAR TRIP", systemImage: "waveform").font(.headline)
                    Spacer()
                    Text("도시의 이야기를 만나요").font(.caption)
                }.foregroundStyle(EARColor.forest)
                VStack(alignment: .leading, spacing: 12) {
                    Text("오늘, 어디로\n떠나볼까요?").font(.largeTitle.weight(.semibold))
                    Text("걸음마다 새로운 이야기").foregroundStyle(EARColor.olive)
                }.padding(.top, 12)
                PhotoPlaceholder(height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("지금 떠날 수 있는 여행").font(.title2.weight(.semibold))
                ForEach(courses) { course in
                PhotoPlaceholder(height: 180, imageName: course.coverImage, label: course.title)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                VStack(alignment: .leading, spacing: 12) {
                    Text(course.city).font(.subheadline).foregroundStyle(EARColor.olive)
                    Text(course.title).font(.title2.weight(.semibold))
                    Text(course.subtitle).foregroundStyle(EARColor.olive)
                    Text("\(course.distanceKilometers, specifier: "%.1f")km · \(course.estimatedDurationMinutes)분 · 이야기 \(course.spots.count)개")
                        .font(.subheadline).foregroundStyle(EARColor.olive)
                }
                NavigationLink(value: AppRoute.course(course)) {
                    HStack { Text("이 여행 만나보기"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.headline).padding(22).foregroundStyle(EARColor.forest)
                        .background(EARColor.pear, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
                }
                if courses.isEmpty {
                    Text("새로운 여행을 준비하고 있어요.").foregroundStyle(EARColor.olive)
                }
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink)
        .background(EARColor.ivory.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .earTripDestinations()
    }
}
#Preview { NavigationStack { HomeView() } }
