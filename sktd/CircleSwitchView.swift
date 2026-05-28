import SwiftUI
import UIKit

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var showCircleSelectSheet = false

    @State private var inviteCode = ""
    @State private var copied = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("現在のサークル")) {
                    if let current = currentCircle {
                        Button {
                            showCircleSelectSheet = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(current.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(current.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Text("ID: \(current.id)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                    } else {
                        Button {
                            showCircleSelectSheet = true
                        } label: {
                            HStack {
                                Text("サークルを選択する")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                    }
                }

                Section(header: Text("招待コード")) {
                    if let current = currentCircle {
                        HStack {
                            Text(current.circleCode)
                                .font(.headline)

                            Spacer()

                            Button(copied ? "コピー済み" : "コピー") {
                                UIPasteboard.general.string = current.circleCode
                                copied = true
                            }
                        }

                        Text("このコードを共有すると、同じサークルに参加できます。")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("サークルを選択すると招待コードが表示されます")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button("サークルを作成") {
                        showCreateSheet = true
                    }
                }

                Section(header: Text("新しいサークルに参加")) {
                    Button("招待コードで参加する") {
                        showJoinSheet = true
                    }
                }
            }
            .navigationTitle("サークル")
            .sheet(isPresented: $showJoinSheet) {
                NavigationStack {
                    CircleJoinView()
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    CircleCreateView()
                }
            }
            .sheet(isPresented: $showCircleSelectSheet) {
                NavigationStack {
                    List {
                        Section(header: Text("サークルを選択")) {
                            ForEach(authManager.joinedCircles) { circle in
                                Button {
                                    authManager.setCurrentCircle(circleId: circle.id) { _ in
                                        store.loadMatches()
                                    }
                                    inviteCode = ""
                                    copied = false
                                    showCircleSelectSheet = false
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(circle.name)
                                                .foregroundColor(.primary)
                                            Text(circle.circleCode)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if authManager.currentCircleId == circle.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("サークル切替")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("閉じる") {
                                showCircleSelectSheet = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                authManager.refreshCircles()
            }
        }
    }

    private var currentCircle: Circle? {
        guard let id = authManager.currentCircleId else {
            return nil
        }
        return authManager.joinedCircles.first { $0.id == id }
    }
}
