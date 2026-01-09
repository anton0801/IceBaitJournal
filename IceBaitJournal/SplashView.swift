import SwiftUI

struct SplashView: View {
    
    @StateObject private var trackerVM = JournalTrackerVM()
    
    var body: some View {
        ZStack {
            if trackerVM.ongoingJournalStage == .setup || trackerVM.exposeAuthQuery {
                SplashScreenView()
            }
            
            if trackerVM.exposeAuthQuery {
                PushMainAppAcceptationView()
                    .environmentObject(trackerVM)
            } else {
                switch trackerVM.ongoingJournalStage {
                case .setup:
                    EmptyView()
                    
                case .running:
                    if trackerVM.journalLocation != nil {
                        IceBaitMainInterface()
                    } else {
                        ContentView()
                    }
                    
                case .obsolete:
                    ContentView()
                    
                case .disconnected:
                    NoConnectionView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))) { notice in
            if let metrics = notice.userInfo?["conversionData"] as? [String: Any] {
                trackerVM.processSetupMetrics(metrics)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))) { notice in
            if let metrics = notice.userInfo?["deeplinksData"] as? [String: Any] {
                trackerVM.processAccessMetrics(metrics)
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.5
    @State private var snowOffset: CGFloat = -UIScreen.main.bounds.height
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.deepFreeze, .frostBlue, .iceWhite]), startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
                    .blur(radius: 20)
                
                Image(isLandscape ? "background_second" : "background_main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .opacity(0.8)
                
                if isLandscape {
                    VStack {
                        HStack {
                            VStack(spacing: 0) {
                                Image("ice_bait_logo")
                                    .resizable()
                                    .frame(width: geo.size.height * 0.85, height: geo.size.height * 0.8)
                                HStack {
                                    Image("ice_loading_icon")
                                        .resizable()
                                        .frame(width: 150, height: 40)
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            Spacer()
                        }
                    }
                } else {
                    VStack {
                        Image("ice_bait_logo")
                            .resizable()
                            .frame(width: geo.size.width, height: geo.size.width)
                            .padding(.top, 42)
                        Spacer()
                    }
                }
                
                ForEach(0..<100) { i in
                    Image(systemName: "snowflake")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: CGFloat.random(in: 12...42)))
                        .offset(x: CGFloat.random(in: -200...200), y: snowOffset + CGFloat(i * 40))
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        .animation(Animation.linear(duration: Double.random(in: 6...12)).repeatForever(autoreverses: true).delay(Double(i) * 0.01), value: snowOffset)
                }
                .onAppear {
                    withAnimation {
                        snowOffset = UIScreen.main.bounds.height
                    }
                }
                
                if !isLandscape {
                    VStack {
                        Spacer()
                        HStack {
                            Image("ice_loading_icon")
                                .resizable()
                                .frame(width: 150, height: 40)
                            ProgressView()
                                .tint(.white)
                        }
                        .padding(.bottom, 82)
                    }
                }
            }
            .onAppear {
                opacity = 1.0
                scale = 1.15
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PushMainAppAcceptationView()
}

struct NoConnectionView: View {
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image(isLandscape ? "connect_problem_background_second" : "connect_problem_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                Image("connect_problem")
                    .resizable()
                    .frame(width: 300, height: 250)
                    .padding(.leading, isLandscape ? 152 : 0)
                
            }
        }
        .ignoresSafeArea()
    }
    
}

struct PushMainAppAcceptationView: View {
    
    @EnvironmentObject var viewModel: JournalTrackerVM
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image("main_push_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                
                VStack(spacing: 18) {
                    Spacer()
                    
                    texts
                    
                    Button {
                        viewModel.processAuthConfirm()
                    } label: {
                        Image("accept_push_button_main")
                            .resizable()
                            .frame(width: 350, height: 55)
                    }
                    
                    Button {
                        viewModel.processAuthBypass()
                    } label: {
                        Text("Skip")
                            .foregroundColor(.white)
                            .font(.custom("BagelFatOne-Regular", size: 14))
                    }
                    .padding(.bottom, isLandscape ? 12 : 72)
                }
                
            }
        }
        .ignoresSafeArea()
    }
    
    private var texts: some View {
        VStack(spacing: 18) {
            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                .foregroundColor(.white)
                .font(.custom("BagelFatOne-Regular", size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 42)
            
            Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
                .foregroundColor(.white)
                .font(.custom("BagelFatOne-Regular", size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 42)
        }
    }
    
}

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0
    
    let pages: [(title: String, description: String, icon: String)] = [
        ("Welcome to Ice Bait Journal", "Your ultimate winter fishing companion. Log baits, track success, and uncover patterns in the ice.", "snowflake.circle.fill"),
        ("Capture Every Detail", "Record baits, fish, conditions, and add photos for a vivid journal.", "camera.fill"),
        ("Visualize Your Success", "Interactive charts reveal top baits and trends to level up your game.", "chart.bar.fill"),
        ("Explore Chronologically", "A beautiful calendar view to relive and plan your fishing days.", "calendar"),
        ("Search & Customize", "Quickly find entries with search, filters, and dark mode for any light.", "magnifyingglass"),
        ("Ready to Dive In?", "Start building your ice fishing legacy today.", "figure.outdoor.cycle")
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.deepFreeze.opacity(0.85), .frostBlue, .iceWhite]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 32) {
                            Image(systemName: pages[index].icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .foregroundColor(.iceBlue)
                                .shadow(color: .silverAccent, radius: 12)
                                .rotationEffect(.degrees(currentPage == index ? 360 : 0))
                                .scaleEffect(currentPage == index ? 1.15 : 0.95)
                                .animation(.spring(response: 0.4, dampingFraction: 0.55), value: currentPage)
                            
                            Text(pages[index].title)
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .offset(y: currentPage == index ? 0 : 25)
                                .opacity(currentPage == index ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6), value: currentPage)
                            
                            Text(pages[index].description)
                                .font(.body)
                                .foregroundColor(.silverAccent)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .opacity(currentPage == index ? 1 : 0)
                                .animation(.easeIn(duration: 1.2).delay(0.4), value: currentPage)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 520)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                HStack(spacing: 24) {
                    if currentPage > 0 {
                        Button("Skip") {
                            onComplete()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                        .shadow(color: .iceBlue, radius: 6)
                    }
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.iceBlue)
                        .cornerRadius(30)
                        .shadow(color: .iceBlue, radius: 6)
                    } else {
                        Button("Start") {
                            onComplete()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.iceBlue)
                        .cornerRadius(30)
                        .shadow(color: .iceBlue, radius: 6)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

