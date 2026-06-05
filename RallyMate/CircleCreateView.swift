import SwiftUI

struct CircleCreateView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var name = ""
    @State private var sportName = RallySportOptions.defaultSport
    @State private var description = ""
    @State private var location = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    @StateObject private var authManager = FirebaseAuthManager.shared

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        RallyCircleCreateFormView(
            name: $name,
            sportName: $sportName,
            description: $description,
            location: $location,
            errorMessage: $errorMessage,
            isLoading: isLoading,
            isEnabled: canCreate,
            onSubmit: create
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("閉じる") { dismiss() }
            }
        }
    }

    private func create() {
        isLoading = true
        errorMessage = ""

        authManager.createCircle(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sportName: sportName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
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
    }
}
