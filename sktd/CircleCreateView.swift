import SwiftUI

struct CircleCreateView: View {

    @State private var circleName = ""
    @State private var generatedCircleId = ""
		@State private var sportName = ""

		var isCreateEnabled: Bool {
				!circleName.isEmpty && !sportName.isEmpty
		}

    var body: some View {
        Form {
            Section(header: Text("サークル情報")) {
                TextField("サークル名", text: $circleName)
								TextField("競技名 例：バドミントン", text: $sportName)
            }

            Section {
                Button("サークルIDを発行する") {
                    generatedCircleId = generateCircleId()
                }
                .disabled(!isCreateEnabled)
            }

						if !generatedCircleId.isEmpty {
								Section(header: Text("発行されたサークルID")) {
										VStack(alignment: .leading, spacing: 12) {
												HStack {
														Text(generatedCircleId)
																.font(.title2)
																.bold()
														Spacer()
														Button(action: {
																UIPasteboard.general.string = generatedCircleId
														}) {
																Label("コピー", systemImage: "doc.on.doc")
														}
												}
												Text("このIDをメンバーに共有してください。")
														.font(.caption)
														.foregroundColor(.gray)
										}
								}
						}
        }
        .navigationTitle("サークル作成")
    }

    func generateCircleId() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let random = String((0..<5).map { _ in characters.randomElement()! })
        return "SKTD-\(random)"
    }
}
