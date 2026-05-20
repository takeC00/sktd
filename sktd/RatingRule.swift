import Foundation

struct RatingRule {

    let kFactor: Double
    let minimumChange: Int
    let maximumChange: Int
    let minimumRating: Int

    let eRankProtectionMultiplier: Double
    let fRankProtectionMultiplier: Double

    let ssRankBorder: Int
    let sRankBorder: Int
    let aRankBorder: Int
    let bRankBorder: Int
    let cRankBorder: Int
    let dRankBorder: Int
    let eRankBorder: Int

    static let normal = RatingRule(
        kFactor: 32,
        minimumChange: 5,
        maximumChange: 25,
        minimumRating: 800,
        eRankProtectionMultiplier: 0.7,
        fRankProtectionMultiplier: 0.5,
        ssRankBorder: 2200,
        sRankBorder: 2000,
        aRankBorder: 1800,
        bRankBorder: 1600,
        cRankBorder: 1400,
        dRankBorder: 1200,
        eRankBorder: 1000
    )

    static let event = RatingRule(
        kFactor: 40,
        minimumChange: 8,
        maximumChange: 32,
        minimumRating: 800,
        eRankProtectionMultiplier: 0.7,
        fRankProtectionMultiplier: 0.5,
        ssRankBorder: 2200,
        sRankBorder: 2000,
        aRankBorder: 1800,
        bRankBorder: 1600,
        cRankBorder: 1400,
        dRankBorder: 1200,
        eRankBorder: 1000
    )
}

func rankName(for rating: Int, rule: RatingRule = .normal) -> String {
    switch rating {
    case rule.ssRankBorder...:
        return "SS"
    case rule.sRankBorder..<rule.ssRankBorder:
        return "S"
    case rule.aRankBorder..<rule.sRankBorder:
        return "A"
    case rule.bRankBorder..<rule.aRankBorder:
        return "B"
    case rule.cRankBorder..<rule.bRankBorder:
        return "C"
    case rule.dRankBorder..<rule.cRankBorder:
        return "D"
    case rule.eRankBorder..<rule.dRankBorder:
        return "E"
    default:
        return "F"
    }
}
