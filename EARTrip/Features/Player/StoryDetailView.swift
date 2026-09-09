import SwiftUI

struct StoryDetailView: View {
    let story: StorySpot
    let course: Course
    @Environment(AudioService.self) private var audio

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PhotoPlaceholder(height: 290, imageName: story.image ?? course.coverImage, label: story.title)
                    .overlay(alignment: .bottomTrailing) { TravelCompanion().padding(24) }
                VStack(alignment: .leading, spacing: 24) {
                    EditorialLabel(text: course.city)
                    Text(story.title).font(.system(.largeTitle, design: .default, weight: .medium))
                    Text(story.description).font(.body).lineSpacing(7).foregroundStyle(EARColor.olive)

                    HStack {
                        Button { audio.isPlaying ? audio.pause() : audio.play() } label: {
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .frame(width: 58, height: 58).foregroundStyle(EARColor.ink).background(EARColor.apricot, in: Circle())
                        }
                        .accessibilityLabel(audio.isPlaying ? "이야기 일시 정지" : "이야기 이어 듣기")
                        VStack(alignment: .leading) {
                            Text("이야기 이어 듣기").font(.subheadline.weight(.semibold))
                            ProgressView(value: audio.progress).tint(EARColor.leaf)
                        }
                    }
                    .padding(.vertical, 16)

                    EditorialLabel(text: "이야기가 있는 곳")
                    Text("\(story.coordinate.latitude, specifier: "%.5f")° N  \(story.coordinate.longitude, specifier: "%.5f")° E")
                        .font(.caption).monospaced().foregroundStyle(EARColor.stone)

                    if let nextStory {
                        EditorialLabel(text: "다음 이야기")
                            .padding(.top, 16)
                        NavigationLink(value: AppRoute.story(nextStory, course: course)) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(String(format: "%02d", nextStory.order)).font(.caption).monospaced()
                                Text(nextStory.title).font(.system(.title3, design: .default, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(EARColor.ink)
                            .padding(.vertical, 18)
                            .overlay(alignment: .bottom) { Rectangle().fill(EARColor.sand).frame(height: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(EARSpacing.page)
            }
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationTitle("장소 이야기").navigationBarTitleDisplayMode(.inline)
        .earTripDestinations()
    }

    private var nextStory: StorySpot? {
        course.story(after: story)
    }
}
