import SwiftUI
import UIKit

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var showCircleSelectSheet = false
    @State private var showDeleteConfirm = false

    @State private var inviteCode = ""
    @State private var copied = false
    @State private var isDeletingCircle = false
    @State private var deleteError = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("現在のサークル").foregroundColor(.gray)) {
                    if let current = currentCircle {
                        Button {
                            showCircleSelectSheet = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(current.name)
                                        .font(.headline)
                                        .foregroundColor(.white)

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
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))

                Section(header: Text("招待コード").foregroundColor(.gray)) {
                    if let current = currentCircle {
                        HStack {
                            Text(current.circleCode)
                                .font(.headline)
                                .foregroundColor(.white)

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
                .listRowBackground(Color.white.opacity(0.06))

                if let current = currentCircle, authManager.isCircleOwner(current) {
                    Section(header: Text("オーナー操作").foregroundColor(.gray)) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            if isDeletingCircle {
                                HStack {
                                    ProgressView()
                                    Text("削除中...")
                                }
                            } else {
                                Text("サークルを削除")
                            }
                        }
                        .disabled(isDeletingCircle)

                        if !deleteError.isEmpty {
                            Text(deleteError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }

                Section {
                    Button("サークルを作成") {
                        showCreateSheet = true
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))

                Section(header: Text("新しいサークルに参加").foregroundColor(.gray)) {
                    Button("招待コードで参加する") {
                        showJoinSheet = true
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))
            }
            .navigationTitle("サークル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
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
                        Section(header: Text("サークルを選択").foregroundColor(.gray)) {
                            ForEach(authManager.joinedCircles) { circle in
                                let isCurrent = authManager.currentCircleId == circle.id
                                Button {
                                    authManager.setCurrentCircle(circleId: circle.id) { _ in
                                        store.startListeningMatches()
                                    }
                                    inviteCode = ""
                                    copied = false
                                    showCircleSelectSheet = false
                                } label: {
                                    CircleSelectRow(
                                        name: circle.name,
                                        code: circle.circleCode,
                                        isCurrent: isCurrent
                                    )
                                }
                                .listRowBackground(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .navigationTitle("サークル切替")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.black, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .scrollContentBackground(.hidden)
                    .background(Color.black.ignoresSafeArea())
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("閉じる") {
                                showCircleSelectSheet = false
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "サークルを削除しますか？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    Task { await deleteCurrentCircle() }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                if let current = currentCircle {
                    Text("「\(current.name)」と関連データがすべて削除されます。この操作は取り消せません。")
                }
            }
            .onAppear {
                authManager.refreshCircles()
            }
        }
    }

    private func deleteCurrentCircle() async {
        guard let current = currentCircle else { return }

        isDeletingCircle = true
        deleteError = ""
        defer { isDeletingCircle = false }

        do {
            try await authManager.deleteCircle(current)
            store.stopListeningMatches()
            store.startListeningMatches()
            inviteCode = ""
            copied = false
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private var currentCircle: Circle? {
        guard let id = authManager.currentCircleId else {
            return nil
        }
        return authManager.joinedCircles.first { $0.id == id }
    }
}

private struct CircleSelectRow: View {
    let name: String
    let code: String
    let isCurrent: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundColor(.white)

                Text(code)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}
