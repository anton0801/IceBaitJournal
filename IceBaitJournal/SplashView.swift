import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.5
    @State private var snowOffset: CGFloat = -UIScreen.main.bounds.height
    var completed: () -> Void
    
    var body: some View {
        ZStack {
            // Cold gradient background with blur for depth
            LinearGradient(gradient: Gradient(colors: [.deepFreeze, .frostBlue, .iceWhite]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            // Animated falling snowflakes for winter atmosphere
            ForEach(0..<20) { i in
                Image(systemName: "snowflake")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: CGFloat.random(in: 10...30)))
                    .offset(x: CGFloat.random(in: -150...150), y: snowOffset + CGFloat(i * 50))
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .animation(Animation.linear(duration: Double.random(in: 5...10)).repeatForever(autoreverses: false).delay(Double(i) * 0.2), value: snowOffset)
            }
            .onAppear {
                withAnimation {
                    snowOffset = UIScreen.main.bounds.height
                }
            }
            
            // Central icon: Bait with snowflake, pulsing and scaling
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "fish")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.iceBlue)
                        .scaleEffect(scale)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scale)
                    
                    Image(systemName: "snowflake.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .offset(x: 40, y: -40)
                        .opacity(opacity)
                        .animation(Animation.easeIn(duration: 1.0).delay(0.5), value: opacity)
                }
                
                // Title with frost effect and fade-in
                Text("Ice Bait Journal")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .silverAccent, radius: 5)
                    .opacity(opacity)
                    .animation(Animation.easeIn(duration: 1.5), value: opacity)
            }
            .onAppear {
                opacity = 1.0
                scale = 1.2
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    completed()
                }
            }
        }
    }
}

// Enhanced Onboarding View with more content (5 pages), beautiful visuals, animations, icons, and WOW factor
struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0
    
    let pages: [(title: String, description: String, icon: String)] = [
        ("Welcome to Ice Bait Journal", "Your personal digital notebook for winter fishing adventures. Log every detail of your ice fishing trips with ease.", "snowflake"),
        ("Log Your Baits & Catches", "Record bait types, names, and results. Track which lures shine on the ice and under what conditions they perform best.", "fish.circle"),
        ("Analyze Winter Patterns", "Discover patterns in fish behavior during cold seasons. See stats on effective baits, ice conditions, and more to refine your strategy.", "chart.bar.fill"),
        ("Build Your Fishing Insights", "Add notes on weather, depth, and activity. Over time, build a treasure trove of knowledge to boost your success on the frozen lakes.", "note.text"),
        ("Get Started & Conquer the Ice", "Start journaling today and transform your winter fishing experience. Ready to make every trip count?", "figure.outdoor.cycle")
    ]
    
    var body: some View {
        ZStack {
            // Dynamic background gradient that changes per page
            LinearGradient(gradient: Gradient(colors: [.deepFreeze.opacity(0.8), .frostBlue, .iceWhite]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            // Animated icon with rotation and scale
                            Image(systemName: pages[index].icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.iceBlue)
                                .shadow(color: .silverAccent, radius: 10)
                                .rotationEffect(.degrees(currentPage == index ? 360 : 0))
                                .scaleEffect(currentPage == index ? 1.1 : 0.9)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentPage)
                            
                            // Title with fade and slide
                            Text(pages[index].title)
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .offset(y: currentPage == index ? 0 : 20)
                                .opacity(currentPage == index ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: currentPage)
                            
                            // Description with typing effect simulation (fade in lines)
                            Text(pages[index].description)
                                .font(.body)
                                .foregroundColor(.silverAccent)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .opacity(currentPage == index ? 1 : 0)
                                .animation(.easeIn(duration: 1.0).delay(0.3), value: currentPage)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 500)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Navigation buttons with glow effect
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button("Skip") {
                            onComplete()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Capsule().fill(Color.iceBlue.opacity(0.5)))
                        .shadow(color: .iceBlue, radius: 5)
                    }
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Capsule().fill(Color.iceBlue))
                        .shadow(color: .iceBlue, radius: 5)
                    } else {
                        Button("Start") {
                            onComplete()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Capsule().fill(Color.iceBlue))
                        .shadow(color: .iceBlue, radius: 5)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

