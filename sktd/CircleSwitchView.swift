import SwiftUI
import UIKit

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    @State private var inviteCode = ""
    @State private var copied = false

    @State private var joinCode = ""
    @State private var joinMessage = ""

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

                Section(header: Text("新しいサークルに参加")) {
                    TextField("招待コードを入力", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)

                    Button("参加する") {
                        joinCircle()
                    }
                    .disabled(joinCode.isEmpty)

                    if !joinMessage.isEmpty {
                        Text(joinMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("所属サークル")) {
                    ForEach(joinedCircles) { circle in
                        Button(action: {
                            store.currentCircleId = circle.id
                            inviteCode = ""
                            copied = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(circle.name)
                                        .foregroundColor(.primary)

                                    Text("競技：\(circle.sportName)")
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

    var joinedCircles: [CircleGroup] {
        store.circles.filter { circle in
            store.circleMembers.contains {
                $0.circleId == circle.id &&
                $0.userId == store.currentUserId
            }
        }
    }

    func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let random = String((0..<6).map { _ in characters.randomElement()! })

        return "\(store.currentCircleId)-\(random)"
    }

    func joinCircle() {
        let normalizedCode = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let circleId = extractCircleId(from: normalizedCode) else {
            joinMessage = "招待コードの形式が正しくありません。"
            return
        }

        guard store.circles.contains(where: { $0.id == circleId }) else {
            joinMessage = "該当するサークルが見つかりません。"
            return
        }

        let alreadyJoined = store.circleMembers.contains {
            $0.userId == store.currentUserId &&
            $0.circleId == circleId
        }

        if alreadyJoined {
            joinMessage = "すでに参加済みのサークルです。"
            return
        }

        store.circleMembers.append(
            CircleMember(
                userId: store.currentUserId,
                circleId: circleId,
                rating: 1500,
                role: "member"
            )
        )

        store.currentCircleId = circleId
        joinCode = ""
        joinMessage = "サークルに参加しました。"
    }

    func extractCircleId(from code: String) -> String? {
        let parts = code.split(separator: "-")

        if parts.count >= 2 {
            return "\(parts[0])-\(parts[1])"
        }

        return nil
    }
}
