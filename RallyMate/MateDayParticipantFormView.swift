import SwiftUI

/// 今日だけ参加の追加・編集（Mate）
struct MateDayParticipantFormView: View {
    @Environment(\.dismiss) private var dismiss

    let circleId: String
    var guest: CircleGuestParticipant?
    var onSaved: (() -> Void)?

    @State private var name = ""
    @State private var level: MateMemberLevel = .experienced
    @State private var errorMessage: String?
    @State private var isSaving = false

    private var isEditing: Bool { guest != nil }

    private var participantId: UUID? {
        guard let guest else { return nil }
        return DayParticipantIdentity.parse(playerId: guest.matchParticipantId)?.participantId
    }

    var body: some View {
        Form {
            Section {
                TextField("表示名", text: $name)
                Picker("レベル", selection: $level) {
                    ForEach(MateMemberLevel.allCases) { lv in
                        Text(lv.label).tag(lv)
                    }
                }
            } header: {
                Text("今日だけ参加")
            } footer: {
                Text("その日の試合・人数合わせ用です。日本時間で日付が変わると消えます。Match の試合設定でも選択できます。")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(isEditing ? "今日だけ参加編集" : "今日だけ参加")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let guest {
                name = guest.name
                level = MateMemberLevel.from(guest.level)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "保存" : "追加") {
                    Task { await save() }
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
        .overlay {
            if isSaving { ProgressView() }
        }
        .rallyDarkFormScreen()
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            if let guest, let participantId {
                try await CircleMembersService.shared.updateDayParticipant(
                    circleId: circleId,
                    participantId: participantId,
                    name: name,
                    level: level.rawValue
                )
            } else {
                try await CircleMembersService.shared.addDayParticipant(
                    circleId: circleId,
                    name: name,
                    level: level.rawValue
                )
            }
            onSaved?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
