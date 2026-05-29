//
//  RegisterView.swift
//  RallyMate
//

import SwiftUI
import FirebaseAuth

struct RegisterView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    @State private var showPassword = false

    @State private var errorMessage = ""
    @State private var isLoading = false

    var isRegisterEnabled: Bool {

        !name.isEmpty
        && !email.isEmpty
        && !password.isEmpty
        && !isLoading
    }

    var body: some View {

        ZStack {

            // MARK: 背景

            Image("login_bg")
                .resizable()
                .scaledToFill()
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .clipped()
                .ignoresSafeArea()

            // MARK: Overlay

            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {

                VStack(spacing: 22) {

                    Spacer()
                        .frame(height: 240)

                    // MARK: 入力フォーム

                    VStack(spacing: 16) {

                        // MARK: 表示名

                        HStack(spacing: 12) {

                            Image(systemName: "person")
                                .foregroundColor(.black)

                            TextField(
                                "",
                                text: $name,
                                prompt:
                                    Text("表示名")
                                    .foregroundColor(
                                        Color(
																						red: 0.38,
																						green: 0.38,
																						blue: 0.40
																				)
																				.opacity(0.72)
                                    )
                            )
                            .foregroundColor(.black)
                        }
                        .padding()
                        .background(
                            Color.white.opacity(0.84)
                        )
                        .cornerRadius(18)

                        // MARK: メール

                        HStack(spacing: 12) {

                            Image(systemName: "envelope")
                                .foregroundColor(.black)

                            TextField(
                                "",
                                text: $email,
                                prompt:
                                    Text("メールアドレス")
                                    .foregroundColor(
                                        Color(
																						red: 0.38,
																						green: 0.38,
																						blue: 0.40
																				)
																				.opacity(0.72)
                                    )
                            )
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        }
                        .padding()
                        .background(
                            Color.white.opacity(0.84)
                        )
                        .cornerRadius(18)

                        // MARK: パスワード

                        HStack(spacing: 12) {

                            Image(systemName: "lock")
                                .foregroundColor(.black)

                            Group {

                                if showPassword {

                                    TextField(
                                        "",
                                        text: $password,
                                        prompt:
                                            Text("パスワード")
                                            .foregroundColor(
																								Color(
																										red: 0.38,
																										green: 0.38,
																										blue: 0.40
																								)
																								.opacity(0.72)
                                            )
                                    )
                                    .foregroundColor(.black)

                                } else {

                                    SecureField(
                                        "",
                                        text: $password,
                                        prompt:
                                            Text("パスワード")
                                            .foregroundColor(
																								Color(
																										red: 0.38,
																										green: 0.38,
																										blue: 0.40
																								)
																								.opacity(0.72)
                                            )
                                    )
                                    .foregroundColor(.black)
                                }
                            }

                            Button {

                                showPassword.toggle()

                            } label: {

                                Image(
                                    systemName:
                                        showPassword
                                        ? "eye.slash"
                                        : "eye"
                                )
                                .foregroundColor(.black)
                            }
                        }
                        .padding()
                        .background(
                            Color.white.opacity(0.84)
                        )
                        .cornerRadius(18)

                        // MARK: エラー

                        if !errorMessage.isEmpty {

                            HStack(spacing: 10) {

                                Image(
                                    systemName:
                                        "exclamationmark.triangle.fill"
                                )
                                .foregroundColor(.red)

                                Text(errorMessage)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(

                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                                .fill(
                                    Color.black.opacity(0.45)
                                )
                            )
                            .overlay(

                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                                .stroke(
                                    Color.red.opacity(0.65),
                                    lineWidth: 1
                                )
                            )
                        }

                        // MARK: 登録ボタン

                        Button(action: {

                            hideKeyboard()

                            errorMessage = ""
                            isLoading = true

                            authManager.signUp(
                                email: email,
                                password: password,
                                name: name
                            ) { result in

                                DispatchQueue.main.async {

                                    isLoading = false

                                    switch result {

                                    case .success:

                                        dismiss()

                                    case .failure(let error):

                                        errorMessage =
                                            convertFirebaseError(error)
                                    }
                                }
                            }

                        }) {

                            ZStack {

                                RoundedRectangle(
                                    cornerRadius: 20
                                )
                                .fill(
                                    isRegisterEnabled
                                    ? LinearGradient(
                                        colors: [
                                            Color.orange,
                                            Color.red.opacity(0.9)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.7),
                                            Color.gray.opacity(0.55)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                                HStack(spacing: 10) {

                                    if isLoading {

                                        ProgressView()
                                            .tint(.white)

                                    } else {

                                        Image(
                                            systemName:
                                                "person.crop.circle.badge.plus"
                                        )
                                        .font(.headline)
                                    }

                                    Text(
                                        isLoading
                                        ? "登録中..."
                                        : "アカウント作成"
                                    )
                                    .font(.headline)
                                    .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 58)
                            .shadow(
                                color: .orange.opacity(0.35),
                                radius: 10
                            )
                        }
                        .disabled(!isRegisterEnabled)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                        .frame(height: 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }

    // MARK: Firebase Error

    func convertFirebaseError(
        _ error: Error
    ) -> String {

        guard let errorCode =
            AuthErrorCode(
                rawValue: (error as NSError).code
            ) else {

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
