import SwiftUI

enum RankTier: String, CaseIterable {

    case F
    case E
    case D
    case C
    case B
    case A
    case S
    case SS

    // MARK: ランクカラー

    var color: Color {

        switch self {

        case .F:
            return Color.gray

        case .E:
            return Color(
                red: 0.55,
                green: 0.38,
                blue: 0.22
            )

        case .D:
            return Color.green

        case .C:
            return Color.blue

        case .B:
            return Color.purple

        case .A:
            return Color.pink

        case .S:
            return Color.orange

        case .SS:
            return Color.yellow
        }
    }

    // MARK: 次ランクカラー

    var nextColor: Color {

        switch self {

        case .F:
            return RankTier.E.color

        case .E:
            return RankTier.D.color

        case .D:
            return RankTier.C.color

        case .C:
            return RankTier.B.color

        case .B:
            return RankTier.A.color

        case .A:
            return RankTier.S.color

        case .S:
            return RankTier.SS.color

        case .SS:
            return RankTier.SS.color
        }
    }
}
