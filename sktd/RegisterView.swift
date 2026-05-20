//
//  RegisterView.swift
//  sktd
//
//  Created by 服部剛士 on 2026/05/20.
//

import SwiftUI

struct RegisterView: View {

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
		@State private var circleId = ""

		var isRegisterEnabled: Bool {
				!name.isEmpty && !email.isEmpty && !password.isEmpty && !circleId.isEmpty
		}

    var body: some View {
        Form {
            Section(header: Text("ユーザー情報")) {
                TextField("表示名", text: $name)
                TextField("メールアドレス", text: $email)
                SecureField("パスワード", text: $password)

								TextField("サークルID", text: $circleId)
									.textInputAutocapitalization(.characters)
									.autocorrectionDisabled(true)
            }



            Section {
                Button("登録する") {
                    print("登録")
                }
            }
        }
        .navigationTitle("新規登録")
    }
}
