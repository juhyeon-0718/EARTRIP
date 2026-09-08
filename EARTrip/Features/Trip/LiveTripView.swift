import SwiftUI
import MapKit

struct LiveTripView: View {
    @Environment(TripEngine.self) private var engine
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var routes = WalkingRouteService()
    @State private var camera: MapCameraPosition = .automatic
    @State private var presentedStory: StorySpot?
    @State private var confirmEnd = false

    var body: some View {
        Map(position: $camera) {
            ForEach(routes.courseLegs) { leg in
                MapPolyline(leg.route.polyline).stroke(EARColor.olive.opacity(0.5), lineWidth: 4)
            }
            if let route = routes.nextRoute {
                MapPolyline(route.polyline).stroke(EARColor.forest, lineWidth: 6)
            }
            ForEach(engine.session?.currentCourse.spots ?? []) { spot in
                if spot.id == engine.session?.nextSpot?.id {
                    MapCircle(center: spot.coordinate.clLocationCoordinate2D, radius: spot.triggerRadius)
                        .foregroundStyle(EARColor.pear.opacity(0.35))
                }
                Annotation(spot.title, coordinate: spot.coordinate.clLocationCoordinate2D) {
                    Text(engine.session?.completedSpotIDs.contains(spot.id) == true ? "✓" : "\(spot.order)")
                        .font(.headline).foregroundStyle(EARColor.forest)
                        .frame(width: 34, height: 34)
                        .background(spot.id == engine.session?.nextSpot?.id ? EARColor.pear : EARColor.ivory, in: Circle())
                        .overlay(Circle().stroke(EARColor.forest, lineWidth: 1))
                        .accessibilityLabel("이야기 \(spot.order), \(spot.title)")
                }
            }
            UserAnnotation {
                TimelineView(.periodic(from: .now, by: 2)) { context in
                    VStack(spacing: 0) {
                        TravelCompanion(walking: location.speed > 0.35 && context.date.timeIntervalSince(location.lastUpdate ?? .distantPast) < 10 && engine.session?.state != .paused)
                            .scaleEffect(0.65).frame(width: 52, height: 58)
                        Circle().fill(.blue).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }.accessibilityLabel("내 위치")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls { MapCompass(); MapScaleView() }
        .overlay(alignment: .topLeading) {
            TimelineView(.periodic(from: .now, by: 5)) { context in
                Label(locationStatus(at: context.date), systemImage: "location.fill")
                    .font(.caption).padding(10).background(EARColor.ivory, in: Capsule()).padding(12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("다음 이야기까지").font(.subheadline).foregroundStyle(EARColor.olive)
                    Spacer()
                    Button { followUser() } label: {
                        Image(systemName: "location.fill").frame(width: 44, height: 44)
                    }.accessibilityLabel("내 위치 따라가기")
                }
                Text(distanceText).font(.largeTitle.weight(.semibold)).monospacedDigit()
                Text(engine.session?.nextSpot?.title ?? "모든 이야기를 만났어요").font(.headline)
                if routes.nextRoute == nil {
                    Text(routes.isLoading ? "도보 경로를 찾고 있어요…" : (routes.message ?? "위치를 확인하면 도보 경로를 안내해요."))
                        .font(.footnote).foregroundStyle(EARColor.olive)
                } else {
                    Text("초록색 도보 경로를 따라 이동해주세요").font(.subheadline)
                }
                ProgressView(value: engine.session?.progress ?? 0).tint(EARColor.olive)
                Text("이야기 \(engine.session?.completedSpotIDs.count ?? 0) / \(engine.session?.currentCourse.spots.count ?? 0)")
                    .font(.caption).foregroundStyle(EARColor.olive)
                if engine.session?.state == .completed, let course = engine.session?.currentCourse {
                    NavigationLink("여행 기록 보기", value: AppRoute.complete(course)).frame(minHeight: 44)
                } else if let story = engine.session?.currentSpot {
                    Button("이야기 플레이어 열기") { presentedStory = story }.frame(minHeight: 44)
                } else {
                    Button {
                        engine.session?.state == .paused ? engine.resumeTrip() : engine.pauseTrip()
                    } label: {
                        Label(engine.session?.state == .paused ? "다시 출발" : "잠깐 쉬기",
                              systemImage: engine.session?.state == .paused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(EARColor.forest))
                    }
                }
                #if DEBUG
                Button("체험 · 다음 이야기 재생") { engine.triggerCurrentStoryForDemo() }.font(.caption)
                #endif
            }.padding(.horizontal, 24).padding(.bottom, 12)
                .foregroundStyle(EARColor.ink).background(EARColor.ivory)
        }
        .navigationTitle(engine.session?.currentCourse.title ?? "여행 지도").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("종료") { confirmEnd = true } }
        }
        .confirmationDialog("여행을 종료할까요?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("여행 종료", role: .destructive) { engine.endTrip(); dismiss() }
        }
        .task {
            followUser()
            presentedStory = engine.session?.currentSpot
            if let course = engine.session?.currentCourse { await routes.loadCourse(course) }
        }
        .task(id: engine.session?.nextSpot?.id) {
            routes.clearNextRoute()
            while !Task.isCancelled {
                if let origin = location.coordinate, let spot = engine.session?.nextSpot,
                   (location.horizontalAccuracy ?? .infinity) <= 65 {
                    await routes.update(from: origin, to: spot)
                }
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
            }
        }
        .onChange(of: engine.session?.currentSpot) { _, spot in presentedStory = spot }
        .fullScreenCover(item: $presentedStory) { story in NavigationStack { StoryPlayerView(story: story) } }
        .earTripDestinations()
    }

    private var distanceText: String {
        if let route = routes.nextRoute { return "\(Int(route.distance)) m · 도보" }
        guard let spot = engine.session?.nextSpot,
              let distance = location.distance(to: spot) else { return "— m" }
        return "\(Int(distance)) m · 직선 거리"
    }

    private func locationStatus(at date: Date) -> String {
        if location.mode == .mock { return "체험용 위치" }
        guard location.isAuthorized else { return "위치 권한이 필요해요" }
        guard let updated = location.lastUpdate, date.timeIntervalSince(updated) < 20 else {
            return "현재 위치를 확인하고 있어요"
        }
        if (location.horizontalAccuracy ?? .infinity) > 65 { return "위치 신호가 약해요" }
        return "위치 연결됨"
    }

    private func followUser() {
        guard let center = engine.session?.currentCourse.startingCoordinate else {
            camera = .automatic
            return
        }
        camera = .userLocation(followsHeading: true, fallback: .region(MKCoordinateRegion(
            center: center.clLocationCoordinate2D, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))))
    }
}
