import SwiftUI

struct RatingGraphView: View {

    let values: [Int]

    var body: some View {
        GeometryReader { geometry in

            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let range = max(maxValue - minValue, 1)

            Path { path in
                for index in values.indices {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let yRatio = CGFloat(values[index] - minValue) / CGFloat(range)
                    let y = geometry.size.height * (1 - yRatio)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 3)
        }
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}
