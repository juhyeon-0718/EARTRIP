import SwiftUI

struct MyTripsView: View {
    @Environment(TripHistoryStore.self) private var history

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialLabel(text: "Walking archive")
                Text("나의 여행 기록")
                    .font(.system(size: 40, weight: .medium, design: .serif))

                if history.records.isEmpty {
                    PhotoPlaceholder(height: 250, dark: true, label: "YOUR FIRST WALK")
                    Text("아직 기록된 걸음이 없습니다.\n첫 도시의 목소리를 만나보세요.")
                        .font(.system(.title3, design: .serif)).lineSpacing(6)
                        .foregroundStyle(EARColor.olive)
                } else {
                    ForEach(history.records) { record in
                        VStack(alignment: .leading, spacing: 14) {
                            PhotoPlaceholder(height: 210, dark: true)
                            EditorialLabel(text: record.course.city)
                            Text(record.course.title).font(.system(.title2, design: .serif, weight: .medium))
                            HStack {
                                Text("\(record.course.distanceKilometers, specifier: "%.1f") KM")
                                Text("\(record.course.spots.count) STORIES")
                                Text("\(record.elapsedMinutes) MIN")
                            }
                            .font(.caption).tracking(1).foregroundStyle(EARColor.stone)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding(EARSpacing.page)
            .padding(.top, 20)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("My Trips")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { MyTripsView().environment(TripHistoryStore()) }
