import SwiftUI

struct RankProgressBar: View {

    let progress: Double
    let currentRank: RankTier

    var body: some View {

        ZStack(alignment: .leading) {

            // 背景

            RoundedRectangle(cornerRadius: 14)
                .fill(
                    Color.white.opacity(0.08)
                )
                .frame(height: 24)

            // Progress

            GeometryReader { geo in

                RoundedRectangle(cornerRadius: 14)
                    .fill(

                        LinearGradient(
                            colors: [
                                currentRank.color,
                                currentRank.nextColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geo.size.width * progress,
                        height: 24
                    )
                    .shadow(
                        color: currentRank.color.opacity(0.4),
                        radius: 8
                    )
            }
            .frame(height: 24)
        }
        .frame(height: 24)
    }
}
