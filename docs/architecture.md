# EAR TRIP: 책임과 협력

## 설계 목표

화면이 아니라 여행 세션이 행동의 기준이다. UI 재생성·화면 이동이 여행 완료나 오디오 상태를 결정하지 않게 한다.
작은 앱에 UseCase/Manager/Coordinator를 일괄 도입하지 않고, 변경 이유가 다른 경계에만 역할을 나눈다.

## 의존성 방향

    App (조립)
      ├─ Features → TripEngine / CourseCatalog / 조회용 위치·기록
      ├─ TripEngine → Models + TripLocationSource / StoryAudioPlayer + TripHistoryStore
      └─ Adapters: LocationService / AudioService → Apple frameworks

Models는 Foundation에만 의존한다. Coordinate의 Apple 좌표 변환은 Location 어댑터로 옮겼다.
TripDependencies의 두 프로토콜은 시스템 자원과 비동기 실패를 교체하기 위한 경계다.
모든 타입에 프로토콜을 만드는 대신, 값인 TriggerPolicy와 카탈로그·기록 저장소는 구체 타입으로 유지한다.

현재는 하나의 iOS target 안의 논리 모듈이다. Swift Package로 분리한 것처럼 주장하지 않는다.
CI의 scripts/check_architecture.py가 모델의 플랫폼 import, 화면의 AudioService 직접 의존,
화면의 MockCatalog 직접 사용 및 완료 기록 저장을 검사한다. 이는 간단한 텍스트 규칙이며 완전한 Swift 의존성 분석기는 아니다.
향후 별도 플랫폼/팀에서 도메인을 재사용할 때 패키지 추출을 고려한다.

## 주요 협력

### 위치 → 자동 재생

LocationService가 좌표를 전달하면 TripEngine이 StoryTriggerPolicy로 정확도와 반경을 검사한다.
엔진만 다음 이야기·완료 집합·세션 상태를 변경한다. 위치 어댑터는 여행 순서를 모른다.
기존 기준인 정확도 65m, 최대 반경 보정 20m는 유지했다.
거리 계산은 플랫폼 독립 Haversine을 사용하므로 기존 CLLocation 타원체 계산과 작은 수치 차이가 있을 수 있다.

### 화면 → 재생

화면은 TripEngine에 toggle/seek/skip을 요청한다. 엔진은 현재 이야기 ID를 확인하고 상태를 변경한다.
AudioService는 AVPlayer와 AVAudioSession만 관리하며, 여행 완료 여부를 결정하지 않는다.
실패는 엔진에서 paused + playbackError로 표현하고 재시도할 수 있다.
loadingStory 상태를 분리해 로딩 중 버튼 재진입을 막는다.
이야기 상세에서 아직 시작하지 않은 이야기의 미리 듣기는 제공하지 않는다. 다른 이야기를 표시하면서 기존 음원을 조작하지 않도록 비활성화한다.

### 완료 → 기록

엔진은 처음 start 시각과 마지막 이야기 완료 시각을 기록한다.
소요 시간은 휴식 시간을 포함한 경과 시간이며 분 미만은 버린다.
완료 즉시 TripHistoryStore에 저장하며 화면이 열릴 필요가 없다.
세션 UUID로 중복 저장을 막아 같은 코스 재방문도 별도 기록이 된다.
현재 저장소는 메모리 기반이다. 앱 재실행 후 영구 보관은 아직 지원하지 않는다.

### 다운로드

demoReady는 오프라인 준비 완료와 다른 상태다.
실제 패키지는 호출자가 제공한 전체 리소스 목록을 완료해야 ready가 된다.
시도별 디렉터리에 받아 취소·실패 시 해당 시도만 정리하며, 파일명 경로 탈출과 중복 이름은 거부한다.
서버 manifest, checksum, 이전 패키지 정리 및 재실행 시 패키지 발견은 아직 미구현이다.

### 경로와 화면 생명주기

View의 .task는 화면에 연결된 작업 수명만 소유한다.
WalkingRouteService가 반복 갱신을 수행하며, 엔진이 제공하는 좌표/다음 장소 값만 받는다.
경로 서비스는 TripEngine이나 View 구체 타입을 참조하지 않는다.

## 테스트 전략

- FakeTripLocation / FakeStoryAudio로 실제 GPS·오디오 없이 엔진 협력 검사
- 주입한 now 함수로 소요 시간 및 같은 코스 재방문 검증
- 다른 이야기의 재생 명령·지연 완료 이벤트 무시
- 로딩 중 여행 종료와 실패 후 재시도
- 정확도/반경 경계, 잘못된 정확도, 거리 계산
- 카탈로그 주입, 다운로드 취소와 잘못된 manifest
- 실제 이미지 번들 포함 여부

단위 테스트가 통과해도 전화 interruption, Bluetooth, 실외 GPS, 잠금 화면, 실제 CDN 실패는 실기기 통합 검증이 필요하다.

## 협업 가이드

- 화면 변경은 Features, 공통 시각 요소는 DesignSystem에 둔다.
- 여행 정책 수정은 TripEngine/Models와 관련 테스트를 같은 커밋에 포함한다.
- 데이터 소스 선택은 AppContainer에서 수행한다. 화면에 Mock/서버 분기를 넣지 않는다.
- 재생 명령은 TripEngine만 호출한다. AudioService를 Environment에 다시 주입하지 않는다.
- 기능 단위로 커밋하고, 날짜 prefix: 한글 설명을 사용한다. 앱 변경에서 CI를 건너뛰지 않는다.
- 인터뷰에서는 완료된 기능과 미구현 한계를 구분하고, 클래스 수보다 변경 영향과 실패 처리 근거를 설명한다.
