import SwiftUI

struct MateCircleInfoView: View {
    let circle: Circle

    @StateObject private var authManager = FirebaseAuthManager.shared

    private var memberCount: Int {
        authManager.currentCircleMembers.count
    }

    var body: some View {
        Form {
            Section {
                InviteCodeCopyRow(code: circle.circleCode)
            } header: {
                Text("招待コード")
            } footer: {
                Text("コードをタップするとコピーできます。このコードを共有すると、同じサークルに参加できます。")
            }

            Section {
                LabeledContent("名前", value: circle.name)
                LabeledContent("競技", value: circle.sportName.isEmpty ? "—" : circle.sportName)
                if !circle.description.isEmpty {
                    LabeledContent("説明", value: circle.description)
                }
                LabeledContent("メンバー数", value: "\(circle.memberIds.count) 人")
                LabeledContent("登録メンバー", value: "\(memberCount) 名")
            } header: {
                Text("サークル情報")
            } footer: {
                Text("サークルの削除は Circle タブのオーナー操作から行えます。")
            }
        }
        .navigationTitle("サークル情報")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authManager.fetchCurrentCircleMembers()
        }
        .rallyDarkFormScreen()
    }
}
