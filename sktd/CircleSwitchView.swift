import SwiftUI

struct CircleSwitchView: View {

    @ObservedObject var store: AppStore

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("現在のサークル")) {
                    if let currentCircle = store.currentCircle {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentCircle.name)
                                .font(.headline)

                            Text(currentCircle.id)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("所属サークル")) {
                    ForEach(store.circles.filter { circle in
                        store.circleMembers.contains {
                            $0.circleId == circle.id && $0.userId == store.currentUserId
                        }
                    }) { circle in
                        Button(action: {
                            store.currentCircleId = circle.id
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(circle.name)
                                        .foregroundColor(.primary)

                                    Text(circle.id)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                if store.currentCircleId == circle.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("サークル切替")
        }
    }
}
