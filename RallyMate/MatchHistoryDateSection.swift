import SwiftUI

struct MatchHistoryDateSection: View {

    @ObservedObject var store: AppStore

    let date: String
    let histories: [MatchResult]
    let currentUserName: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            // MARK: 日付

            Text(date)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // MARK: 試合一覧

            VStack(spacing: 12) {

                ForEach(histories) { history in

                    NavigationLink {

                        MatchDetailView(
                            store: store,
                            match: history
                        )

                    } label: {

                        MatchHistoryRowView(
                            history: history,
                            store: store,
                            currentUserName: currentUserName,
                            showOnlyOpponent: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
