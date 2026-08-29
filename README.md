# EAR TRIP v2

> 지도를 보며 여행하는 앱이 아니라, 도시를 걸으면 도시가 말을 거는 앱.

EAR TRIP은 걷는 사람의 위치를 감지하고 특정 장소에 가까워졌을 때 그 장소의 이야기를 자동 재생하는 iOS 오디오 여행 앱입니다. 화면 체류를 늘리는 대신 휴대폰을 내려놓게 하는 것을 제품 원칙으로 삼습니다.

현재 저장소는 Phase 1 기반 구현입니다. 실제 서버·결제·상용 콘텐츠 없이 부산 자갈치 시장 Mock 코스로 전체 UX와 핵심 엔진을 검증할 수 있습니다.

## 구현 범위

- SwiftUI / iOS 17 앱과 XcodeGen 프로젝트 정의
- Home, Explore, Course Detail, Trip Preparation, Live Trip, Story Player, Story Detail, Trip Complete, My Trips
- Observation 기반 앱 상태와 SwiftUI Environment 의존성 주입
- Real/Mock 모드를 지원하는 CoreLocation 서비스
- AVPlayer + AVAudioSession 기반 오디오 서비스
- 위치, 중복 방지, 자동 재생, 진행 상태를 연결하는 TripEngine
- URLSession + FileManager 기반 오프라인 다운로드 골격과 Mock 준비 흐름
- 자갈치 시장 1.8km / 50분 / 5개 Story Mock 코스
- XCTest 단위 테스트
- Codemagic Development/TestFlight workflow
- GitHub Actions macOS simulator 검증

## Architecture

Feature-based 구조를 사용합니다. View는 화면 구성과 사용자 입력만 담당하며 CoreLocation과 AVPlayer를 직접 소유하지 않습니다. 초기 MVP에 불필요한 UseCase/Manager/Coordinator 계층은 만들지 않았습니다.

```text
EARTrip/
├── App/                 앱 진입점, 탭, Route
├── Core/
│   ├── Location/        권한, 실위치/Mock 위치, 거리
│   ├── Audio/           AVPlayer 재생 상태와 제어
│   ├── Download/        URLSession/FileManager 오프라인 기반
│   ├── Storage/         여행 기록 세션 저장소
│   └── TripEngine.swift 위치 → 반경 → 자동 재생 → 완료
├── DesignSystem/        색, 간격, 타이포그래피, 공통 요소
├── Features/            화면 단위 구현
├── MockData/            코스와 수정 가능한 GPS 좌표
├── Models/              Course, StorySpot, TripSession
└── Resources/           Asset catalog
Tests/                   핵심 거리/TripEngine 테스트
project.yml              XcodeGen single source of truth
codemagic.yaml           Cloud macOS CI / TestFlight
```

### 핵심 데이터 흐름

```text
LocationService
    ↓ coordinate + accuracy
TripEngine
    ↓ 다음 Story 거리 / trigger / 이미 재생했는지 확인
AudioService
    ↓ 완료 callback
TripSession
    ↓ completedSpotIDs / nextSpot / progress
SwiftUI
```

`completedSpotIDs`와 trigger arm을 세션/엔진에 보관하여 GPS가 반경 경계에서 흔들려도 같은 Story를 반복 자동 재생하지 않습니다. 65m보다 나쁜 accuracy에서는 자동 trigger를 보류합니다. 이 수치는 이후 실제 필드 테스트에서 조정할 수 있습니다.

## Tech Stack

- Swift 5 language mode, SwiftUI, iOS 17+ (Xcode 16+ toolchain)
- Observation (`@Observable`), SwiftUI Environment
- Swift Concurrency (`async/await`, `Task`, `MainActor`)
- CoreLocation, AVFoundation / AVPlayer
- URLSession, FileManager
- XCTest
- XcodeGen, Codemagic, GitHub Actions

## Local build on macOS

이 프로젝트는 `.pbxproj`를 수동 관리하지 않습니다. `project.yml`을 수정하고 프로젝트를 다시 생성합니다.

```bash
brew install xcodegen
git clone https://github.com/juhyeon-0718/EARTRIP.git
cd EARTRIP
xcodegen generate
xcodebuild build \
  -project EARTrip.xcodeproj \
  -scheme EARTrip \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

생성되는 `EARTrip.xcodeproj`는 빌드 산출물 성격이므로 필요할 때 재생성할 수 있습니다. 앱 Bundle ID 기본값은 `com.eartrip.app`입니다. 실제 소유 도메인에 맞게 출시 전에 `project.yml`과 CI signing 항목을 함께 변경하세요.

## Mac 없이 Cloud에서 확인하기

EAR TRIP의 기본 개발·배포 흐름은 다음과 같습니다.

```text
Codex Cloud
    ↓ source change
GitHub
    ↓ push / pull request
GitHub Actions
    ↓ XcodeGen + unsigned simulator compile + unit tests
Codemagic
    ↓ archive + signing
App Store Connect
    ↓ processing / internal testing
