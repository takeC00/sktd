import SwiftUI

/// サークルのメンバー・参加者管理（Mate）
struct MateCircleDetailView: View {
    let circle: Circle

    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var showAddParticipant = false
    @State private var pendingMemberDelete: CircleMembership?
    @State private var showDeleteMemberConfirm = false
    @State private var isDeletingMember = false

    private var registeredMembers: [CircleMembership] {
        authManager.currentCircleMembers.filter(\.isRegistered)
    }

    private var manualMembers: [CircleMembership] {
        authManager.currentCircleMembers.filter(\.isManual)
    }

    private var dayGuests: [CircleGuestParticipant] {
        authManager.currentCircleGuests.filter {
            DayParticipantIdentity.isDayParticipant($0.matchParticipantId)
        }
    }

    private var isEmpty: Bool {
        registeredMembers.isEmpty && manualMembers.isEmpty && dayGuests.isEmpty
    }

    var body: some View {
        Group {
            if isEmpty {
                ContentUnavailableView(
                    "参加者がいません",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("招待コードで参加するか、手動登録メンバーを追加してください")
                )
            } else {
                List {
                    if !registeredMembers.isEmpty {
                        Section {
                            ForEach(registeredMembers) { member in
                                NavigationLink {
                                    MateRegisteredMemberFormView(
                                        circle: circle,
                                        member: member
                                    )
                                } label: {
                                    memberRow(member, subtitle: roleLabel(member.role))
                                }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        if canRemoveMember(member) {
                                            Button(role: .destructive) {
                                                pendingMemberDelete = member
                                                showDeleteMemberConfirm = true
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                    }
                            }
                        } header: {
                            Text("サークルメンバー")
                        } footer: {
                            Text("Hub / Match / Mate で招待コード参加した正式メンバーです。")
                        }
                    }

                    if !manualMembers.isEmpty {
                        Section {
                            ForEach(manualMembers) { member in
                                NavigationLink {
                                    MateManualMemberFormView(
                                        circleId: circle.id,
                                        member: member,
                                        createdBy: authManager.uid ?? ""
                                    )
                                } label: {
                                    memberRow(member, subtitle: "手動追加")
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if canRemoveMember(member) {
                                        Button(role: .destructive) {
                                            pendingMemberDelete = member
                                            showDeleteMemberConfirm = true
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("サークルメンバー（手動追加）")
                        } footer: {
                            Text("アプリ未登録の常連メンバーです。レーティング・試合履歴の永続管理対象です。")
                        }
                    }

                    if !dayGuests.isEmpty {
                        Section {
                            ForEach(dayGuests) { guest in
                                NavigationLink {
                                    MateDayParticipantFormView(
                                        circleId: circle.id,
                                        guest: guest
                                    )
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(guest.name)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Text("今日だけ参加")
                                                .font(.caption2)
                                                .foregroundStyle(.blue)
                                        }
                                        Spacer()
                                        levelBadge(guest.level)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await removeGuest(guest) }
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("今日だけ参加")
                        } footer: {
                            Text("日本時間で日付が変わると消えます。Match の試合設定でも使われます。")
                        }
                    }

                }
            }
        }
        .navigationTitle(circle.name)
        .rallyDarkScreenBackground()
        .rallyDarkNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddParticipant = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .accessibilityLabel("参加者を追加")
            }
        }
        .sheet(isPresented: $showAddParticipant) {
            if let uid = authManager.uid {
                MateParticipantAddSheet(circleId: circle.id, createdBy: uid)
            }
        }
        .onChange(of: showAddParticipant) { _, isShowing in
            if !isShowing {
                authManager.fetchCurrentCircleMembers()
            }
        }
        .refreshable {
            authManager.fetchCurrentCircleMembers()
        }
        .onAppear {
            authManager.fetchCurrentCircleMembers()
        }
        .confirmationDialog(
            "メンバーを削除しますか？",
            isPresented: $showDeleteMemberConfirm,
            presenting: pendingMemberDelete
        ) { member in
            Button("削除", role: .destructive) {
                Task { await deleteMember(member) }
            }
            Button("キャンセル", role: .cancel) {
                pendingMemberDelete = nil
            }
        } message: { member in
            if member.isManual {
                Text("「\(member.userName)」を削除します。過去の試合履歴は残ります。")
            } else {
                Text("「\(member.userName)」をサークルから除外します。")
            }
        }
    }

    private func memberRow(_ member: CircleMembership, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.userName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            levelBadge(member.level)
            Text("\(member.rating)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func roleLabel(_ role: String) -> String {
        switch role {
        case "admin", "owner": "管理者"
        default: "メンバー"
        }
    }

    private func levelBadge(_ level: String?) -> some View {
        let mateLevel = MateMemberLevel.from(level)
        return Text(mateLevel.label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(levelBadgeColor(level).opacity(0.15))
            .foregroundStyle(levelColor(level))
            .clipShape(Capsule())
    }

    private func levelColor(_ level: String?) -> Color {
        MateMemberLevel.from(level) == .experienced ? .red : .blue
    }

    private func levelBadgeColor(_ level: String?) -> Color {
        MateMemberLevel.from(level) == .experienced ? .red : .blue
    }

    private func removeGuest(_ guest: CircleGuestParticipant) async {
        do {
            try await CircleMembersService.shared.removeDayParticipant(
                matchParticipantId: guest.matchParticipantId
            )
        } catch {
            // 削除失敗は次回 refresh で反映
        }
    }

    private var currentUserMembership: CircleMembership? {
        guard let uid = authManager.uid else { return nil }
        return authManager.currentCircleMembers.first { $0.userId == uid }
    }

    private var isOwnerOrAdmin: Bool {
        authManager.isCircleOwner(circle)
            || ["admin", "owner"].contains(currentUserMembership?.role ?? "")
    }

    private func canRemoveMember(_ member: CircleMembership) -> Bool {
        guard !isDeletingMember else { return false }
        if member.role == "owner" || member.userId == circle.ownerId { return false }
        if member.userId == authManager.uid { return false }
        if member.isManual { return isOwnerOrAdmin }
        if member.isRegistered { return authManager.isCircleOwner(circle) }
        return false
    }

    private func deleteMember(_ member: CircleMembership) async {
        isDeletingMember = true
        defer {
            isDeletingMember = false
            pendingMemberDelete = nil
        }

        do {
            try await CircleMembersService.shared.removeMember(member)
        } catch {
            // 削除失敗は次回 refresh で反映
        }
    }
}

// MARK: - サークルメンバー編集

struct MateRegisteredMemberFormView: View {
    @Environment(\.dismiss) private var dismiss

    let circle: Circle
    let member: CircleMembership
    var onSaved: (() -> Void)?

    @StateObject private var authManager = FirebaseAuthManager.shared

    @State private var rating = ""
    @State private var level: MateMemberLevel = .experienced
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    private var canRemove: Bool {
        guard let uid = authManager.uid else { return false }
        if member.role == "owner" || member.userId == circle.ownerId { return false }
        if member.userId == uid { return false }
        return authManager.isCircleOwner(circle)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("表示名", value: member.userName)
                TextField("レート", text: $rating)
                    .keyboardType(.numberPad)
                Picker("レベル", selection: $level) {
                    ForEach(MateMemberLevel.allCases) { lv in
                        Text(lv.label).tag(lv)
                    }
                }
                TextField("備考（任意）", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("サークルメンバー")
            } footer: {
                Text("表示名は Mate / Hub のアカウント設定で変更します。")
            }

            if canRemove {
                Section {
                    Button("メンバーを削除", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .disabled(isSaving)
                } footer: {
                    Text("サークルから除外します。過去の試合履歴は残ります。")
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("メンバー編集")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            rating = "\(member.rating)"
            level = MateMemberLevel.from(member.level)
            notes = member.notes ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .overlay {
            if isSaving { ProgressView() }
        }
        .confirmationDialog(
            "メンバーを削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                Task { await deleteMember() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("「\(member.userName)」をサークルから除外します。")
        }
        .rallyDarkFormScreen()
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let ratingValue = Int(rating) ?? member.rating

        do {
            try await CircleMembersService.shared.updateRegisteredMember(
                member,
                rating: ratingValue,
                level: level.rawValue,
                notes: notes.registeredMemberNotesValue
            )
            onSaved?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteMember() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await CircleMembersService.shared.removeMember(member)
            onSaved?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var registeredMemberNotesValue: String? {
        isEmpty ? nil : self
    }
}
