import SwiftUI

/// 手動登録メンバー作成・編集（Mate）
struct MateManualMemberFormView: View {
    @Environment(\.dismiss) private var dismiss

    let circleId: String
    var member: CircleMembership?
    let createdBy: String
    var onSaved: (() -> Void)?

    @State private var displayName = ""
    @State private var rating = "1500"
    @State private var level: MateMemberLevel = .experienced
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { member != nil }

    var body: some View {
        Form {
            Section {
                TextField("表示名", text: $displayName)
                TextField("初期レート", text: $rating)
                    .keyboardType(.numberPad)
                Picker("レベル", selection: $level) {
                    ForEach(MateMemberLevel.allCases) { lv in
                        Text(lv.label).tag(lv)
                    }
                }
                TextField("備考（任意）", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("手動登録メンバー")
            } footer: {
                Text("アプリアカウントを持たない常連メンバーをサークルに永続登録します。レーティング・試合履歴の対象になります。")
            }

            if isEditing {
                Section {
                    Button("メンバーを削除", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .disabled(isSaving)
                } footer: {
                    Text("削除しても Mate の過去試合履歴は残ります。")
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(isEditing ? "手動登録編集" : "手動登録メンバー")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let member {
                displayName = member.userName
                rating = "\(member.rating)"
                level = MateMemberLevel.from(member.level)
                notes = member.notes ?? ""
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task { await save() }
                }
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
        .overlay {
            if isSaving { ProgressView() }
        }
        .confirmationDialog(
            "メンバーを削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                Task { await deleteMember() }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .rallyDarkFormScreen()
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let ratingValue = Int(rating) ?? RatingDefaults.initialRating

        do {
            if let member {
                try await CircleMembersService.shared.updateManualMember(
                    member,
                    displayName: displayName,
                    rating: ratingValue,
                    level: level.rawValue,
                    notes: notes.nilIfEmpty
                )
            } else {
                try await CircleMembersService.shared.createManualMember(
                    circleId: circleId,
                    displayName: displayName,
                    rating: ratingValue,
                    level: level.rawValue,
                    notes: notes.nilIfEmpty,
                    createdBy: createdBy
                )
            }
            onSaved?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteMember() async {
        guard let member else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await CircleMembersService.shared.deactivateManualMember(member)
            onSaved?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
