import SwiftUI

#if DEBUG
struct DevDangerResetView: View {
    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var message: String?

    private var canDelete: Bool {
        confirmationText == "DELETE" && !isDeleting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("開発用：Firestore上のデータ（users / circles / circleMembers）を全削除します。元に戻せません。")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Section(header: Text("確認")) {
                    TextField("DELETE と入力", text: $confirmationText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                }

                if let message {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        runDelete()
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                            } else {
                                Text("DBを全削除する")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canDelete)
                }
            }
            .navigationTitle("開発用リセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func runDelete() {
        message = nil
        isDeleting = true
        authManager.devDeleteAllData { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    message = "削除しました。"
                    confirmationText = ""
                case .failure(let error):
                    message = error.localizedDescription
                }
            }
        }
    }
}
#endif

