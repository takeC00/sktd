import SwiftUI

struct LoginView: View {

    let onLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Text("SKTD")
                    .font(.largeTitle)
                    .bold()

                TextField("メールアドレス", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                SecureField("パスワード", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                Button("ログイン") {
                    onLogin()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink(destination: RegisterView()) {
                    Text("アカウントを作成する")
                }
                
                NavigationLink(destination: CircleCreateView()) {
                    Text("サークルを作成する")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
    }
}
