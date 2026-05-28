import SwiftUI
import FirebaseAuth

struct LoginView: View {

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    @State private var errorMessage = ""
    @State private var isLoading = false

    var isLoginEnabled: Bool {

        !email.isEmpty
        && !password.isEmpty
        && !isLoading
    }

    var body: some View {

        NavigationView {

            ScrollViewReader { proxy in

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
                            Color.black.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // MARK: コンテンツ

                    ScrollView {

                        VStack {

                            // 初期位置調整
                            Spacer(
                                minLength:
                                    UIScreen.main.bounds.height * 0.58
                            )

                            // スクロール位置アンカー
                            Color.clear
                                .frame(height: 1)
                                .id("formAnchor")

                            VStack(spacing: 18) {

                                // MARK: メール

                                HStack(spacing: 12) {

                                    Image(systemName: "envelope")
                                        .foregroundColor(.black)

                                    TextField(
                                        "メールアドレス",
                                        text: $email
                                    )
                                    .foregroundColor(.black)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                }
                                .padding()
                                .background(
                                    Color.white.opacity(0.72)
                                )
                                .cornerRadius(18)

                                // MARK: パスワード

                                HStack(spacing: 12) {

                                    Image(systemName: "lock")
                                        .foregroundColor(.black)

                                    Group {

                                        if showPassword {

                                            TextField(
                                                "パスワード",
                                                text: $password
                                            )
                                            .foregroundColor(.black)

                                        } else {

                                            SecureField(
                                                "パスワード",
                                                text: $password
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
                                    Color.white.opacity(0.72)
                                )
                                .cornerRadius(18)

                                // MARK: エラー

																if !errorMessage.isEmpty {

																		HStack(spacing: 10) {

																				Image(systemName: "exclamationmark.triangle.fill")
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

																				RoundedRectangle(cornerRadius: 14)
																						.fill(
																								Color.black.opacity(0.45)
																						)
																		)
																		.overlay(

																				RoundedRectangle(cornerRadius: 14)
																						.stroke(
																								Color.red.opacity(0.65),
																								lineWidth: 1
																						)
																		)
																		.shadow(
																				color: .black.opacity(0.25),
																				radius: 8
																		)
																		.transition(.opacity)
																}

                                // MARK: ログイン

                                Button(action: {

                                    hideKeyboard()

                                    errorMessage = ""
                                    isLoading = true

                                    authManager.login(
                                        email: email,
                                        password: password
                                    ) { result in

                                        DispatchQueue.main.async {

                                            isLoading = false

                                            switch result {

                                            case .success:

                                                print("ログイン成功")

                                            case .failure(let error):

																								errorMessage =
																										convertFirebaseError(error)

                                                print(
                                                    error.localizedDescription
                                                )
                                            }
                                        }
                                    }

                                }) {

                                    ZStack {

                                        RoundedRectangle(
                                            cornerRadius: 20
                                        )
                                        .fill(
                                            isLoginEnabled
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
                                                        "arrow.right.circle.fill"
                                                )
                                                .font(.headline)
                                            }

                                            Text(
                                                isLoading
                                                ? "ログイン中..."
                                                : "ログイン"
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
                                .disabled(!isLoginEnabled)

                                // MARK: Links

                                VStack(spacing: 16) {

                                    NavigationLink(
                                        destination: RegisterView()
                                    ) {

                                        Text(
                                            "アカウントを作成する 〉"
                                        )
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(.horizontal, 28)

                            Spacer()
                                .frame(height: 240)
                        }
                    }
                }

                // MARK: 自動スクロール

                .onChange(of: email) { _ in

                    scrollIfNeeded(proxy: proxy)
                }

                .onChange(of: password) { _ in

                    scrollIfNeeded(proxy: proxy)
                }

                .navigationBarHidden(true)
            }
        }
    }

    // MARK: スクロール

    func scrollIfNeeded(
        proxy: ScrollViewProxy
    ) {

        if !email.isEmpty && !password.isEmpty {

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.15
            ) {

                withAnimation(
                    .easeInOut(duration: 0.35)
                ) {

                    proxy.scrollTo(
                        "formAnchor",
                        anchor: .top
                    )
                }
            }
        }
    }

		func convertFirebaseError(
				_ error: Error
		) -> String {

				guard let errorCode =
						AuthErrorCode(
								rawValue: (error as NSError).code
						) else {

						return "ログインに失敗しました"
				}

				switch errorCode {

				case .invalidEmail:
						return "メールアドレスの形式が正しくありません"

				case .wrongPassword:
						return "パスワードが違います"

				case .userNotFound:
						return "アカウントが存在しません"

				case .emailAlreadyInUse:
						return "このメールアドレスは既に使用されています"

				case .weakPassword:
						return "パスワードは6文字以上で入力してください"

				case .networkError:
						return "通信エラーが発生しました"

				case .tooManyRequests:
						return "試行回数が多すぎます。少し待ってください"

				default:
						return "ログインに失敗しました"
				}
		}
}
