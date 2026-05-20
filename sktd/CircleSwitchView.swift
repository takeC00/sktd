import SwiftUI
import UIKit

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    @State private var inviteCode = ""
    @State private var copied = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("現在のサークル")) {
                    if let currentCircle = store.currentCircle {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentCircle.name)
                                .font(.headline)
														Text("競技：\(currentCircle.sportName)")
																.font(.subheadline)
																.foregroundColor(.gray)
                            Text(currentCircle.id)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("招待コード")) {
                    Button("招待コードを発行する") {
                        inviteCode = generateInviteCode()
                        copied = false
                    }

                    if !inviteCode.isEmpty {
                        HStack {
                            Text(inviteCode)
                                .font(.headline)

                            Spacer()

                            Button(copied ? "コピー済み" : "コピー") {
                                UIPasteboard.general.string = inviteCode
                                copied = true
                            }
                        }

                        Text("このコードを共有すると、同じサークルに参加できます。")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("所属サークル")) {
                    ForEach(store.circles.filter { circle in
                        store.circleMembers.contains {
                            $0.circleId == circle.id &&
                            $0.userId == store.currentUserId
                        }
                    }) { circle in
                        Button(action: {
                            store.currentCircleId = circle.id
                            inviteCode = ""
                            copied = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(circle.name)
                                        .foregroundColor(.primary)
																		Text(circle.sportName)
																				.font(.caption)
																				.foregroundColor(.gray)
                                    Text(circle.id)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                if store.currentCircleId == circle.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("サークル")
        }
    }

    func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let random = String((0..<6).map { _ in characters.randomElement()! })

        return "\(store.currentCircleId)-\(random)"
    }
}
