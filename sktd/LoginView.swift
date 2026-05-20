import SwiftUI

struct LoginView: View {

    let onLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var isLoginEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
								Image("login_bg")
										.resizable()
										.scaledToFill()
										.ignoresSafeArea()

                VStack(spacing: 18) {

                    Spacer()

                    VStack(spacing: 14) {

                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(.black)

                            TextField("", text: $email)
                                .foregroundColor(.black)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }
                        .padding()
                        .ignoresSafeArea(.keyboard)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(16)

                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(.black)

                            if showPassword {
                                TextField("", text: $password)
                                    .foregroundColor(.black)
                            } else {
                                SecureField("", text: $password)
                                    .foregroundColor(.black)
                            }

                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.black)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(16)
                    }

                    Button(action: {
                        onLogin()
                    }) {
                        Text("ログイン")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isLoginEnabled
                                ? Color.orange.opacity(0.9)
                                : Color.gray.opacity(0.7)
                            )
                            .cornerRadius(18)
                    }
                    .disabled(!isLoginEnabled)

                    VStack(spacing: 14) {
                        NavigationLink(destination: RegisterView()) {
                            Text("アカウントを作成する 〉")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        NavigationLink(destination: CircleCreateView()) {
                            Text("サークルを作成する 〉")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 48)
                }
                .padding(.horizontal, 28)
            }
            .navigationBarHidden(true)
        }
    }
}
