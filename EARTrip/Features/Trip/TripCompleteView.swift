import SwiftUI

struct TripCompleteView: View {
    let course: Course
    @Environment(TripHistoryStore.self) private var history

    var body: some View {
        ScrollView {
            VStack(spacing: 34) {
                EditorialLabel(text: "Trip complete")
                VStack(spacing: 4) {
                    Text("JAGALCHI").font(.system(.largeTitle, design: .default, weight: .semibold)).tracking(1)
                    Text("BUSAN").font(.caption.weight(.semibold)).tracking(4).foregroundStyle(EARColor.olive)
                }

                TicketMark()

                HStack(spacing: 40) {
                    MetricItem(value: String(format: "%.1f", course.distanceKilometers), label: "KM")
                    MetricItem(value: "\(course.spots.count)", label: "Stories")
                    MetricItem(value: "52", label: "MIN")
                }
                Text("한 도시를 통과한 것이 아니라,\n잠시 그 도시의 이야기를 들었습니다.")
                    .font(.system(.title3, design: .default)).multilineTextAlignment(.center).lineSpacing(6)
                    .foregroundStyle(EARColor.olive)
            }
            .frame(maxWidth: .infinity)
            .padding(EARSpacing.page)
            .padding(.top, 36)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .onAppear { history.add(course: course, elapsedMinutes: 52) }
    }
}

private struct TicketMark: View {
    var body: some View {
        ZStack {
            Circle().stroke(EARColor.forest.opacity(0.28), lineWidth: 1).frame(width: 170, height: 170)
            Circle().stroke(EARColor.forest, style: StrokeStyle(lineWidth: 2, dash: [3, 5])).frame(width: 145, height: 145)
            VStack(spacing: 7) {
                Text("EAR TRIP").font(.caption.weight(.bold)).tracking(2)
                Image(systemName: "figure.walk").font(.title2)
                Text("29 AUG 2026").font(.caption2).monospaced()
            }.foregroundStyle(EARColor.forest).rotationEffect(.degrees(-7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("EAR TRIP 부산 여행 완료 기록")
    }
}
