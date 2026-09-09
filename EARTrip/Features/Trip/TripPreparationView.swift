import SwiftUI
import UIKit

struct TripPreparationView: View {
    let course: Course
    @Environment(DownloadService.self) private var downloads
    @Environment(LocationService.self) private var location
    @Environment(TripEngine.self) private var engine
    @Environment(\.openURL) private var openURL
    @State private var pathToLive = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(ready ? "여행 준비가 끝났어요" : "여행을 준비하고 있어요").font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 28)
                Text(ready ? course.title : "이야기를 담는 동안 잠시만 기다려주세요")
                    .foregroundStyle(EARColor.olive).frame(maxWidth: .infinity).multilineTextAlignment(.center)
                PreparationArtwork(walking: !ready)
                HStack {
                    Text("오디오 준비").font(.headline)
                    Spacer()
                    Text(ready ? "준비 완료" : "\(Int(progress * 100))%")
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(EARColor.paper)
                        Capsule().fill(EARColor.leaf.opacity(0.75)).frame(width: geometry.size.width * progress)
                    }
                }.frame(height: 16)
                    .accessibilityLabel("오디오 준비").accessibilityValue("\(Int(progress * 100))퍼센트")
                Text("현재는 체험용 콘텐츠예요. 실제 음원 다운로드는 아직 제공되지 않습니다.")
                    .font(.footnote).foregroundStyle(EARColor.olive)
                Divider()
                Button {
                    if location.authorizationStatus == .denied || location.authorizationStatus == .restricted {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } else { location.requestPermission() }
                } label: {
                    Label(location.isAuthorized || location.mode == .mock ? "위치 권한 확인 완료" : "위치 권한 허용하기", systemImage: location.isAuthorized ? "checkmark.circle.fill" : "location")
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                }
                Text("장소에 가까워지면 이야기가 시작돼요. 지도와 도보 경로는 인터넷 연결이 필요해요.")
                    .foregroundStyle(EARColor.olive)
                PrimaryActionButton(title: ready ? "준비 완료, 출발" : "준비 중…") {
                    engine.prepare(course: course)
                    engine.start()
                    pathToLive = true
                }.disabled(!ready || !(location.isAuthorized || location.mode == .mock))
            }.padding(EARSpacing.page)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .foregroundStyle(EARColor.ink)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("여행 준비").navigationBarTitleDisplayMode(.inline)
        .task { if !ready { await downloads.prepareMockCourse(course) } }
        .navigationDestination(isPresented: $pathToLive) { LiveTripView() }
    }
    private var ready: Bool { downloads.state(for: course).isReady }
    private var progress: Double {
        switch downloads.state(for: course) {
        case .downloading(let progress): progress
        case .ready, .demoReady: 1
        default: 0
        }
    }
}
