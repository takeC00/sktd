import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
final class FirebaseAuthManager: ObservableObject {

    static let shared = FirebaseAuthManager()

    @Published var currentUser: FirebaseAuth.User?

    init() {

        self.currentUser = Auth.auth().currentUser
    }

    // MARK: 新規登録

    func signUp(
        email: String,
        password: String,
        name: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        Auth.auth().createUser(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {

                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                return
            }

            // Firestore保存

            let db = Firestore.firestore()

            db.collection("users")
                .document(user.uid)
                .setData([

                    "name": name,
                    "email": email,
                    "rating": 1500,
                    "createdAt": Timestamp()

                ]) { error in

                    if let error = error {

                        completion(.failure(error))
                        return
                    }

                    self.currentUser = user

                    completion(.success(()))
                }
        }
    }

    // MARK: ログイン

    func login(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {

                completion(.failure(error))
                return
            }

            self.currentUser = result?.user

            completion(.success(()))
        }
    }

    // MARK: ログアウト

    func logout() {

        do {

            try Auth.auth().signOut()

            self.currentUser = nil

        } catch {

            print(error.localizedDescription)
        }
    }

    // MARK: ログイン状態

    var isLoggedIn: Bool {

        Auth.auth().currentUser != nil
    }
}
