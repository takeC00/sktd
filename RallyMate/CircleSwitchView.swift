import SwiftUI

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    @StateObject private var authManager =
        FirebaseAuthManager.shared

    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var showCircleSelectSheet = false
    @State private var showDeleteConfirm = false
    @State private var showAccountSettings = false

    @State private var isDeletingCircle = false
    @State private var deleteError = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: sectionHeader("現在のサークル")) {
                    if let current = currentCircle {
                        Button {
                            showCircleSelectSheet = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(current.name)
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    if !current.description.isEmpty {
                                        Text(current.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    if !current.sportName.isEmpty {
                                        Text(current.sportName)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
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
                .listRowBackground(CircleTabStyle.rowBackground)

                if let current = currentCircle {
                    Section(header: sectionHeader("メンバー・参加者")) {
                        NavigationLink {
                            MateCircleDetailView(circle: current)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("参加者を管理")
                                        .foregroundColor(.white)
                                    Text("\(memberSummary) 名")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        NavigationLink {
                            MateCircleInfoView(circle: current)
                        } label: {
                            Text("サークル情報")
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(CircleTabStyle.rowBackground)
                }

                Section(header: sectionHeader("新しいサークルに参加")) {
                    Button("招待コードで参加する") {
                        showJoinSheet = true
                    }
                    .foregroundColor(.white)
                }
                .listRowBackground(CircleTabStyle.rowBackground)

                if let current = currentCircle, authManager.isCircleOwner(current) {
                    Section(header: sectionHeader("オーナー操作")) {
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
                    .listRowBackground(CircleTabStyle.rowBackground)
                }
            }
            .navigationTitle("サークル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("サークルを作成")
                }
            }
            .accountToolbar(showAccountSettings: $showAccountSettings)
            .accountSettingsSheet(isPresented: $showAccountSettings)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .refreshable {
                authManager.refreshCircles()
                authManager.fetchCurrentCircleMembers()
            }
            .sheet(isPresented: $showJoinSheet) {
                NavigationStack {
                    CircleJoinView()
                }
                .rallyDarkFormScreen()
            }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    CircleCreateView()
                }
                .rallyDarkFormScreen()
            }
            .sheet(isPresented: $showCircleSelectSheet) {
                NavigationStack {
                    List {
                        Section(header: sectionHeader("サークルを選択")) {
                            ForEach(authManager.joinedCircles) { circle in
                                let isCurrent = authManager.currentCircleId == circle.id
                                Button {
                                    authManager.setCurrentCircle(circleId: circle.id) { _ in
                                        store.startListeningMatches()
                                    }
                                    showCircleSelectSheet = false
                                } label: {
                                    CircleSelectRow(
                                        name: circle.name,
                                        isCurrent: isCurrent
                                    )
                                }
                                .listRowBackground(CircleTabStyle.rowBackground)
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
                authManager.fetchCurrentCircleMembers()
            }
        }
    }

    private var memberSummary: Int {
        let members = authManager.currentCircleMembers.count
        if members > 0 { return members }
        return authManager.currentCircleGuests.count
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title).foregroundColor(.gray)
    }
}

private enum CircleTabStyle {
    static let rowBackground = Color.white.opacity(0.06)
}

private struct CircleSelectRow: View {
    let name: String
    let isCurrent: Bool

    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.white)

            Spacer()

            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}
