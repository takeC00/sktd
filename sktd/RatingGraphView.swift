import SwiftUI

struct RatingGraphView: View {

    let values: [Int]

    private var plotIndices: [Int] {
        Array(0..<values.count)
    }

    // 軸用の値計算
    private var maxValue: Int {
        values.max() ?? RatingDefaults.initialRating
    }

    private var minValue: Int {
        values.min() ?? RatingDefaults.initialRating
    }

    private var upperValue: Int {
        ((maxValue + 50) / 50) * 50
    }

    private var lowerValue: Int {
        max(((minValue - 50) / 50) * 50, 0)
    }

    private var range: Int {
        max(upperValue - lowerValue, 1)
    }

    private var scaleValues: [Int] {
        Array(stride(from: upperValue, through: lowerValue, by: -50))
    }

    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width - 56
            let chartHeight = geometry.size.height - 40
            let leftPadding: CGFloat = 48
            let topPadding: CGFloat = 18

            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.10),
                                Color.gray.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 横グリッド & Y軸ラベル
                ForEach(scaleValues, id: \.self) { value in
                    let yRatio = CGFloat(value - lowerValue) / CGFloat(range)
                    let y = topPadding + chartHeight * (1 - yRatio)

                    Path { path in
                        path.move(to: CGPoint(x: leftPadding, y: y))
                        path.addLine(to: CGPoint(x: leftPadding + chartWidth, y: y))
                    }
                    .stroke(Color.gray.opacity(0.22), lineWidth: 1)

                    Text("\(value)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .position(x: 24, y: y)
                }

                // 折れ線
                Path { path in
                    let count = values.count
                    let denom = CGFloat(max(count - 1, 1))

                    for index in 0..<count {
                        let xRatio = CGFloat(index) / denom
                        let x = leftPadding + chartWidth * xRatio

                        let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                        let y = topPadding + chartHeight * (1 - yRatio)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    Color.blue,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // プロット点
                let count = values.count
                let denom = CGFloat(max(count - 1, 1))

                // ForEach を使わずに Path のループで描画（型推論エラー回避）
                Path { path in
                    for index in plotIndices {
                        let xRatio = CGFloat(index) / denom
                        let x = leftPadding + chartWidth * xRatio

                        let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                        let y = topPadding + chartHeight * (1 - yRatio)

                        let size: CGFloat = (index == count - 1) ? 14 : 9
                        let rect = CGRect(
                            x: x - size / 2,
                            y: y - size / 2,
                            width: size,
                            height: size
                        )
                        path.addEllipse(in: rect)
                    }
                }
                .fill(Color.white)

                Path { path in
                    for index in plotIndices {
                        let xRatio = CGFloat(index) / denom
                        let x = leftPadding + chartWidth * xRatio

                        let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                        let y = topPadding + chartHeight * (1 - yRatio)

                        let size: CGFloat = (index == count - 1) ? 14 : 9
                        let rect = CGRect(
                            x: x - size / 2,
                            y: y - size / 2,
                            width: size,
                            height: size
                        )
                        path.addEllipse(in: rect)
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
            }
        }
    }
}
