import Foundation

struct Player: Identifiable {
    let id: String
    var name: String
    var email: String
    var rating: Int
}

struct CircleMember: Identifiable {
    let id = UUID()
    let userId: String
    let circleId: String
    var rating: Int
    var role: String
}

struct CircleGroup: Identifiable {
    let id: String
    var name: String
    var ownerUserId: String
}

enum MatchType: String, CaseIterable {
    case singles = "シングルス"
    case doubles = "ダブルス"
}

struct SetScore: Identifiable {
    let id = UUID()
    var teamAScore: String
    var teamBScore: String
}

struct MatchResult: Identifiable {
    let id = UUID()
    let circleId: String
    let date: Date
    let matchType: MatchType
    let teamAPlayers: [String]
    let teamBPlayers: [String]
    let setScores: [SetScore]
    let winner: String
    let ratingDiff: Int
}

let samplePlayers: [Player] = [

    Player(
        id: "user_001",
        name: "服部",
        email: "me@example.com",
        rating: 1500
    ),

    Player(
        id: "user_002",
        name: "内田",
        email: "yamada@example.com",
        rating: 1680
    ),

    Player(
        id: "user_003",
        name: "楢村",
        email: "sato@example.com",
        rating: 1520
    ),

    Player(
        id: "user_004",
        name: "福田",
        email: "suzuki@example.com",
        rating: 1450
    ),

		Player(
        id: "user_005",
        name: "まる",
        email: "suzuki@example.com",
        rating: 1450
    ),

		Player(
        id: "user_006",
        name: "ざき",
        email: "suzuki@example.com",
        rating: 1450
    ),

		Player(
        id: "user_007",
        name: "シュンペイ",
        email: "suzuki@example.com",
        rating: 1450
    ),

		Player(
        id: "user_008",
        name: "芹ちゃん",
        email: "suzuki@example.com",
        rating: 1450
    ),
]
let sampleCircleGroups: [CircleGroup] = [
    CircleGroup(
        id: "circle_001",
        name: "サークル1",
        ownerUserId: "user_001"
    ),
    CircleGroup(
        id: "circle_002",
        name: "サークル2",
        ownerUserId: "user_001"
    )
]

let sampleCircleMembers: [CircleMember] = [
    // サークル1：1〜4
    CircleMember(userId: "user_001", circleId: "circle_001", rating: 1500, role: "admin"),
    CircleMember(userId: "user_002", circleId: "circle_001", rating: 1680, role: "member"),
    CircleMember(userId: "user_003", circleId: "circle_001", rating: 1520, role: "member"),
    CircleMember(userId: "user_004", circleId: "circle_001", rating: 1450, role: "member"),

    // サークル2：1, 5〜8
    CircleMember(userId: "user_001", circleId: "circle_002", rating: 1500, role: "admin"),
    CircleMember(userId: "user_005", circleId: "circle_002", rating: 1450, role: "member"),
    CircleMember(userId: "user_006", circleId: "circle_002", rating: 1450, role: "member"),
    CircleMember(userId: "user_007", circleId: "circle_002", rating: 1450, role: "member"),
    CircleMember(userId: "user_008", circleId: "circle_002", rating: 1450, role: "member")
]
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    return formatter.string(from: date)
}

func formatOnlyDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}
