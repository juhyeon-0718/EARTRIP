import Foundation

enum MockCatalog {
    static let jagalchi: Course = {
        let id = JagalchiCoordinates.courseID
        let titles = [
            ("새벽 경매의 시작", "바다가 시장으로 들어오는 시간", JagalchiCoordinates.auction),
            ("시장 골목, 사람들의 하루", "목소리와 발걸음이 겹치는 곳", JagalchiCoordinates.marketAlley),
            ("생선구이 골목", "연기 속에 쌓인 오래된 식탁", JagalchiCoordinates.grilledFish),
            ("바다에서 시장까지", "한 상자가 지나온 짧고 긴 거리", JagalchiCoordinates.harbor),
            ("자갈치의 오늘", "변하면서도 남아 있는 풍경", JagalchiCoordinates.today)
        ]
        let spots = titles.enumerated().map { index, item in
            StorySpot(
                id: UUID(uuidString: String(format: "9A1A0000-0000-0000-0000-%012d", index + 101))!,
                courseID: id,
                order: index + 1,
                title: item.0,
                subtitle: item.1,
                description: "자갈치의 장소와 사람을 가까이에서 듣는 이야기입니다. 걷는 속도를 늦추고 주변의 소리와 함께 들어보세요.",
                coordinate: item.2,
                triggerRadius: 45,
                audioURL: nil,
                localAudioURL: nil,
                duration: [420, 510, 470, 540, 450][index],
                image: nil
            )
        }
        return Course(
            id: id,
            city: "부산",
            title: "자갈치 시장 골목 이야기",
            subtitle: "시장과 바다 사이, 다섯 개의 목소리",
            description: "자갈치 시장을 걸으며 시장과 바다, 그리고 이곳에서 살아온 사람들의 이야기를 듣는 오디오 여행.",
            coverImage: "HarborArtwork",
            distanceKilometers: 1.8,
            estimatedDurationMinutes: 50,
            price: 0,
            startingCoordinate: JagalchiCoordinates.auction,
            spots: spots
        )
    }()

    static let courses = [jagalchi]
    static let cities = ["부산", "서울", "경주", "전주", "제주"]
}
