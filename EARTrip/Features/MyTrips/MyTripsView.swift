import SwiftUI

struct MyTripsView: View {
    @Environment(TripHistoryStore.self) private var history

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("내 여행")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                Text("내가 만난 도시의 이야기").foregroundStyle(EARColor.olive)
                Text("여행 기록").font(.headline).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .bottom) { Rectangle().fill(EARColor.leaf).frame(height: 2) }

                if history.records.isEmpty {
                    Image("CompanionResting").resizable().scaledToFit().frame(height: 230)
                        .frame(maxWidth: .infinity).accessibilityHidden(true)
                    Text("첫 여행을 기다리고 있어요.\n도시의 이야기를 만나보세요.")
                        .font(.system(.title3, design: .default)).lineSpacing(6)
                        .foregroundStyle(EARColor.olive)
                } else {
                    ForEach(history.records) { record in
                        VStack(alignment: .leading, spacing: 14) {
                            PhotoPlaceholder(height: 170, imageName: record.course.coverImage, label: record.course.title)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            EditorialLabel(text: record.course.city)
                            Text(record.course.title).font(.system(.title2, design: .default, weight: .medium))
                            HStack {
                                Text("\(record.course.distanceKilometers, specifier: "%.1f") km")
                                Text("이야기 \(record.course.spots.count)개")
                            }
                            .font(.caption).tracking(1).foregroundStyle(EARColor.stone)
                            Text(record.completedAt, format: .dateTime.year().month().day())
                                .font(.caption).foregroundStyle(EARColor.olive)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding(EARSpacing.page)
            .padding(.top, 20)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("내 여행")
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { MyTripsView().environment(TripHistoryStore()) }
