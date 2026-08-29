import SwiftUI

struct StoryDetailView: View {
    let story: StorySpot
    @Environment(AudioService.self) private var audio

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PhotoPlaceholder(height: 350, label: "STORY \(String(format: "%02d", story.order))")
                VStack(alignment: .leading, spacing: 24) {
                    EditorialLabel(text: "Jagalchi · Busan")
                    Text(story.title).font(.system(.largeTitle, design: .serif, weight: .medium))
                    Text(story.description).font(.body).lineSpacing(7).foregroundStyle(EARColor.olive)

                    HStack {
                        Button { audio.isPlaying ? audio.pause() : audio.play() } label: {
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .frame(width: 46, height: 46).foregroundStyle(.white).background(EARColor.forest, in: Circle())
                        }
                        VStack(alignment: .leading) {
                            Text("PLACE STORY").font(.caption2).tracking(1.5)
                            ProgressView(value: audio.progress).tint(EARColor.forest)
                        }
                    }
                    .padding(.vertical, 16)

                    EditorialLabel(text: "Location")
                    Text("\(story.coordinate.latitude, specifier: "%.5f")° N  \(story.coordinate.longitude, specifier: "%.5f")° E")
                        .font(.caption).monospaced().foregroundStyle(EARColor.stone)

                    if let nextStory {
                        EditorialLabel(text: "Next story")
                            .padding(.top, 16)
                        NavigationLink(value: AppRoute.story(nextStory)) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(String(format: "%02d", nextStory.order)).font(.caption).monospaced()
                                Text(nextStory.title).font(.system(.title3, design: .serif, weight: .medium))
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
        .earTripDestinations()
    }

    private var nextStory: StorySpot? {
        MockCatalog.jagalchi.spots.first(where: { $0.order == story.order + 1 })
    }
}
