//
//  RegisterView.swift
//  RallyMate
//

import SwiftUI
import FirebaseAuth

struct RegisterView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var authManager = FirebaseAuthManager.shared

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    private var isRegisterEnabled: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        RallySignUpFormView(
            name: $name,
            email: $email,
            password: $password,
            showPassword: $showPassword,
            errorMessage: $errorMessage,
            isLoading: isLoading,
            isEnabled: isRegisterEnabled,
            onSubmit: signUp
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("閉じる") { dismiss() }
            }
        }
    }

    private func signUp() {
        hideKeyboard()
        errorMessage = ""
        isLoading = true

        authManager.signUp(email: email, password: password, name: name) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = convertFirebaseError(error)
                }
            }
        }
    }

    private func convertFirebaseError(_ error: Error) -> String {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return "登録に失敗しました"
        }

        switch errorCode.code {
        case .invalidEmail:
            return "メールアドレス形式が正しくありません"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .weakPassword:
            return "パスワードは6文字以上で入力してください"
        case .networkError:
            return "通信エラーが発生しました"
        case .tooManyRequests:
            return "試行回数が多すぎます"
        default:
            return "アカウント作成に失敗しました"
        }
    }
}
