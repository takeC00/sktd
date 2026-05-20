import SwiftUI

struct RatingExplanationView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("レーティングの計算方法")
                    .font(.largeTitle)
                    .bold()

                Text("このアプリでは、対戦相手とのレート差に応じて増減するELO方式を使います。")
                    .foregroundColor(.gray)

                explanationCard(
                    title: "基本ルール",
                    text: "格上に勝つと大きく上がり、格下に勝つと少し上がります。逆に、格下に負けると大きく下がります。"
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("具体例")
                        .font(.headline)

                    ratingExample(
                        title: "格上に勝利",
                        before: "自分 1500 vs 相手 1700",
                        result: "勝利",
                        diff: "+30",
                        color: .green
                    )

                    ratingExample(
                        title: "格下に勝利",
                        before: "自分 1700 vs 相手 1500",
                        result: "勝利",
                        diff: "+10",
                        color: .green
                    )

                    ratingExample(
                        title: "格下に敗北",
                        before: "自分 1700 vs 相手 1500",
                        result: "敗北",
                        diff: "-30",
                        color: .red
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("イメージ図")
                        .font(.headline)

                    HStack {
                        VStack {
                            Text("格上")
                                .font(.caption)
                            Text("1700")
                                .font(.title2)
                                .bold()
                        }

                        Spacer()

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title)

                        Spacer()

                        VStack {
                            Text("自分")
                                .font(.caption)
                            Text("1500")
                                .font(.title2)
                                .bold()
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(16)

                    Text("レート差が大きい相手に勝つほど、評価が大きく変動します。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                explanationCard(
                    title: "チーム戦の場合",
                    text: "ダブルスではチームメンバーの平均レートを使って計算します。チームA平均レートとチームB平均レートを比較します。"
                )
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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
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
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}
