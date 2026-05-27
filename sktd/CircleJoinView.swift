//
//  CircleOnboardingView.swift
//  sktd
//

import SwiftUI

struct CircleJoinView: View {

    @State private var showCreateView = false
    @State private var showJoinView = false

    var body: some View {

        NavigationStack {

            ZStack {

                // MARK: 背景

                Image("login_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height
                    )
                    .clipped()
                    .ignoresSafeArea()

                // MARK: Overlay

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 28) {

                        Spacer()
                            .frame(height: 160)

                        // MARK: アイコン

                        ZStack {

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.orange,
                                            Color.red.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "person.3.fill")
                                .font(.system(size: 48))
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
                                icon: "chart.line.uptrend.xyaxis",
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
                        .padding(.top, 12)

                        // MARK: ボタン群

                        VStack(spacing: 18) {

                            // 作成

                            Button {

                                showCreateView = true

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

                            // 参加

                            Button {

                                showJoinView = true

                            } label: {

                                ZStack {

                                    RoundedRectangle(
                                        cornerRadius: 22
                                    )
                                    .fill(
                                        Color.white.opacity(0.18)
                                    )
                                    .overlay(

                                        RoundedRectangle(
                                            cornerRadius: 22
                                        )
                                        .stroke(
                                            Color.white.opacity(0.3),
                                            lineWidth: 1
                                        )
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
                        .padding(.top, 12)

                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.horizontal, 28)
                }
            }
            .navigationBarHidden(true)

            // MARK: 遷移

            .navigationDestination(
                isPresented: $showCreateView
            ) {

                CircleCreateView()
            }

            .navigationDestination(
                isPresented: $showJoinView
            ) {

                CircleJoinView()
            }
        }
    }

    // MARK: カード

    func onboardingCard(
        icon: String,
        title: String,
        description: String
    ) -> some View {

        HStack(spacing: 16) {

            ZStack {

                Circle()
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
                        .white.opacity(0.75)
                    )
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    Color.white.opacity(0.08)
                )
        )
        .overlay(

            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}
