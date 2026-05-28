import SwiftUI

struct RankingView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    var rankedMembers: [CircleMembership] {
        authManager.currentCircleMembers.sorted { $0.rating > $1.rating }
    }
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(rankedMembers.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(rankColor(index: index))
                            .foregroundColor(.white)
														.clipShape(SwiftUI.Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.userName)
                                .font(.headline)

                            Text("Rating \(member.rating)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("ランキング")
            .onAppear {
                authManager.refreshCircles()
            }
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
