import SwiftUI

struct StoryPlayerView: View {
    let story: StorySpot
    @Environment(AudioService.self) private var audio
    @Environment(TripEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PhotoPlaceholder(height: 260)
                    .overlay(alignment: .bottomTrailing) { TravelCompanion().padding(24) }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                Text("이야기 \(story.order)").font(.subheadline).foregroundStyle(EARColor.olive)
                Text(story.title).font(.title.weight(.semibold)).multilineTextAlignment(.center)
                Text(engine.session?.currentCourse.city ?? "부산").foregroundStyle(EARColor.olive)
                VStack(spacing: 4) {
                    Slider(value: Binding(get: { audio.progress }, set: { audio.seek(to: $0 * audio.duration) }), in: 0...1)
                        .tint(EARColor.olive).accessibilityLabel("이야기 재생 위치")
                    HStack { Text(format(audio.currentTime)); Spacer(); Text(format(audio.duration)) }
                        .font(.subheadline).monospacedDigit().foregroundStyle(EARColor.olive)
                }
                HStack {
                    control("gobackward.15", "15초 뒤로") { audio.skipBackward() }
                    Spacer()
                    Button { audio.isPlaying ? engine.pauseStory() : engine.resumeStory() } label: {
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title).frame(width: 80, height: 80)
                            .background(EARColor.apricot, in: Circle())
                    }.accessibilityLabel(audio.isPlaying ? "일시 정지" : "재생")
                    Spacer()
                    control("goforward.15", "15초 앞으로") { audio.skipForward() }
                }.foregroundStyle(EARColor.forest)
                if story.audioURL == nil && story.localAudioURL == nil {
                    Text("체험용 이야기 · 실제 음원은 준비 중이에요").font(.footnote).foregroundStyle(EARColor.olive)
                }
                Button("이야기 완료 · 다음 장소로") {
                    engine.completeCurrentStory()
                    dismiss()
                }.frame(minHeight: 44)
                Divider()
                NavigationLink(value: AppRoute.story(story)) { Text("이 장소가 궁금해요 →").frame(minHeight: 44) }
            }.padding(EARSpacing.page)
        }
        .foregroundStyle(EARColor.ink).background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("지금 듣는 이야기").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        .onChange(of: engine.session?.currentSpot) { _, spot in if spot == nil { dismiss() } }
        .earTripDestinations()
    }
    private func control(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).font(.title2).frame(width: 56, height: 56) }.accessibilityLabel(label)
    }
    private func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
