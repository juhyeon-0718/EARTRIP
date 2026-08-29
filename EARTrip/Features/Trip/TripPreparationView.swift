import SwiftUI

struct TripPreparationView: View {
    let course: Course
    @Environment(DownloadService.self) private var downloads
    @Environment(LocationService.self) private var location
    @Environment(TripEngine.self) private var engine
    @State private var pathToLive = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                EditorialLabel(text: "Before the walk")
                Text(course.title).font(.system(.largeTitle, design: .serif, weight: .medium))
                HStack(spacing: 30) {
                    MetricItem(value: "\(course.spots.count)", label: "Stories")
                    MetricItem(value: String(format: "%.1f", course.distanceKilometers), label: "KM")
                    MetricItem(value: "약 \(course.estimatedDurationMinutes)", label: "MIN")
                }

                ReadinessRow(title: "오디오 다운로드", detail: "약 35MB", status: downloadText)
                    .task {
                        if !downloads.state(for: course).isReady { await downloads.prepareMockCourse(course) }
                    }
                ReadinessRow(title: "위치 권한", detail: "자동 재생에 필요", status: locationStatus)
                    .onTapGesture { location.requestPermission() }
                ReadinessRow(title: "오디오", detail: "무음 모드에서도 재생", status: "준비")

                Text("휴대폰을 계속 보고\n걸을 필요는 없어요.\n\n장소에 가까워지면\n이야기가 자동으로 시작됩니다.")
                    .font(.system(.title2, design: .serif, weight: .medium))
                    .lineSpacing(7)
                    .padding(.vertical, 16)

                PrimaryActionButton(title: "준비 완료, 출발") {
                    engine.prepare(course: course)
                    engine.start()
                    pathToLive = true
                }
                .disabled(!downloads.state(for: course).isReady)
                .opacity(downloads.state(for: course).isReady ? 1 : 0.55)
            }
            .padding(EARSpacing.page)
        }
        .background(EARColor.ivory.ignoresSafeArea())
        .navigationDestination(isPresented: $pathToLive) { LiveTripView() }
    }

    private var downloadText: String {
        switch downloads.state(for: course) {
        case .notDownloaded: "대기"
        case .downloading(let progress): "\(Int(progress * 100))%"
        case .ready: "✓ 준비 완료"
        case .failed: "다시 시도"
        }
    }

    private var locationStatus: String {
        location.mode == .mock ? "Mock" : (location.isAuthorized ? "✓ 허용됨" : "탭하여 허용")
    }
}

private struct ReadinessRow: View {
    let title: String
    let detail: String
    let status: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(EARColor.stone)
            }
            Spacer()
            Text(status).font(.caption.weight(.semibold)).foregroundStyle(EARColor.forest)
        }
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) { Rectangle().fill(EARColor.sand).frame(height: 1) }
    }
}
