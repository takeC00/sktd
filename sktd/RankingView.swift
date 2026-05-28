import SwiftUI

struct RankingView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    var rankedMembers: [CircleMembership] {
        authManager.currentCircleMembers
    }
    var body: some View {
        NavigationStack {
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
                                .foregroundColor(.white)

                            Text("Rating \(member.rating)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white.opacity(0.06))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("ランキング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
