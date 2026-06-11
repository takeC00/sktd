import SwiftUI

struct SplashView: View {

    @Binding var isPresented: Bool

    @State private var opacity: Double = 1

    private let displayDuration: TimeInterval = 2.0
    private let fadeDuration: TimeInterval = 1.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("splash_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .opacity(opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                    isPresented = false
                }
            }
        }
    }
}

struct RootView: View {

    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}
