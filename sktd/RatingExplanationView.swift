import SwiftUI

struct RatingExplanationView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("レーティングの計算方法")
                    .font(.largeTitle)
                    .bold()

                Text("本アプリでは、対戦相手とのレート差に応じて増減するELO方式をベースにしています。")
                    .foregroundColor(.gray)

                explanationCard(
                    title: "基本ルール",
                    text: "格上に勝つと大きく上がり、格下に勝つと少し上がります。逆に、格下に負けると大きく下がります。"
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("ポイント変動ルール")
                        .font(.headline)

                    ruleRow(title: "最低保証", value: "±5")
                    ruleRow(title: "最大変動", value: "±40")
                    ruleRow(title: "変動係数", value: "K = 64")

                    Text("どんな試合でも最低±5は変動し、1試合の最大変動は±40までに制限しています。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("具体例")
                        .font(.headline)

                    ratingExample(
                        title: "同格に勝利",
                        before: "自分 1800 vs 相手 1800",
                        result: "勝利",
                        diff: "+32",
                        color: .green
                    )

                    ratingExample(
                        title: "格上に勝利",
                        before: "自分 1500 vs 相手 2000",
                        result: "勝利",
                        diff: "+40（上限）",
                        color: .green
                    )

                    ratingExample(
                        title: "格下に勝利",
                        before: "自分 2200 vs 相手 1200",
                        result: "勝利",
                        diff: "+5（最低保証）",
                        color: .green
                    )

                    ratingExample(
                        title: "格下に敗北",
                        before: "自分 2200 vs 相手 1200",
                        result: "敗北",
                        diff: "-40（下限）",
                        color: .red
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("ダブルスの場合")
                        .font(.headline)

                    Text("ダブルスでは、チームメンバーの平均レートを使って計算します。")
                        .foregroundColor(.gray)

                    HStack {
                        VStack(spacing: 6) {
                            Text("チームA")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("1600")
                                .font(.title2)
                                .bold()
                        }

                        Spacer()

                        Text("vs")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Spacer()

                        VStack(spacing: 6) {
                            Text("チームB")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("1800")
                                .font(.title2)
                                .bold()
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(16)

                    Text("チームAが勝てば格上撃破扱いになり、上がり幅が大きくなります。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("計算方法")
    }

    func explanationCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(text)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    func ruleRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
    }

    func ratingExample(
        title: String,
        before: String,
        result: String,
        diff: String,
        color: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(before)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(result)
                    .font(.caption)
            }

            Spacer()

            Text(diff)
                .font(.title3)
                .bold()
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}
