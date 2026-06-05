import Foundation
import FirebaseFirestore

enum CircleMemberError: LocalizedError {
    case invalidName
    case duplicateName
    case notManualMember
    case notRegisteredMember

    var errorDescription: String? {
        switch self {
        case .invalidName: "表示名を入力してください"
        case .duplicateName: "同じ名前のメンバーが既にいます"
        case .notManualMember: "手動登録メンバーのみ操作できます"
        case .notRegisteredMember: "アカウントメンバーのみ操作できます"
        }
    }
}

@MainActor
final class CircleMembersService {
    static let shared = CircleMembersService()

    private var db: Firestore { Firestore.firestore() }

    private init() {}

    static func member(from document: QueryDocumentSnapshot) -> CircleMembership? {
        let data = document.data()
        guard
            let circleId = data["circleId"] as? String,
            let role = data["role"] as? String,
            let joinedAt = data["joinedAt"] as? Timestamp
        else {
            return nil
        }

        let userName = (data["userName"] as? String)
            ?? (data["displayName"] as? String)
            ?? (data["nickname"] as? String)
            ?? ""
        guard !userName.isEmpty else { return nil }

        let userId = data["userId"] as? String
        let memberType: MemberType
        if let raw = data["memberType"] as? String {
            memberType = MemberType.fromFirestore(raw)
        } else if userId != nil {
            memberType = .registered
        } else {
            return nil
        }

        if memberType == .registered && userId == nil { return nil }
        if memberType == .manual && userId != nil { return nil }

        let isActive = data["isActive"] as? Bool ?? true
        guard isActive else { return nil }

        let rating = intValue(from: data["rating"]) ?? RatingDefaults.initialRating

        return CircleMembership(
            id: document.documentID,
            circleId: circleId,
            userId: userId,
            userName: userName,
            rating: rating,
            role: role,
            memberType: memberType,
            level: data["level"] as? String,
            notes: data["notes"] as? String,
            isActive: isActive,
            joinedAt: joinedAt.dateValue()
        )
    }

