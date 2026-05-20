import SwiftUI

struct RatingGraphView: View {

    let values: [Int]

    var maxValue: Int {
        values.max() ?? 1500
    }

    var minValue: Int {
        values.min() ?? 1500
    }

    var upperValue: Int {
        ((maxValue + 50) / 50) * 50
    }

    var lowerValue: Int {
        max(((minValue - 50) / 50) * 50, 0)
    }

    var range: Int {
        max(upperValue - lowerValue, 1)
    }

    var scaleValues: [Int] {
        stride(from: upperValue, through: lowerValue, by: -50).map { $0 }
    }

    var latestValue: Int {
        values.last ?? 1500
    }

    var body: some View {
        GeometryReader { geometry in

            let chartWidth = geometry.size.width - 56
            let chartHeight = geometry.size.height - 40
            let leftPadding: CGFloat = 48
            let topPadding: CGFloat = 18

            ZStack {
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

                Path { path in
                    for index in values.indices {
                        let x = leftPadding + chartWidth * CGFloat(index) / CGFloat(max(values.count - 1, 1))
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

                ForEach(values.indices, id: \.self) { index in
                    let x = leftPadding + chartWidth * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let yRatio = CGFloat(values[index] - lowerValue) / CGFloat(range)
                    let y = topPadding + chartHeight * (1 - yRatio)

                    Circle()
                        .fill(Color.white)
                        .frame(width: index == values.indices.last ? 14 : 9,
                               height: index == values.indices.last ? 14 : 9)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .position(x: x, y: y)
                }

            }
        }
    }
}