TestFlight
```

GitHub Actions는 모든 변경의 compile gate이며 Apple credential이 필요하지 않습니다. Codemagic TestFlight workflow는 compile gate를 통과한 commit에 대해 Apple signing 정보가 준비된 경우에만 실행합니다.

### GitHub Actions

`.github/workflows/ios.yml`이 모든 branch push와 pull request에서 다음을 수행합니다.

1. macOS 15 runner의 Xcode, Swift, simulator runtime 출력
2. XcodeGen 2.42+ 설치 및 버전 확인
3. `project.yml`에서 `EARTrip.xcodeproj` 생성
4. generated shared scheme `EARTrip` 확인
5. generic iOS Simulator 대상으로 signing 없는 Debug build
6. 사용 가능한 iPhone simulator를 동적으로 선택해 단위 테스트
7. 성공/실패와 관계없이 xcodebuild log 업로드

GitHub 저장소의 **Actions** 탭에서 결과를 볼 수 있습니다.

### Codemagic Development Build

1. Codemagic에서 GitHub 저장소를 연결합니다.
2. repository root의 `codemagic.yaml`을 선택합니다.
3. `EAR TRIP - Development Build` workflow를 실행합니다.

이 workflow는 Apple 인증 정보 없이 XcodeGen, shared scheme 검증, unsigned simulator build와 unit test를 실행합니다. 특정 iPhone 모델 이름을 고정하지 않고 runner에 설치된 사용 가능한 simulator를 선택합니다. 빌드된 `.app`, test result와 로그를 artifact로 남깁니다.

## TestFlight 연결

`EAR TRIP - TestFlight` workflow는 인증 정보가 준비된 이후 수동 실행하는 배포 경로입니다. 저장소에는 인증서, provisioning profile, API private key를 넣지 않습니다.

Codemagic에서 다음을 설정해야 합니다.

1. App Store Connect에서 앱을 만들고 Bundle ID `com.eartrip.app`을 등록
2. App Store Connect API Key 생성(App Manager 권한 권장)
3. Codemagic **Team settings → Integrations → App Store Connect**에 다음 값 등록
   - Issuer ID
   - Key ID
   - API private key (`.p8` 내용)
4. integration 이름을 정확히 `EARTRIP_ASC`로 지정
5. Codemagic **Code signing identities**에서 해당 Bundle ID의 Apple Distribution certificate와 App Store provisioning profile을 fetch 또는 upload
6. TestFlight workflow 실행

Codemagic이 integration을 통해 profile을 적용하고, `CM_BUILD_NUMBER`를 build number로 설정하고, signed IPA를 만들어 TestFlight에 제출합니다.

필요한 비밀 값은 Codemagic UI에만 저장합니다.

| 값 | 저장 위치 | 저장소 commit |
|---|---|---|
| App Store Connect Issuer ID | `EARTRIP_ASC` integration | 금지 |
| App Store Connect Key ID | `EARTRIP_ASC` integration | 금지 |
| App Store Connect `.p8` private key | `EARTRIP_ASC` integration | 금지 |
| Apple Distribution certificate/private key | Codemagic code signing | 금지 |
| App Store provisioning profile | Codemagic code signing | 금지 |

팀에서 environment group 방식으로 바꿀 경우 secret 이름은 `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY`로 통일하는 것을 권장합니다. 현재 YAML은 더 안전한 Codemagic integration 방식을 사용합니다.

## Mock course와 위치 테스트

첫 코스는 부산 **자갈치 시장 골목 이야기**입니다. 좌표를 수정할 때는 아래 한 파일만 변경합니다.

```text
EARTrip/MockData/JagalchiCoordinates.swift
```

`LocationService(mode: .mock)`을 만들고 `pushMockLocation(_:accuracy:)`를 호출하면 실제 GPS 없이 trigger를 테스트할 수 있습니다. 단위 테스트가 이 경로를 사용합니다. Live Trip 화면의 `DEMO · 다음 이야기 재생`은 아직 실제 음원 URL이 없는 Phase 1에서 전체 UX를 확인하기 위한 명시적 simulator fallback입니다.

## Offline design

`DownloadService`는 서버가 연결되면 개별 파일을 application support 아래 course별 디렉터리에 저장할 수 있습니다. UI는 `notDownloaded`, `downloading(progress:)`, `ready`, `failed`를 표현합니다. 현재 자갈치 코스는 짧은 Mock 준비 흐름을 사용합니다.

향후 background `URLSessionConfiguration.background`, manifest checksum, 부분 재시도, 저장 공간 검사로 확장할 수 있도록 다운로드 책임을 View 밖에 두었습니다.

## Accessibility와 디자인

- Dynamic Type에 대응하는 semantic font를 우선 사용
- 핵심 버튼 최소 높이와 VoiceOver label 제공
- Warm Ivory / Deep Forest Green 중심, 보라색 및 neon 미사용
- 사진이 없어도 레이아웃을 검토할 수 있는 비구상적 photo placeholder
- Live Trip은 길찾기 지도 대신 거리와 trigger radius를 공간적으로 표현
- Story Player는 음악 플레이어 대신 장소·좌표·Story sequence를 강조

## 아직 구현하지 않은 기능

- Supabase / PostGIS / Storage production 연결
- 로그인, Apple Sign In
- StoreKit 2 결제 또는 RevenueCat
- 실제 audio/image CDN과 콘텐츠 CMS
- Background location entitlement와 장시간 필드 검증
- Lock screen `MPNowPlayingInfoCenter`, Remote Command Center
- interruption/route change의 전체 production 처리
- background URLSession과 checksum 기반 완전한 오프라인 패키지
- analytics, push notification, admin dashboard
- production 사진, 음원, App Icon

빈 `AppIcon.appiconset`은 향후 production icon의 위치만 예약합니다. 현재 simulator compile에서는 App Icon 이름을 build setting에 강제하지 않으므로 이미지가 없어도 build가 깨지지 않습니다. TestFlight/App Store 제출 전에는 반드시 유효한 1024×1024 App Icon을 추가해야 합니다.

## 출시 전 체크리스트

- 실제 Bundle ID와 Apple Team 확정
- App Icon 및 production 사진/음원 추가
- 위치 권한 문구 현지화 및 background location 정책 검토
- 실제 도보 필드 테스트로 trigger radius/accuracy threshold 조정
- 개인정보 처리방침과 App Store privacy questionnaire 작성
- TestFlight internal testing 후 interruption, Bluetooth, 잠금 화면 검증
