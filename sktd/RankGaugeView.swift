import SwiftUI

struct RankGaugeView: View {

    let rating: Int

    var rank: String {

        switch rating {

        case 2200...:
            return "SS"

        case 2000..<2200:
            return "S"

        case 1800..<2000:
            return "A"

        case 1600..<1800:
            return "B"

        case 1400..<1600:
            return "C"

        case 1200..<1400:
            return "D"

        case 1000..<1200:
            return "E"

        default:
            return "F"
        }
    }

    var rankColor: Color {

        switch rank {

        case "SS":
            return .yellow

        case "S":
            return .orange

        case "A":
            return .pink

        case "B":
            return .purple

        case "C":
            return .blue

        case "D":
            return .green

        case "E":
            return Color(
                red: 0.55,
                green: 0.38,
                blue: 0.22
            )

        default:
            return .gray
        }
    }

    var nextRankColor: Color {

        switch rank {

        case "F":
            return Color(
                red: 0.55,
                green: 0.38,
                blue: 0.22
            )

        case "E":
            return .green

        case "D":
            return .blue

        case "C":
            return .purple

        case "B":
            return .pink

        case "A":
            return .orange

        case "S":
            return .yellow

        default:
            return .yellow
        }
    }

    var nextRankRating: Int {

        switch rating {

        case 2200...:
            return rating

        case 2000..<2200:
            return 2200

        case 1800..<2000:
            return 2000

        case 1600..<1800:
            return 1800

        case 1400..<1600:
            return 1600

        case 1200..<1400:
            return 1400

        case 1000..<1200:
            return 1200

        default:
            return 1000
        }
    }

    var currentRankBaseRating: Int {

        switch rating {

        case 2200...:
            return 2200

        case 2000..<2200:
            return 2000

        case 1800..<2000:
            return 1800

        case 1600..<1800:
            return 1600

        case 1400..<1600:
            return 1400

        case 1200..<1400:
            return 1200

        case 1000..<1200:
            return 1000

        default:
            return 800
        }
    }

    var progress: Double {

        if rating >= 2200 {
            return 1.0
        }

        let range = max(
            nextRankRating
            - currentRankBaseRating,
            1
        )

        let current =
            rating - currentRankBaseRating

        return min(
            max(
                Double(current)
                / Double(range),
                0
            ),
            1
        )
    }

    var remainingPointText: String {

        if rating >= 2200 {
            return "最高ランク到達"
        }

        return "次ランクまであと \(nextRankRating - rating)"
    }

    var body: some View {

        let badgeGradient =
            LinearGradient(
                colors: [
                    rankColor,
                    nextRankColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        VStack(spacing: 22) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(badgeGradient)

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )

                RoundedRectangle(
                    cornerRadius: 28
                )
                .stroke(
                    Color.white.opacity(0.22),
                    lineWidth: 2
                )

                VStack(spacing: 4) {

                    Text("RANK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(
                            .white.opacity(0.85)
                        )

                    Text(rank)
                        .font(
                            .system(
                                size: 44,
                                weight: .black
                            )
                        )
                        .foregroundColor(.white)
                }
            }
            .frame(width: 140, height: 140)

            VStack(spacing: 6) {

                Text("\(rating)")
                    .font(
                        .system(
                            size: 42,
                            weight: .black
                        )
                    )

                Text(remainingPointText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            GaugeArcView(
                progress: progress,
                currentColor: rankColor,
                nextColor: nextRankColor
            )
            .frame(height: 90)
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(
            color: .black.opacity(0.14),
            radius: 10
        )
    }
}
