import SwiftUI

/// 参加者追加（手動登録 / 今日だけ参加）
struct MateParticipantAddSheet: View {
    let circleId: String
    let createdBy: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = FirebaseAuthManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        MateManualMemberFormView(
                            circleId: circleId,
                            createdBy: createdBy,
                            onSaved: { dismiss() }
                        )
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("メンバーとして追加")
                                    .font(.headline)
                                Text("手動登録メンバーを作成（常連・Androidユーザーなど）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundStyle(.orange)
                        }
                    }

                    NavigationLink {
                        MateDayParticipantFormView(circleId: circleId, onSaved: { dismiss() })
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("今日だけ参加")
                                    .font(.headline)
                                Text("その日の試合入力・人数合わせ用")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                        }
                    }
                } footer: {
                    Text("アカウントメンバーは招待コード参加で自動的に一覧に表示されます。")
                }

                let dayGuests = authManager.currentCircleGuests.filter {
                    DayParticipantIdentity.isDayParticipant($0.matchParticipantId)
                }
                if !dayGuests.isEmpty {
                    Section("今日だけ参加（\(dayGuests.count) 名）") {
                        ForEach(dayGuests) { guest in
                            NavigationLink {
                                MateDayParticipantFormView(
                                    circleId: circleId,
                                    guest: guest
                                )
                            } label: {
                                HStack {
                                    Text(guest.name)
                                    Spacer()
                                    Text(MateMemberLevel.from(guest.level).label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("参加者を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .rallyDarkFormScreen()
        }
    }
}
