import SwiftUI

struct RankBadgeView: View {

    let rank: RankTier

    var body: some View {

        ZStack {

            // 背景

            RoundedRectangle(cornerRadius: 26)
                .fill(

                    LinearGradient(
                        colors: [
                            rank.color.opacity(0.95),
                            rank.nextColor.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 光沢

            RoundedRectangle(cornerRadius: 26)
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

            // 枠線

            RoundedRectangle(cornerRadius: 26)
                .stroke(
                    Color.white.opacity(0.25),
                    lineWidth: 2
                )

            VStack(spacing: 4) {

                Text("RANK")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.85))

                Text(rank.rawValue)
                    .font(
                        .system(
                            size: 40,
                            weight: .black
                        )
                    )
                    .foregroundColor(.white)
                    .shadow(
                        color: .black.opacity(0.4),
                        radius: 4
                    )
            }
        }
        .frame(width: 130, height: 130)
        .shadow(
            color: rank.color.opacity(0.45),
            radius: 18
        )
    }
}
