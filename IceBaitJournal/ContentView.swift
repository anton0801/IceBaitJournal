import SwiftUI

struct ContentView: View {
    
    @StateObject private var dataManager = DataManager()
    @AppStorage("firstLaunch") private var firstLaunch = true
    @State private var showSplash = true
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                            if firstLaunch {
                                showOnboarding = true
                            }
                        }
                    }
                }
            } else if showOnboarding {
                OnboardingView {
                    firstLaunch = false
                    showOnboarding = false
                }
                .environmentObject(dataManager)
            } else {
                MainView()
                    .environmentObject(dataManager)
            }
        }
    }
    
}

#Preview {
    ContentView()
}

struct CardView: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.darkIceBlue)
            Text(value)
                .font(.title2)
                .foregroundColor(.iceBlue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.silverAccent, lineWidth: 0.5))
        .shadow(color: .silverAccent.opacity(0.3), radius: 10)
    }
}
