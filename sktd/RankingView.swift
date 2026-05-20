import SwiftUI

struct RankingView: View {

    @ObservedObject var store: AppStore
		var rankedPlayers: [Player] {
				store.currentCirclePlayers.sorted {
						store.ratingInCurrentCircle(userId: $0.id) > store.ratingInCurrentCircle(userId: $1.id)
				}
		}
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(rankColor(index: index))
                            .foregroundColor(.white)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.name)
                                .font(.headline)

                            Text("Rating \(store.ratingInCurrentCircle(userId: player.id))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("ランキング")
        }
    }

    func rankColor(index: Int) -> Color {
        switch index {
        case 0:
            return .yellow
        case 1:
            return .gray
        case 2:
            return .orange
        default:
            return .blue
        }
    }
}
