import Foundation
import FirebaseFirestore

struct Circle: Identifiable {

    var id: String

    var name: String

    var description: String

    var sportName: String

    var ownerId: String

    var memberIds: [String]

    var circleCode: String

    var createdAt: Timestamp
}
