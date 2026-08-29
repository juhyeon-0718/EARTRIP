import SwiftUI

struct StoryPlayerView: View {
    let story: StorySpot
    @Environment(AudioService.self) private var audio
    @Environment(TripEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            EARColor.forest.ignoresSafeArea()
            VStack(spacing: 0) {
                PhotoPlaceholder(height: 310, dark: true, label: String(format: "%.4f° N · BUSAN", story.coordinate.latitude))
                    .overlay(alignment: .topTrailing) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.down").font(.headline).foregroundStyle(.white)
                                .frame(width: 44, height: 44).background(.black.opacity(0.18), in: Circle())
                        }
                        .padding()
                        .accessibilityLabel("플레이어 닫기")
                    }

                VStack(alignment: .leading, spacing: 20) {
                    EditorialLabel(text: "Story \(story.order) / \(MockCatalog.jagalchi.spots.count)", color: EARColor.sand)
                    Text(story.title)
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    HStack {
                        Text("JAGALCHI").tracking(2)
                        Spacer()
                        Text("BUSAN").tracking(2)
                    }
                    .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.55))

                    AudioWave(progress: audio.progress).frame(height: 54)

                    Slider(value: Binding(get: { audio.progress }, set: { audio.seek(to: $0 * audio.duration) }), in: 0...1)
                        .tint(EARColor.sand)
                        .accessibilityLabel("이야기 재생 위치")
                    HStack {
                        Text(format(audio.currentTime))
                        Spacer()
                        Text("−" + format(audio.duration))
                    }
                    .font(.caption).monospacedDigit().foregroundStyle(.white.opacity(0.65))

                    HStack {
                        PlayerControl(icon: "gobackward.15", label: "15초 뒤로") { audio.skipBackward() }
                        Spacer()
                        Button {
                            audio.isPlaying ? engine.pauseStory() : engine.resumeStory()
                        } label: {
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2).foregroundStyle(EARColor.forest)
                                .frame(width: 68, height: 68).background(EARColor.ivory, in: Circle())
                        }
                        .accessibilityLabel(audio.isPlaying ? "일시 정지" : "재생")
                        Spacer()
                        PlayerControl(icon: "goforward.15", label: "15초 앞으로") { audio.skipForward() }
                    }
                    .padding(.horizontal, 24)

                    Button("이야기 완료 · 다음 장소로") {
                        engine.completeCurrentStory()
                        dismiss()
                    }
                    .font(.caption.weight(.semibold)).tracking(1)
                    .foregroundStyle(EARColor.sand)
                    .frame(maxWidth: .infinity).padding(.top, 8)

                    NavigationLink(value: AppRoute.story(story)) {
                        Text("이 장소의 이야기 더 읽기")
                            .font(.caption).foregroundStyle(.white.opacity(0.65))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(EARSpacing.page)
                Spacer(minLength: 12)
            }
        }
        .statusBarHidden()
        .earTripDestinations()
    }

    private func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}

private struct PlayerControl: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: icon).font(.title2).foregroundStyle(.white) }
            .accessibilityLabel(label)
    }
}

private struct AudioWave: View {
    let progress: Double
    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<42) { index in
                    let height = CGFloat(10 + ((index * 17) % 35))
                    Capsule()
                        .fill(Double(index) / 42 <= progress ? EARColor.sand : Color.white.opacity(0.22))
                        .frame(width: max(2, (proxy.size.width - 123) / 42), height: height)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}
