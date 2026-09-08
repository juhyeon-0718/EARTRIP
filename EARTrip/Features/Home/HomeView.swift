import SwiftUI

struct HomeView: View {
    private let course = MockCatalog.jagalchi
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label("EAR TRIP", systemImage: "waveform").font(.headline)
                    Spacer()
                    Text(course.city).font(.subheadline)
                }.foregroundStyle(EARColor.forest)
                VStack(alignment: .leading, spacing: 12) {
                    Text("오늘, 어디로\n떠나볼까요?").font(.largeTitle.weight(.semibold))
                    Text("걸음마다 새로운 이야기").foregroundStyle(EARColor.olive)
                }.padding(.top, 12)
                PhotoPlaceholder(height: 270)
                    .overlay(alignment: .bottomLeading) { TravelCompanion().padding(24) }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                VStack(alignment: .leading, spacing: 12) {
                    Text("오늘의 여행").font(.subheadline).foregroundStyle(EARColor.olive)
                    Text(course.title).font(.title2.weight(.semibold))
                    Text("시장과 바다 사이에 숨은 이야기를 만나요.").foregroundStyle(EARColor.olive)
                    Text("\(course.distanceKilometers, specifier: "%.1f")km · \(course.estimatedDurationMinutes)분 · 이야기 \(course.spots.count)개")
                        .font(.subheadline).foregroundStyle(EARColor.olive)
                }
                NavigationLink(value: AppRoute.course(course)) {
                    HStack { Text("이 여행 만나보기"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.headline).padding(22).foregroundStyle(EARColor.forest)
                        .background(EARColor.pear, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink)
        .background(EARColor.ivory.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .earTripDestinations()
    }
}
#Preview { NavigationStack { HomeView() } }
