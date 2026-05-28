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

    @Published var currentUserName: String = ""

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

                    "name": name,

                    "email": email,

                    "rating": 1500,

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

    // MARK: サークル作成

    func createCircle(
        name: String,
        sportName: String,
        description: String = "",
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
                    "rating": 1500,
                    "role": role,
                    "joinedAt": Timestamp()
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

    func fetchCurrentCircleMembers() {
        guard let circleId = currentCircleId else {
            DispatchQueue.main.async {
                self.currentCircleMembers = []
            }
            return
        }

        db.collection("circleMembers")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let members: [CircleMembership] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let circleId = data["circleId"] as? String,
                        let userId = data["userId"] as? String,
                        let userName = data["userName"] as? String,
                        let rating = data["rating"] as? Int,
                        let role = data["role"] as? String,
                        let joinedAt = data["joinedAt"] as? Timestamp
                    else {
                        return nil
                    }

                    return CircleMembership(
                        id: doc.documentID,
                        circleId: circleId,
                        userId: userId,
                        userName: userName,
                        rating: rating,
                        role: role,
                        joinedAt: joinedAt.dateValue()
                    )
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
                    }
                }
            }
    }

    // MARK: ログイン状態

    var isLoggedIn: Bool {

        currentUser != nil
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
