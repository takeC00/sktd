import SwiftUI

struct GaugeArcView: View {

    let progress: Double

    let currentColor: Color
    let nextColor: Color

    var body: some View {

        GeometryReader { geo in

            let width =
                geo.size.width

            let height =
                geo.size.height

            let lineWidth: CGFloat = 24

            let radius = min(
                width * 0.42,
                height * 1.15
            )

            let center = CGPoint(
                x: width / 2,
                y: height * 1.05
            )

            let progressGradient =
                LinearGradient(
                    colors: [
                        currentColor,
                        nextColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

            ZStack {

                Path { path in

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(205),
                        endAngle: .degrees(335),
                        clockwise: false
                    )
                }
                .stroke(
                    Color.gray.opacity(0.18),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )

                Path { path in

                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(205),
                        endAngle: .degrees(
                            205 + 130 * progress
                        ),
                        clockwise: false
                    )
                }
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
            }
        }
    }
}
