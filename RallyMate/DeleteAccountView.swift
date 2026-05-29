import SwiftUI

struct DeleteAccountView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var confirmationText = ""
    @State private var password = ""
    @State private var isDeleting = false
    @State private var message: String?

    private var canDelete: Bool {
        confirmationText == "DELETE" && !isDeleting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("この操作は元に戻せません。アカウント（Firebase Auth）を削除し、Firestore上の自分のユーザーデータと所属情報を削除します。")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Section(header: Text("再認証（必要な場合）")) {
                    SecureField("パスワード（メール/パスワードログインの場合）", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
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
                                Text("アカウントを削除する")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canDelete)
                }
            }
            .navigationTitle("アカウント削除")
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

        let pass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        authManager.deleteMyAccount(password: pass.isEmpty ? nil : pass) { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    message = "削除しました。"
                    confirmationText = ""
                    password = ""
                    dismiss()
                case .failure(let error):
                    message = error.localizedDescription
                }
            }
        }
    }
}

