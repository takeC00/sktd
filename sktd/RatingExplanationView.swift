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
                    Text("通常戦のポイント変動")
                        .font(.headline)

                    ruleRow(title: "変動係数", value: "K = 32")
                    ruleRow(title: "最低保証", value: "±5")
                    ruleRow(title: "最大変動", value: "±25")
                    ruleRow(title: "最低レート", value: "800")

                    Text("どんな試合でも最低±5は変動し、1試合の最大変動は±25までに制限しています。")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("通常戦では、約100以上レートが高い相手に勝つと、上限の+25に到達しやすくなります。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("イベント戦のポイント変動")
                        .font(.headline)

                    ruleRow(title: "変動係数", value: "K = 40")
                    ruleRow(title: "最低保証", value: "±8")
                    ruleRow(title: "最大変動", value: "±32")

                    Text("イベント戦では通常戦より少し大きく変動します。")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("イベント戦では、約100以上レートが高い相手に勝つと、上限の+32に到達しやすくなります。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.orange.opacity(0.08))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("上限に到達する目安")
                        .font(.headline)

                    explanationCard(
                        title: "約100差が目安",
                        text: "相手の方が自分より約100以上レートが高い場合に勝利すると、通常戦では+25、イベント戦では+32の上限に届きやすくなります。"
                    )

                    ratingExample(
                        title: "通常戦：100差の格上に勝利",
                        before: "自分 1500 vs 相手 1600",
                        result: "勝利",
                        diff: "+25（上限）",
                        color: .green
                    )

                    ratingExample(
                        title: "イベント戦：100差の格上に勝利",
                        before: "自分 1500 vs 相手 1600",
                        result: "勝利",
                        diff: "+32（上限）",
                        color: .green
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("初級者保護")
                        .font(.headline)

                    ruleRow(title: "Fランク敗北", value: "減少量 50% OFF")
                    ruleRow(title: "Eランク敗北", value: "減少量 30% OFF")

                    Text("低ランク帯では敗北時の減少量を軽減します。勝利時の上昇量は通常通りです。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("ランク")
                        .font(.headline)

                    rankRow(rank: "SS", range: "2200以上")
                    rankRow(rank: "S", range: "2000〜2199")
                    rankRow(rank: "A", range: "1800〜1999")
                    rankRow(rank: "B", range: "1600〜1799")
                    rankRow(rank: "C", range: "1400〜1599")
                    rankRow(rank: "D", range: "1200〜1399")
                    rankRow(rank: "E", range: "1000〜1199")
                    rankRow(rank: "F", range: "999以下")
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
                        diff: "+16",
                        color: .green
                    )

                    ratingExample(
                        title: "格上に勝利",
                        before: "自分 1500 vs 相手 2000",
                        result: "勝利",
                        diff: "+25（上限）",
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
                        diff: "-25（下限）",
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

    func rankRow(rank: String, range: String) -> some View {
        HStack {
            Text(rank)
                .bold()
                .frame(width: 44, alignment: .leading)

            Text(range)
                .foregroundColor(.gray)

            Spacer()
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
