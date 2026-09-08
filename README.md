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

## 첫 TestFlight 배포 방법

`EAR TRIP - TestFlight` workflow는 GitHub의 검증된 commit에서 Release archive를 만들고, Codemagic이 App Store용 signing asset을 적용해 IPA를 생성한 뒤 TestFlight에 업로드하는 수동 배포 경로입니다. 인증서, provisioning profile, API private key는 저장소나 YAML에 넣지 않습니다.

### 1. Apple Developer에서 App ID 등록

1. [Apple Developer](https://developer.apple.com/account/)에 Account Holder 또는 Admin 권한 계정으로 로그인합니다.
2. **Certificates, Identifiers & Profiles → Identifiers → + → App IDs → App**을 선택합니다.
3. Description은 `EAR TRIP`, Bundle ID는 **Explicit** `com.eartrip.app`으로 등록합니다.
4. 현재 단계에서는 추가 capability를 켜지 않습니다. 위치 When-In-Use와 background audio는 entitlement가 아니라 `Info.plist` 설정으로 동작합니다. Background Location, Push Notifications, Sign in with Apple 등은 아직 활성화하지 않습니다.

### 2. App Store Connect에 앱 생성

1. [App Store Connect](https://appstoreconnect.apple.com/)에서 **My Apps → + → New App**을 선택합니다.
2. Platforms는 iOS, Name은 `EAR TRIP`, Primary Language는 한국어를 선택합니다.
3. 방금 등록한 Bundle ID `com.eartrip.app`을 선택합니다.
4. SKU는 계정 내부에서 고유한 값(예: `EARTRIP-IOS`)을 입력합니다.
5. 앱을 만든 뒤 **App Information**에서 표시되는 Apple ID 숫자를 기록합니다. 현재 workflow에는 필요하지 않지만, 이후 App Store의 최신 build number를 조회하는 방식으로 바꿀 때 사용합니다.

### 3. App Store Connect API key 생성

1. App Store Connect의 **Users and Access → Integrations → App Store Connect API → Team Keys**로 이동합니다.
2. `EARTRIP Codemagic` 같은 이름으로 키를 만들고 App Manager 권한을 부여합니다.
3. 화면에 표시되는 **Issuer ID**와 **Key ID**를 기록합니다.
4. `.p8` private key를 다운로드합니다. Apple은 이 파일을 한 번만 내려받게 하므로 안전한 비밀 저장소에 보관합니다.

### 4. Codemagic integration 연결

1. Codemagic에서 GitHub 계정을 연결하고 `juhyeon-0718/EARTRIP` 저장소를 앱으로 추가합니다.
2. **Team settings → Integrations → Developer Portal / App Store Connect**에서 새 integration을 만듭니다.
3. 이름을 YAML과 정확히 같은 `EARTRIP_ASC`로 지정합니다.
4. Issuer ID, Key ID, `.p8` private key를 입력하고 연결을 검증합니다.
5. 이 값들은 Codemagic integration에만 저장하고 GitHub secret이나 저장소 파일로 복사하지 않습니다.

### 5. App Store signing asset 준비

Codemagic의 automatic signing asset 선택을 사용합니다. `codemagic.yaml`의 `ios_signing`이 `app_store` 배포용 `com.eartrip.app` certificate/profile을 찾고, `xcode-project use-profiles`가 생성된 Xcode project에 적용합니다.

1. Codemagic **Team settings → Code signing identities → iOS certificates**에서 `EARTRIP_ASC` integration으로 Apple Distribution certificate를 생성하거나, Codemagic에서 과거 생성한 기존 certificate를 가져옵니다. 새로 생성했다면 화면에서 한 번만 제공되는 certificate 파일과 password를 안전하게 보관한 뒤 같은 화면의 Upload certificate 탭에 등록합니다.
2. Apple Developer에서 `com.eartrip.app`용 **App Store** provisioning profile을 만들고 위 Distribution certificate를 연결합니다. Codemagic UI가 profile 생성/fetch를 지원하면 같은 integration을 사용해 가져옵니다.
3. Codemagic **iOS provisioning profiles**에 해당 profile이 표시되고 Bundle ID와 Team이 certificate와 일치하는지 확인합니다.

다른 환경에서 만든 certificate는 private key가 포함된 `.p12`와 password가 있어야 Codemagic에 업로드할 수 있습니다. Mac이 없는 경우 Codemagic에서 certificate를 생성한 뒤 즉시 다운로드·재등록하는 경로가 가장 단순합니다.

### 6. Production App Icon 추가

TestFlight/App Store archive에는 실제 App Icon이 필요합니다. 현재 저장소는 빈 1024×1024 universal iOS 슬롯만 제공하며 임의의 production icon은 포함하지 않습니다.

1. alpha channel이 없는 최종 1024×1024 PNG를 `EARTrip/Resources/Assets.xcassets/AppIcon.appiconset/`에 추가합니다.
2. `Contents.json`의 1024×1024 항목에 실제 filename을 지정합니다. 예를 들어 파일명이 `AppIcon-1024.png`이면 해당 항목에 `"filename" : "AppIcon-1024.png"`를 추가합니다.
3. 변경을 GitHub에 push하고 GitHub Actions가 다시 green인지 확인합니다.

TestFlight workflow는 이 파일을 archive 전에 검사합니다. 아이콘이 없거나 manifest에 filename이 없으면 Apple 업로드 단계까지 진행하지 않고 원인을 명시해 실패합니다.

### 7. TestFlight workflow 실행

1. Codemagic 앱의 **Start new build**를 선택합니다.
2. GitHub Actions를 통과한 branch/commit을 선택합니다.
3. workflow는 **EAR TRIP - TestFlight** (`testflight-build`)를 선택합니다.
4. build를 시작하고 `Generate Xcode project → Validate TestFlight prerequisites → Set CI build number → Apply App Store signing profile → Build signed IPA → Publish` 순서가 성공하는지 확인합니다.
5. App Store Connect **My Apps → EAR TRIP → TestFlight**에서 processing이 끝난 build를 확인하고 Internal Testing group에 추가합니다.

### 필요한 값과 저장 위치

| 값 | 어디에서 확인/생성하는가 | 어디에 입력하는가 | 비밀 여부 |
|---|---|---|---|
| Bundle ID `com.eartrip.app` | Apple Developer Identifiers | `project.yml`, Codemagic signing 조건, App Store Connect app | 공개 설정 |
| Apple Developer Team ID | Apple Developer **Membership details** | 별도 YAML 입력은 불필요하며 certificate/profile의 Team 일치 확인에 사용 | 계정 정보 |
| App Store Connect Issuer ID | Users and Access → Integrations → App Store Connect API | Codemagic `EARTRIP_ASC` integration | 보호 필요 |
| App Store Connect API Key ID | 같은 API key 화면 | Codemagic `EARTRIP_ASC` integration | 보호 필요 |
| App Store Connect `.p8` private key | API key 생성 직후 1회 다운로드 | Codemagic `EARTRIP_ASC` integration | secret, commit 금지 |
| Apple Distribution certificate/private key | Codemagic 또는 Apple Developer Certificates | Codemagic Code signing identities | secret, commit 금지 |
| App Store provisioning profile | Apple Developer Profiles 또는 Codemagic fetch | Codemagic iOS provisioning profiles | commit 금지 |
| App Store Apple ID | App Store Connect → App Information | 현재는 입력 불필요, 향후 원격 build number 조회 시 사용 | 공개 숫자 |

현재 integration 방식에서는 별도의 GitHub secret이나 Codemagic environment group이 필요하지 않습니다. 환경 변수 방식으로 전환할 경우에만 `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY` 같은 secret을 사용하고 모두 secure로 표시합니다.

### Version과 build number

- Marketing Version은 `project.yml`의 `0.1.0`입니다.
- Build Number는 Codemagic이 제공하는 양의 정수 `CM_BUILD_NUMBER`를 archive 직전에 `agvtool`로 적용합니다.
- 첫 성공 build는 예를 들어 `0.1.0 (12)` 형태로 TestFlight에 표시됩니다.
- App Store Connect는 동일 version/build 조합의 재업로드를 허용하지 않습니다. Codemagic 앱을 새로 만들거나 build counter가 기존 업로드보다 낮아졌다면 기존 최대값보다 높은 build number로 실행해야 합니다. 이후에는 App Store Apple ID를 이용해 최신 TestFlight build number + 1을 조회하는 방식으로 확장할 수 있습니다.

### Archive 설정과 iOS capability

- shared scheme: `EARTrip`
- Archive configuration: `Release`
- Bundle ID: `com.eartrip.app`
- Deployment target: iOS 17.0
- Code signing style: Xcode project는 Automatic이며, Codemagic archive 시 matching App Store profile을 주입합니다.
- 위치: `NSLocationWhenInUseUsageDescription`만 선언합니다. 현재 앱은 background location을 구현하지 않았으므로 `location` background mode와 Location Updates capability를 추가하지 않습니다.
- 오디오: `UIBackgroundModes`의 `audio`만 선언합니다. 별도 entitlement는 필요하지 않습니다.
- Push, iCloud, Sign in with Apple, Associated Domains 등 사용하지 않는 capability는 활성화하지 않습니다.

App Store Connect가 export compliance 질문을 표시하면 현재 앱이 Apple의 URLSession/TLS만 사용하고 별도 암호화 기능을 포함하지 않는지 실제 릴리스 기준으로 확인한 후 응답합니다. 이 항목은 법적 확인이므로 저장소에서 임의로 고정하지 않습니다.

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

빈 `AppIcon.appiconset`은 향후 production icon의 위치만 예약합니다. Debug simulator build에는 App Icon 이름을 강제하지 않지만 Release archive에는 `AppIcon`을 지정합니다. TestFlight workflow의 사전 검사가 실제 1024×1024 PNG와 manifest filename을 확인하므로 제출 전 production icon 추가가 필수입니다.

## 출시 전 체크리스트

- 실제 Bundle ID와 Apple Team 확정
- App Icon 및 production 사진/음원 추가
- 위치 권한 문구 현지화 및 background location 정책 검토
- 실제 도보 필드 테스트로 trigger radius/accuracy threshold 조정
- 개인정보 처리방침과 App Store privacy questionnaire 작성
- TestFlight internal testing 후 interruption, Bluetooth, 잠금 화면 검증
