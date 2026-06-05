import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class FirebaseAuthManager:
    ObservableObject {

    static let shared =
        FirebaseAuthManager()

    @Published var currentUser:
        User?

    // 現在表示するサークル（users.currentCircleId）
    @Published var currentCircleId: String?

    // 所属しているサークル一覧（circles.memberIds に uid が含まれる）
    @Published var joinedCircles: [Circle] = []

    // 選択中サークルの所属メンバー（中間テーブル）
    @Published var currentCircleMembers: [CircleMembership] = []

    /// 今日だけ参加・旧 Visitor 等（レーティング対象外）
    @Published var currentCircleGuests: [CircleGuestParticipant] = []

    /// 後方互換
    var currentCircleVisitors: [CircleGuestParticipant] {
        currentCircleGuests
    }

    @Published var currentUserName: String = ""

    var currentUserEmail: String? {
        currentUser?.email
    }

    var uid: String? {
        currentUser?.uid
    }

    private let db =
        Firestore.firestore()

    init() {

        self.currentUser =
            Auth.auth().currentUser
    }

    // MARK: 新規登録

    func signUp(
        email: String,
        password: String,
        name: String,
        completion: @escaping (
            Result<Void, Error>
        ) -> Void
    ) {

        Auth.auth().createUser(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {

                completion(.failure(error))
                return
            }

            guard let user =
                result?.user else {

                return
            }

            self.db
                .collection("users")
                .document(user.uid)
                .setData([

                    "userId": user.uid,

                    "name": name,

                    "email": email,

                    "currentCircleId": NSNull(),

                    "createdAt":
                        Timestamp()

                ]) { error in

                    if let error = error {

                        completion(
                            .failure(error)
                        )
                        return
                    }

                    DispatchQueue.main.async {

                        self.currentUser =
                            user
                        self.currentUserName = name
                    }

                    self.refreshCircles()
                    completion(.success(()))
                }
        }
    }

    // MARK: ログイン

    func login(
        email: String,
        password: String,
        completion: @escaping (
            Result<Void, Error>
        ) -> Void
    ) {

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {

                completion(.failure(error))
                return
            }

            DispatchQueue.main.async {

                self.currentUser =
                    result?.user
            }

            self.refreshCircles()
            completion(.success(()))
        }
    }

    // MARK: 表示名更新

    func updateDisplayName(_ name: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "RallyMate",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "ログイン情報が取得できません"]
            )
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(
                domain: "RallyMate",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "表示名を入力してください"]
            )
        }

        try await db.collection("users").document(uid).updateData([
            "name": trimmed,
            "updatedAt": Timestamp()
        ])

        let memberships = try await db.collection("circleMembers")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()

        for document in memberships.documents {
            try await document.reference.updateData(["userName": trimmed])
        }

        await MainActor.run {
            self.currentUserName = trimmed
        }
    }

    // MARK: サークル削除

    func deleteCircle(_ circle: Circle) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "RallyMate",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "ログイン情報が取得できません"]
            )
        }
        guard circle.ownerId == uid else {
            throw NSError(
                domain: "RallyMate",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "サークルのオーナーのみ削除できます"]
            )
        }

        let circleId = circle.id

        try await deleteDocuments(
            in: db.collection("eventParticipants").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("eventVisitors").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("events").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("announcements").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("circleDayParticipants").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("circleRoster").whereField("circleId", isEqualTo: circleId)
        )
        try await deleteDocuments(
            in: db.collection("matches").whereField("circleId", isEqualTo: circleId)
        )

        let sessions = try await db.collection("sessions")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments()
        for document in sessions.documents {
            try await deleteSession(document.documentID)
        }

        let stableSessionId = circleId.lowercased()
        let stableRef = db.collection("sessions").document(stableSessionId)
        if (try await stableRef.getDocument()).exists {
            try await deleteSession(stableSessionId)
        }

        try await deleteDocuments(
            in: db.collection("circleMembers").whereField("circleId", isEqualTo: circleId)
        )

        try await db.collection("circles").document(circleId).delete()

        let userRef = db.collection("users").document(uid)
        let userDoc = try await userRef.getDocument()
        if userDoc.data()?["currentCircleId"] as? String == circleId {
            try await userRef.updateData([
                "currentCircleId": FieldValue.delete(),
                "updatedAt": Timestamp()
            ])
        }

        await MainActor.run {
            self.joinedCircles.removeAll { $0.id == circleId }
            if self.currentCircleId == circleId {
                self.currentCircleId = self.joinedCircles.first?.id
            }
            self.currentCircleMembers = []
        }

        refreshCircles()
    }

    private func deleteDocuments(in query: Query) async throws {
        while true {
            let snapshot = try await query.limit(to: 300).getDocuments()
            if snapshot.isEmpty { return }

            let batch = db.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }
    }

    private func deleteSession(_ sessionId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        try await deleteCollection(sessionRef.collection("matches"))
        try await deleteCollection(sessionRef.collection("sessionPlayers"))
        try await sessionRef.delete()
    }

    private func deleteCollection(_ collection: CollectionReference) async throws {
        while true {
            let snapshot = try await collection.limit(to: 300).getDocuments()
            if snapshot.isEmpty { return }

            let batch = db.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }
    }

    func isCircleOwner(_ circle: Circle) -> Bool {
        Auth.auth().currentUser?.uid == circle.ownerId
    }

    // MARK: ログアウト

    func logout() {

        do {

            try Auth.auth().signOut()

            DispatchQueue.main.async {

                self.currentUser = nil
                self.currentCircleId = nil
                self.joinedCircles = []
                self.currentCircleMembers = []
                self.currentUserName = ""
            }

        } catch {

            print(
                error.localizedDescription
            )
        }
    }

    // MARK: アカウント削除（自分）

    /// 自分のFirebase Authアカウント削除 + Firestoreの関連データ掃除（Functionsなし運用）
    /// - Note: 多くの場合 `reauthenticate` が必須です（パスワードユーザーは password を渡す）。
    func deleteMyAccount(password: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            deleteMyAccount(password: password) { result in
                continuation.resume(with: result)
            }
        }
    }

    func deleteMyAccount(
        password: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(
                .failure(
                    NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "ログイン情報が取得できません"]
                    )
                )
            )
            return
        }

        let uid = user.uid

        func reauthenticateIfNeeded(then next: @escaping () -> Void) {
            // Email/Password のみここで再認証対応（他providerは未対応）
            let providers = user.providerData.map { $0.providerID }
            let isPasswordProvider = providers.contains("password")

            guard isPasswordProvider else {
                next()
                return
            }

            guard
                let email = user.email,
                let password,
                !password.isEmpty
            else {
                completion(
                    .failure(
                        NSError(
                            domain: "",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "再認証のためパスワードが必要です"]
                        )
                    )
                )
                return
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                next()
            }
        }

        func cleanupFirestore(completion cleanupDone: @escaping (Result<Void, Error>) -> Void) {
            let group = DispatchGroup()
            var firstError: Error?

            // users/{uid}
            group.enter()
            db.collection("users")
                .document(uid)
                .delete { error in
                    if let error = error, firstError == nil {
                        firstError = error
                    }
                    group.leave()
                }

            // circleMembers where userId == uid
            group.enter()
            db.collection("circleMembers")
                .whereField("userId", isEqualTo: uid)
                .getDocuments { snapshot, error in
                    if let error = error {
                        if firstError == nil { firstError = error }
                        group.leave()
                        return
                    }

                    let batch = self.db.batch()
                    snapshot?.documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    batch.commit { error in
                        if let error = error, firstError == nil {
                            firstError = error
                        }
                        group.leave()
                    }
                }

            // circles.memberIds から uid を削除
            group.enter()
            db.collection("circles")
                .whereField("memberIds", arrayContains: uid)
                .getDocuments { snapshot, error in
                    if let error = error {
                        if firstError == nil { firstError = error }
                        group.leave()
                        return
                    }

                    let batch = self.db.batch()
                    snapshot?.documents.forEach { doc in
                        batch.updateData(
                            ["memberIds": FieldValue.arrayRemove([uid])],
                            forDocument: doc.reference
                        )
                    }
                    batch.commit { error in
                        if let error = error, firstError == nil {
                            firstError = error
                        }
                        group.leave()
                    }
                }

            group.notify(queue: .main) {
                if let firstError {
                    cleanupDone(.failure(firstError))
                } else {
                    cleanupDone(.success(()))
                }
            }
        }

        reauthenticateIfNeeded {
            cleanupFirestore { cleanupResult in
                switch cleanupResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    user.delete { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        self.logout()
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // MARK: サークル作成

    func createCircle(
        name: String,
        sportName: String,
        description: String = "",
        location: String = "",
        completion: @escaping (
            Result<String, Error>
        ) -> Void
    ) {

				guard let uid =
						Auth.auth().currentUser?.uid else {

						completion(
								.failure(
										NSError(
												domain: "",
												code: -1,
												userInfo: [
														NSLocalizedDescriptionKey:
																"ログイン情報が取得できません"
												]
										)
								)
						)

						return
				}

        let document =
            db.collection("circles")
            .document()

        let circleId =
            document.documentID

        let circleCode =
            String(circleId.prefix(6))
            .uppercased()

        let data: [String: Any] = [

            "name": name,

            "description": description,

            "sportName": sportName,

            "location": location,

            "ownerId": uid,

            "memberIds": [uid],

            "circleCode": circleCode,

            "createdAt": Timestamp()
        ]

        document.setData(data) { error in

            if let error = error {

                completion(.failure(error))
                return
            }

            self.db
                .collection("users")
                .document(uid)
                .updateData([

                    "currentCircleId": circleId
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    DispatchQueue.main.async {
                        self.currentCircleId = circleId
                    }
                    self.fetchCurrentCircleMembers()

                    self.upsertMembership(
                        circleId: circleId,
                        userId: uid,
                        role: "admin"
                    ) { _ in
                        self.refreshCircles()
                        completion(.success(circleId))
                    }
                }
        }
    }

    // MARK: サークル参加（招待コード）

    func joinCircle(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(
                .failure(
                    NSError(
                        domain: "",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "ログイン情報が取得できません"
                        ]
                    )
                )
            )
            return
        }

        let normalizedCode = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        if normalizedCode.isEmpty {
            completion(
                .failure(
                    NSError(
                        domain: "",
                        code: -2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "招待コードを入力してください"
                        ]
                    )
                )
            )
            return
        }

        db.collection("circles")
            .whereField("circleCode", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let doc = snapshot?.documents.first else {
                    completion(
                        .failure(
                            NSError(
                                domain: "",
                                code: -3,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "該当するサークルが見つかりません"
                                ]
                            )
                        )
                    )
                    return
                }

                let circleId = doc.documentID

                // circles.memberIds に追加
                self.db.collection("circles")
                    .document(circleId)
                    .updateData([
                        "memberIds": FieldValue.arrayUnion([uid])
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }

                        // users.currentCircleId を更新
                        self.db.collection("users")
                            .document(uid)
                            .updateData([
                                "currentCircleId": circleId
                            ]) { error in
                                if let error = error {
                                    completion(.failure(error))
                                    return
                                }

                                DispatchQueue.main.async {
                                    self.currentCircleId = circleId
                                    self.currentCircleMembers = []
                                }
                                self.fetchCurrentCircleMembers()

                                self.upsertMembership(
                                    circleId: circleId,
                                    userId: uid,
                                    role: "member"
                                ) { _ in
                                    self.refreshCircles()
                                    completion(.success(circleId))
                                }
                            }
                    }
            }
    }

    // MARK: サークル状態更新

    func refreshCircles() {
        fetchCurrentCircle()
        fetchJoinedCircles()
        fetchCurrentCircleMembers()
    }

    func setCurrentCircle(circleId: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let uid = currentUser?.uid else {
            completion?(
                .failure(
                    NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "ログイン情報が取得できません"]
                    )
                )
            )
            return
        }

        db.collection("users")
            .document(uid)
            .updateData(["currentCircleId": circleId]) { error in
                if let error = error {
                    completion?(.failure(error))
                    return
                }
                DispatchQueue.main.async {
                    self.currentCircleId = circleId
                    self.currentCircleMembers = []
                }
                self.fetchCurrentCircleMembers()
                completion?(.success(()))
            }
    }

    func fetchCurrentCircle() {

				guard let uid =
						currentUser?.uid else {

						return
				}

				db.collection("users")
						.document(uid)
						.getDocument { snapshot, error in

								guard let data =
										snapshot?.data() else {

										return
								}

								let currentCircleId =
										data["currentCircleId"]
										as? String

                                let name =
                                    (data["name"] as? String) ?? ""

								DispatchQueue.main.async {
                                    self.currentCircleId = currentCircleId
                                    self.currentUserName = name
								}
                                self.fetchCurrentCircleMembers()
						}
		}

    // MARK: 中間テーブル（所属メンバー）

    private func upsertMembership(
        circleId: String,
        userId: String,
        role: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("users")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let userName =
                    (snapshot?.data()?["name"] as? String) ?? "Unknown"

                let docId = "\(circleId)_\(userId)"
                let data: [String: Any] = [
                    "circleId": circleId,
                    "userId": userId,
                    "userName": userName,
                    "displayName": userName,
                    "rating": RatingDefaults.initialRating,
                    "role": role,
                    "memberType": MemberType.registered.rawValue,
                    "isActive": true,
                    "joinedAt": Timestamp(),
                    "updatedAt": Timestamp(),
                ]

                self.db.collection("circleMembers")
                    .document(docId)
                    .setData(data, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        completion(.success(()))
                    }
            }
    }

    /// 試合入力で選べる参加者 ID（メンバー + ゲスト）
    var allMatchParticipantIds: [String] {
        let memberIds = currentCircleMembers.map(\.matchParticipantId)
        let guestIds = currentCircleGuests.map(\.matchParticipantId)
        return memberIds + guestIds
    }

    func guestName(for playerId: String) -> String? {
        currentCircleGuests.first(where: { $0.matchParticipantId == playerId })?.name
    }

    func visitorName(for playerId: String) -> String? {
        guestName(for: playerId)
    }

    func fetchCurrentCircleGuests() {
        guard let circleId = currentCircleId else {
            DispatchQueue.main.async {
                self.currentCircleGuests = []
            }
            return
        }

        let group = DispatchGroup()
        var rosterGuests: [CircleGuestParticipant] = []
        var dayGuests: [CircleGuestParticipant] = []
        var eventGuests: [CircleGuestParticipant] = []

        group.enter()
        db.collection("circleRoster")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments { snapshot, _ in
                rosterGuests = snapshot?.documents.compactMap { doc in
                    Self.legacyRosterGuest(from: doc)
                } ?? []
                group.leave()
            }

        group.enter()
        db.collection("circleDayParticipants")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments { snapshot, _ in
                dayGuests = snapshot?.documents.compactMap { doc in
                    Self.dayParticipantGuest(from: doc, circleId: circleId)
                } ?? []
                group.leave()
            }

        group.enter()
        db.collection("eventVisitors")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments { snapshot, _ in
                eventGuests = snapshot?.documents.compactMap { doc in
                    Self.eventVisitorGuest(from: doc)
                } ?? []
                group.leave()
            }

        group.notify(queue: .main) {
            var seen = Set<String>()
            var merged: [CircleGuestParticipant] = []
            for guest in rosterGuests + dayGuests + eventGuests {
                guard seen.insert(guest.matchParticipantId).inserted else { continue }
                merged.append(guest)
            }
            self.currentCircleGuests = merged.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    func fetchCurrentCircleVisitors() {
        fetchCurrentCircleGuests()
    }

    private static func legacyRosterGuest(from doc: QueryDocumentSnapshot) -> CircleGuestParticipant? {
        let data = doc.data()
        guard data["userId"] == nil,
              data["circleMemberId"] == nil,
              let name = data["name"] as? String,
              !name.isEmpty else {
            return nil
        }

        let memberType = data["memberType"] as? String
        if memberType == MemberType.manual.rawValue || memberType == MemberType.registered.rawValue {
            return nil
        }

        return CircleGuestParticipant(
            matchParticipantId: VisitorIdentity.playerId(rosterDocumentId: doc.documentID),
            name: name
        )
    }

    private static func dayParticipantGuest(
        from doc: QueryDocumentSnapshot,
        circleId: String
    ) -> CircleGuestParticipant? {
        let data = doc.data()
        guard data["circleId"] as? String == circleId,
              data["dateKey"] as? String == Self.todayKeyInJST(),
              let name = data["name"] as? String,
              !name.isEmpty,
              let participantIdRaw = data["participantId"] as? String,
              let participantId = UUID(uuidString: participantIdRaw) else {
            return nil
        }

        return CircleGuestParticipant(
            matchParticipantId: DayParticipantIdentity.playerId(
                circleId: circleId,
                participantId: participantId
            ),
            name: name,
            level: data["level"] as? String
        )
    }

    private static func eventVisitorGuest(from doc: QueryDocumentSnapshot) -> CircleGuestParticipant? {
        let data = doc.data()
        guard let name = data["name"] as? String,
              !name.isEmpty else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
        guard Self.isSameDayInJST(createdAt, Date()) else { return nil }

        return CircleGuestParticipant(
            matchParticipantId: EventVisitorIdentity.playerId(visitorId: doc.documentID),
            name: name
        )
    }

    private static func todayKeyInJST(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: now)
    }

    private static func isSameDayInJST(_ lhs: Date, _ rhs: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar.isDate(lhs, inSameDayAs: rhs)
    }

    func fetchCurrentCircleMembers() {
        guard let circleId = currentCircleId else {
            DispatchQueue.main.async {
                self.currentCircleMembers = []
                self.currentCircleGuests = []
            }
            return
        }

        fetchCurrentCircleGuests()

        db.collection("circleMembers")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let members: [CircleMembership] = snapshot?.documents.compactMap {
                    CircleMembersService.member(from: $0)
                } ?? []

                DispatchQueue.main.async {
                    self.currentCircleMembers = members.sorted { $0.rating > $1.rating }
                }
            }
    }

    private func fetchJoinedCircles() {
        guard let uid = currentUser?.uid else {
            DispatchQueue.main.async {
                self.joinedCircles = []
            }
            return
        }

        db.collection("circles")
            .whereField("memberIds", arrayContains: uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let circles: [Circle] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let description = data["description"] as? String,
                        let ownerId = data["ownerId"] as? String,
                        let memberIds = data["memberIds"] as? [String],
                        let circleCode = data["circleCode"] as? String,
                        let createdAt = data["createdAt"] as? Timestamp
                    else {
                        return nil
                    }

                    let sportName =
                        (data["sportName"] as? String) ?? "バドミントン"

                    return Circle(
                        id: doc.documentID,
                        name: name,
                        description: description,
                        sportName: sportName,
                        ownerId: ownerId,
                        memberIds: memberIds,
                        circleCode: circleCode,
                        createdAt: createdAt
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.joinedCircles = circles.sorted {
                        $0.createdAt.dateValue() > $1.createdAt.dateValue()
                    }

                    if self.currentCircleId == nil {
                        self.currentCircleId = self.joinedCircles.first?.id
                        self.fetchCurrentCircleMembers()
                    }
                }
            }
    }

    // MARK: ログイン状態

    var isLoggedIn: Bool {

        currentUser != nil
    }

    private static func intValue(from value: Any?) -> Int? {
        switch value {
        case let number as Int: number
        case let number as Int64: Int(number)
        case let number as Double: Int(number)
        default: nil
        }
    }
}

#if DEBUG
extension FirebaseAuthManager {
    /// 開発用：Firestore上の主要データを全削除（破壊的）
    /// - Note: Firebase Auth のアカウント自体は削除しません。
    func devDeleteAllData(completion: @escaping (Result<Void, Error>) -> Void) {
        // 依存順に消す（参照が残っても困らない順）
        devDeleteCollection(named: "matches") { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.devDeleteCollection(named: "circleMembers") { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        self.devDeleteCollection(named: "circles") { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                self.devDeleteCollection(named: "users") { result in
                                    switch result {
                                    case .failure(let error):
                                        completion(.failure(error))
                                    case .success:
                                        DispatchQueue.main.async {
                                            self.currentCircleId = nil
                                            self.joinedCircles = []
                                            self.currentCircleMembers = []
                                        }
                                        completion(.success(()))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func devDeleteCollection(named name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let collection = db.collection(name)
        let pageSize = 200

        func deletePage() {
            collection.limit(to: pageSize).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    completion(.success(()))
                    return
                }

                let batch = collection.firestore.batch()
                docs.forEach { batch.deleteDocument($0.reference) }
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    // 次ページへ
                    deletePage()
                }
            }
        }

        deletePage()
    }
}
#endif
