import SwiftUI

struct StoryPlayerView: View {
    let story: StorySpot
    @Environment(TripEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PhotoPlaceholder(height: 310, imageName: story.image ?? course?.coverImage, label: story.title)
                    .overlay(alignment: .bottomTrailing) { TravelCompanion().scaleEffect(1.3).padding(32) }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("이야기 \(story.order)").font(.subheadline).foregroundStyle(EARColor.olive)
                Text(story.title).font(.title.weight(.semibold)).multilineTextAlignment(.center)
                if let course { Text(course.city).foregroundStyle(EARColor.olive) }
                VStack(spacing: 4) {
                    Slider(value: Binding(get: { engine.playbackProgress }, set: { engine.seek(to: $0 * engine.duration) }), in: 0...1)
                        .tint(EARColor.leaf).accessibilityLabel("이야기 재생 위치")
                    HStack { Text(format(engine.currentTime)); Spacer(); Text(format(engine.duration)) }
                        .font(.subheadline).monospacedDigit().foregroundStyle(EARColor.olive)
                }
                HStack {
                    control("gobackward.15", "15초 뒤로") { engine.skipBackward() }
                    Spacer()
                    Button { engine.togglePlayback(for: story) } label: {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title).frame(width: 80, height: 80)
                            .background(EARColor.apricot, in: Circle())
                    }.disabled(engine.session?.state == .loadingStory)
                        .accessibilityLabel(engine.isPlaying ? "일시 정지" : "재생")
                    Spacer()
                    control("goforward.15", "15초 앞으로") { engine.skipForward() }
                }.foregroundStyle(EARColor.forest)
                if let error = engine.playbackError {
                    Text(error).font(.footnote).foregroundStyle(EARColor.olive)
                }
                if story.audioURL == nil && story.localAudioURL == nil {
                    Text("체험용 이야기 · 실제 음원은 준비 중이에요").font(.footnote).foregroundStyle(EARColor.olive)
                }
                Button("이야기 완료 · 다음 장소로") {
                    engine.completeCurrentStory()
                    dismiss()
                }.frame(minHeight: 44)
                Divider()
                if let course {
                    NavigationLink(value: AppRoute.story(story, course: course)) { Text("이 장소가 궁금해요 →").frame(minHeight: 44) }
                }
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink).background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("지금 듣는 이야기").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        .onChange(of: engine.session?.currentSpot) { _, spot in if spot == nil { dismiss() } }
        .earTripDestinations()
    }
    private var course: Course? {
        guard let course = engine.session?.currentCourse, course.id == story.courseID else { return nil }
        return course
    }
    private func control(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).font(.title2).frame(width: 56, height: 56) }.accessibilityLabel(label)
    }
    private func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
