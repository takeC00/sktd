import SwiftUI

struct CircleCreateView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var name = ""
    @State private var sportName: String = "バドミントン"

    @State private var errorMessage = ""

    @State private var isLoading = false

		@StateObject private var authManager =
				FirebaseAuthManager.shared

    var canCreate: Bool {

        !name.isEmpty
        && !isLoading
    }

    var body: some View {
        Form {
            Section(header: Text("サークル情報")) {
                TextField("サークル名", text: $name)

                Picker("競技", selection: $sportName) {
                    Text("バドミントン").tag("バドミントン")
                    Text("卓球").tag("卓球")
                    Text("テニス").tag("テニス")
                }
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
                    isLoading = true
                    errorMessage = ""

                    authManager.createCircle(
                        name: name,
                        sportName: sportName
                    ) { result in
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
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("サークルを作成")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(!canCreate)
            }
        }
        .navigationTitle("サークル作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}
