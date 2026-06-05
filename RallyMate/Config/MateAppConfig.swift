import Foundation

enum MateAppConfig {
    static var hostingBaseURL: String {
        MateFirebaseConfig.defaultHostingURL
    }

    /// 本日レート変動 QR 用 URL（`/rating/{circleId}?date=yyyy-MM-dd`）
    static func dailyRatingURL(circleId: String, dateKey: String) -> URL? {
        let dateSegment = dateKey.replacingOccurrences(of: "/", with: "-")
        return URL(string: "\(hostingBaseURL)/rating/\(circleId.lowercased())?date=\(dateSegment)")
    }

    static func dateKeyInJST(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    static func todayDateKeyInJST(now: Date = .now) -> String {
        dateKeyInJST(for: now)
    }

    static func snapshotDocumentId(circleId: String, dateKey: String) -> String {
        "\(circleId.lowercased())_\(dateKey.replacingOccurrences(of: "/", with: "-"))"
    }
}
