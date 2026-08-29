import SwiftUI

struct LiveTripView: View {
    @Environment(TripEngine.self) private var engine
    @Environment(LocationService.self) private var location
    @State private var pulse = false
    @State private var presentedStory: StorySpot?

    var body: some View {
        ZStack {
            EARColor.ivory.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    EditorialLabel(text: "Live walk")
                    Spacer()
                    Label(gpsText, systemImage: "location.fill")
                        .font(.caption).foregroundStyle(EARColor.olive)
                }
                .padding(.horizontal, EARSpacing.page)
                .padding(.top, 18)

                Spacer()

                VStack(spacing: 10) {
                    EditorialLabel(text: "Next story")
                    Text(distanceText)
                        .font(.system(size: 66, weight: .light, design: .serif))
                        .monospacedDigit()
                    Text(engine.session?.nextSpot?.title ?? "모든 이야기를 걸었습니다")
                        .font(.headline).multilineTextAlignment(.center)
                }

                ProximityField(pulse: pulse, progress: proximityProgress)
                    .frame(height: 270)
                    .onAppear { withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { pulse = true } }

                Text(engine.session?.state == .completed ? "오늘의 걸음이 기록되었습니다." : "조금만 더 걸으면\n이야기가 시작돼요.")
                    .font(.system(.title3, design: .serif))
                    .multilineTextAlignment(.center).lineSpacing(5)

                Spacer()

                VStack(spacing: 14) {
                    ProgressView(value: engine.session?.progress ?? 0).tint(EARColor.forest)
                    HStack {
                        Text(progressText).font(.caption).monospaced()
                        Spacer()
                        Text("화면을 내려놓아도 좋아요").font(.caption).foregroundStyle(EARColor.stone)
                    }
                }
                .padding(EARSpacing.page)

                if engine.session?.state == .completed, let course = engine.session?.currentCourse {
                    NavigationLink(value: AppRoute.complete(course)) {
                        Text("여행 기록 보기").font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56).background(EARColor.forest)
                    }
                    .buttonStyle(.plain).padding(.horizontal, EARSpacing.page)
                } else {
                    Button("DEMO · 다음 이야기 재생") { engine.triggerCurrentStoryForDemo() }
                        .font(.caption.weight(.semibold)).tracking(1).foregroundStyle(EARColor.olive)
                        .padding(.bottom, 12)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onChange(of: engine.session?.currentSpot) { _, spot in presentedStory = spot }
        .fullScreenCover(item: $presentedStory) { story in
            NavigationStack { StoryPlayerView(story: story) }
        }
        .earTripDestinations()
    }

    private var gpsText: String {
        guard let accuracy = location.horizontalAccuracy else { return location.mode == .mock ? "MOCK GPS" : "GPS SEARCHING" }
        return "GPS ±\(Int(accuracy))M"
    }

    private var distanceText: String {
        guard let distance = engine.session?.distanceToNextSpot else { return "— m" }
        return distance >= 1000 ? String(format: "%.1f km", distance / 1000) : "\(Int(distance)) m"
    }

    private var progressText: String {
        let done = engine.session?.completedSpotIDs.count ?? 0
        let total = engine.session?.currentCourse.spots.count ?? 0
        return String(format: "%02d / %02d", done, total)
    }

    private var proximityProgress: Double {
        guard let distance = engine.session?.distanceToNextSpot else { return 0.12 }
        return max(0.08, min(1, 1 - distance / 500))
    }
}

private struct ProximityField: View {
    let pulse: Bool
    let progress: Double

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(EARColor.olive.opacity(0.18 - Double(index) * 0.035), lineWidth: 1)
                    .frame(width: CGFloat(90 + index * 62), height: CGFloat(90 + index * 62))
                    .scaleEffect(pulse ? 1.04 : 0.96)
            }
            Circle().fill(EARColor.forest.opacity(0.12)).frame(width: 64, height: 64)
            Circle().fill(EARColor.forest).frame(width: 13, height: 13)
            Circle()
                .fill(EARColor.sand)
                .overlay(Circle().stroke(EARColor.ivory, lineWidth: 3))
                .frame(width: 22, height: 22)
                .offset(y: CGFloat(-35 - 72 * progress))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다음 이야기까지의 거리 감지 영역")
    }
}
