import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddEntry = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }
                
                BaitsView()
                    .tabItem {
                        Label("Baits", systemImage: "fish")
                    }
                
                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .accentColor(.iceBlue)
            
            HStack {
                Spacer()
                Button(action: {
                    showingAddEntry = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .padding(20)
                        .background(Circle().fill(Color.iceBlue))
                        .foregroundColor(.iceWhite)
                        .shadow(color: .silverAccent, radius: 10)
                }
                .sheet(isPresented: $showingAddEntry) {
                    AddEntryView()
                        .environmentObject(dataManager)
                }
                Spacer()
            }
            .padding(.bottom, 80) // Position above tab bar
        }
    }
}

#Preview {
    MainView()
}
