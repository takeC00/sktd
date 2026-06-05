import SwiftUI

/// 本日のレート変動 QR（Web 公開用スナップショットを生成）
struct MateRatingQRView: View {
    @ObservedObject var store: AppStore
    let circle: Circle

    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = FirebaseAuthManager.shared

    @State private var snapshot: DailyRatingSnapshot?
    @State private var errorMessage: String?
    @State private var isPublishing = true

    private var urlString: String {
        guard let snapshot else { return "" }
        return MateAppConfig.dailyRatingURL(
            circleId: snapshot.circleId,
            dateKey: snapshot.dateKey
        )?.absoluteString ?? ""
    }

    var body: some View {
        NavigationStack {
            Group {
                if isPublishing {
                    ProgressView("QR を準備中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "QR を生成できません",
                        systemImage: "qrcode",
                        description: Text(errorMessage)
                    )
                } else if let snapshot {
                    ScrollView {
                        VStack(spacing: 24) {
                            qrSection

                            VStack(alignment: .leading, spacing: 12) {
                                Text(snapshot.circleName)
                                    .font(.headline)
                                Text("本日のレート変動（\(snapshot.dateKey)）")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("イベント前 → イベント後の変動を、QR 生成時点の結果で公開します。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            previewList(snapshot.entries)
                        }
                        .padding()
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("レート QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                await publishSnapshot()
            }
        }
    }

    private var qrSection: some View {
        Group {
            if let qr = QRCodeGenerator.image(from: urlString), !urlString.isEmpty {
                qr
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(UIScreen.main.bounds.width - 48, 280))
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("QRを生成できません")
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func previewList(_ entries: [DailyRatingEntry]) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                MateRatingPreviewRow(
                    rank: index + 1,
                    entry: entry,
                    changeText: store.formattedRatingChange(entry.ratingChange)
                )
            }
        }
    }

    private func publishSnapshot() async {
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }

        do {
            snapshot = try await DailyRatingSnapshotService.shared.publishSnapshot(
                store: store,
                circleId: circle.id,
                circleName: circle.name,
                members: authManager.currentCircleMembers
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MateRatingPreviewRow: View {
    let rank: Int
    let entry: DailyRatingEntry
    let changeText: String

    private var changeColor: Color {
        entry.ratingChange >= 0 ? .orange : .blue
    }

    private var rankBadgeColor: Color {
        switch rank - 1 {
        case 0: .yellow
        case 1: .gray
        case 2: .orange
        default: .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(rankBadgeColor)
                .foregroundStyle(.white)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("開始 \(entry.ratingBefore)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(changeText)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(changeColor)

            Text("\(entry.ratingAfter)")
                .font(.title3)
                .monospacedDigit()
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
}