    func createManualMember(
        circleId: String,
        displayName: String,
        rating: Int = RatingDefaults.initialRating,
        level: String,
        notes: String?,
        createdBy: String
    ) async throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CircleMemberError.invalidName }

        let snapshot = try await db.collection("circleMembers")
            .whereField("circleId", isEqualTo: circleId)
            .getDocuments()

        let existing = snapshot.documents.compactMap { Self.member(from: $0) }
        if existing.contains(where: { $0.userName.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            throw CircleMemberError.duplicateName
        }

        let memberId = UUID().uuidString.lowercased()
        let documentId = "\(circleId)_\(memberId)"
        let now = Timestamp(date: .now)

        var data: [String: Any] = [
            "circleId": circleId,
            "userName": trimmed,
            "displayName": trimmed,
            "rating": rating,
            "role": "member",
            "memberType": MemberType.manual.rawValue,
            "level": level,
            "isActive": true,
            "createdBy": createdBy,
            "joinedAt": now,
            "updatedAt": now,
        ]

        if let notes, !notes.isEmpty {
            data["notes"] = notes
        }

        try await db.collection("circleMembers").document(documentId).setData(data)
        FirebaseAuthManager.shared.fetchCurrentCircleMembers()
    }

    func updateManualMember(
        _ member: CircleMembership,
        displayName: String,
        rating: Int,
        level: String,
        notes: String?
    ) async throws {
        guard member.isManual else { throw CircleMemberError.notManualMember }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CircleMemberError.invalidName }

        try await db.collection("circleMembers")
            .document(member.id)
            .updateData([
                "userName": trimmed,
                "displayName": trimmed,
                "rating": rating,
                "level": level,
                "notes": notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? NSNull(),
                "updatedAt": Timestamp(date: .now),
            ])

        FirebaseAuthManager.shared.fetchCurrentCircleMembers()
    }

    func deactivateManualMember(_ member: CircleMembership) async throws {
        guard member.isManual else { throw CircleMemberError.notManualMember }

        try await db.collection("circleMembers")
            .document(member.id)
            .updateData([
                "isActive": false,
                "updatedAt": Timestamp(date: .now),
            ])

        try await db.collection("circleRoster")
            .document(member.id)
            .delete()

        FirebaseAuthManager.shared.fetchCurrentCircleMembers()
    }

    func removeRegisteredMember(_ member: CircleMembership) async throws {
        guard member.isRegistered, let userId = member.userId else {
            throw CircleMemberError.notRegisteredMember
        }

        let circleRef = db.collection("circles").document(member.circleId)
        let memberRef = db.collection("circleMembers").document(member.id)
        let rosterRef = db.collection("circleRoster").document("\(member.circleId)_\(userId)")

        try await db.runTransaction { transaction, errorPointer in
            transaction.deleteDocument(memberRef)
            transaction.updateData([
                "memberIds": FieldValue.arrayRemove([userId]),
                "updatedAt": Timestamp(date: .now),
            ], forDocument: circleRef)
            transaction.deleteDocument(rosterRef)
            return nil
        }

        FirebaseAuthManager.shared.fetchCurrentCircleMembers()
    }

    func removeMember(_ member: CircleMembership) async throws {
        if member.isManual {
            try await deactivateManualMember(member)
        } else {
            try await removeRegisteredMember(member)
        }
    }

    func updateRegisteredMember(
        _ member: CircleMembership,
        rating: Int,
        level: String,
        notes: String?
    ) async throws {
        guard member.isRegistered else { throw CircleMemberError.notRegisteredMember }

        try await db.collection("circleMembers")
            .document(member.id)
            .updateData([
                "rating": rating,
                "level": level,
                "notes": notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? NSNull(),
                "updatedAt": Timestamp(date: .now),
            ])

        if let userId = member.userId {
            let rosterRef = db.collection("circleRoster").document("\(member.circleId)_\(userId)")
            try await rosterRef.setData([
                "level": level,
                "updatedAt": Timestamp(date: .now),
            ], merge: true)
        }

        FirebaseAuthManager.shared.fetchCurrentCircleMembers()
    }

    func addDayParticipant(
        circleId: String,
        name: String,
        level: String
    ) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CircleMemberError.invalidName }

        let participantId = UUID()
        let dateKey = Self.todayKeyInJST()
        let documentId = "\(circleId)_\(participantId.uuidString.lowercased())"

        try await db.collection("circleDayParticipants")
            .document(documentId)
            .setData([
                "circleId": circleId,
                "participantId": participantId.uuidString.lowercased(),
                "name": trimmed,
                "level": level,
                "dateKey": dateKey,
                "updatedAt": Timestamp(date: .now),
            ])

        FirebaseAuthManager.shared.fetchCurrentCircleGuests()
    }

    func removeDayParticipant(matchParticipantId: String) async throws {
        guard let parsed = DayParticipantIdentity.parse(playerId: matchParticipantId) else { return }

        let documentId = "\(parsed.circleId)_\(parsed.participantId.uuidString.lowercased())"
        try await db.collection("circleDayParticipants").document(documentId).delete()
        FirebaseAuthManager.shared.fetchCurrentCircleGuests()
    }

    func updateDayParticipant(
        circleId: String,
        participantId: UUID,
        name: String,
        level: String
    ) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CircleMemberError.invalidName }

        let dateKey = Self.todayKeyInJST()
        let documentId = "\(circleId)_\(participantId.uuidString.lowercased())"
        let documentRef = db.collection("circleDayParticipants").document(documentId)

        let snapshot = try await db.collection("circleDayParticipants")
            .whereField("circleId", isEqualTo: circleId)
            .whereField("dateKey", isEqualTo: dateKey)
            .getDocuments()

        let duplicate = snapshot.documents.contains { doc in
            doc.documentID != documentId
                && ((doc.data()["name"] as? String)?.caseInsensitiveCompare(trimmed) == .orderedSame)
        }
        if duplicate {
            throw CircleMemberError.duplicateName
        }

        try await documentRef.updateData([
            "name": trimmed,
            "level": level,
            "updatedAt": Timestamp(date: .now),
        ])

        FirebaseAuthManager.shared.fetchCurrentCircleGuests()
    }

    private static func todayKeyInJST(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: now)
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

enum MateMemberLevel: String, CaseIterable, Identifiable {
    case experienced
    case beginner

    var id: String { rawValue }

    var label: String {
        switch self {
        case .experienced: "経験者"
        case .beginner: "初心者"
        }
    }

    static func from(_ raw: String?) -> MateMemberLevel {
        MateMemberLevel(rawValue: raw ?? "") ?? .experienced
    }
}
