import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = FirebaseAuthManager.shared

    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var didSave = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        Form {
            Section {
                TextField("表示名", text: $name)
                    .textInputAutocapitalization(.words)

                if let email = authManager.currentUserEmail {
                    LabeledContent("メール", value: email)
                }
            } header: {
                Text("プロフィール")
            } footer: {
                Text("表示名はサークルメンバー一覧やランキングに表示されます。RallyHub・RallyMatch と共通です。")
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if didSave {
                Section {
                    Text("保存しました")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle("アカウント")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
        .onAppear {
            name = authManager.currentUserName
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = ""
        didSave = false
        defer { isSaving = false }

        do {
            try await authManager.updateDisplayName(name)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
