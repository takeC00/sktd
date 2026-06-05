import SwiftUI

struct CircleJoinView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var inviteCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    private var canJoin: Bool {
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Form {
                Section(header: Text("招待コード")) {
                    TextField("招待コード（例：ABC123）", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        join()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("参加する")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canJoin)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("サークル参加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .rallyDarkFormScreen()
    }

    private func join() {
        errorMessage = ""
        isLoading = true

        authManager.joinCircle(code: inviteCode) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

