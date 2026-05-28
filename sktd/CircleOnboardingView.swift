import SwiftUI

struct CircleOnboardingView: View {

    var body: some View {

        NavigationStack {

            ZStack {
                // MARK: Overlay

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.22),
                        Color.black.opacity(0.68)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 30) {

                        Spacer()
                            .frame(height: 140)

                        // MARK: アイコン

                        ZStack {

                            SwiftUI.Circle()
                                .fill(

                                    LinearGradient(
                                        colors: [
                                            Color.orange,
                                            Color.red.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(
                                    width: 120,
                                    height: 120
                                )

                            Image(
                                systemName:
                                    "person.3.fill"
                            )
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        }
                        .shadow(
                            color: .orange.opacity(0.45),
                            radius: 16
                        )

                        // MARK: タイトル

                        VStack(spacing: 12) {

                            Text("Welcome to RallyMate")
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .black
                                    )
                                )
                                .foregroundColor(.white)

                            Text(
                                "まずはサークルを作成するか\n既存サークルに参加しましょう"
                            )
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(
                                .white.opacity(0.82)
                            )
                            .lineSpacing(6)
                        }

                        // MARK: 説明カード

                        VStack(spacing: 16) {

                            onboardingCard(
                                icon: "sportscourt.fill",
                                title: "試合管理",
                                description:
                                    "試合結果・セットスコア・履歴を管理"
                            )

                            onboardingCard(
                                icon:
                                    "chart.line.uptrend.xyaxis",
                                title: "レーティング",
                                description:
                                    "ランキングとレートをリアルタイム更新"
                            )

                            onboardingCard(
                                icon: "person.2.fill",
                                title: "コミュニティ",
                                description:
                                    "仲間とサークルを共有"
                            )
                        }
                        .padding(.top, 8)

                        // MARK: ボタン群

                        VStack(spacing: 18) {

                            // MARK: 作成

                            NavigationLink {
                                CircleCreateView()
                            } label: {
                                ZStack {
                                    RoundedRectangle(
                                        cornerRadius: 22
                                    )
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.orange,
                                                Color.red.opacity(0.9)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                    HStack(spacing: 12) {
                                        Image(
                                            systemName:
                                                "plus.circle.fill"
                                        )
                                        .font(.headline)

                                        Text("サークルを作成")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                }
                                .frame(height: 60)
                                .shadow(
                                    color: .orange.opacity(0.35),
                                    radius: 12
                                )
                            }

                            // MARK: 参加

                            NavigationLink {
                                CircleJoinView()
                            } label: {
                                ZStack {
                                    RoundedRectangle(
                                        cornerRadius: 22
                                    )
                                    .fill(
                                        Color.white.opacity(0.15)
                                    )

                                    RoundedRectangle(
                                        cornerRadius: 22
                                    )
                                    .stroke(
                                        Color.white.opacity(0.22),
                                        lineWidth: 1
                                    )

                                    HStack(spacing: 12) {
                                        Image(
                                            systemName:
                                                "person.badge.plus"
                                        )
                                        .font(.headline)

                                        Text("サークルに参加")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                }
                                .frame(height: 60)
                            }
                        }
                        .padding(.top, 10)

                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.horizontal, 28)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Card

    func onboardingCard(
        icon: String,
        title: String,
        description: String
    ) -> some View {

        HStack(spacing: 16) {

            ZStack {

                SwiftUI.Circle()
                    .fill(
                        Color.orange.opacity(0.18)
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.orange)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(
                        .white.opacity(0.74)
                    )
            }

            Spacer()
        }
        .padding()
        .background(

            RoundedRectangle(
                cornerRadius: 22
            )
            .fill(
                Color.white.opacity(0.08)
            )
        )
        .overlay(

            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 1
            )
        )
    }
}
