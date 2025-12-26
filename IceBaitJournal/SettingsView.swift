import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("useMeters") var useMeters: Bool = true
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var csvURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Units: \(useMeters ? "Meters" : "Feet")", isOn: $useMeters)
                
                Button("Reset Journal") {
                    showingResetAlert = true
                }
                
                NavigationLink("Privacy Policy") {
                    Text("Your data is stored locally and never shared. This app respects your privacy.")
                        .padding()
                }
                
                NavigationLink("About App") {
                    Text("Ice Bait Journal v1.0\nDeveloped for ice fishing enthusiasts.")
                        .padding()
                }
                
//                Button("Export Journal as CSV") {
//                    csvURL = generateCSVFile()
//                    if csvURL != nil {
//                        showingExportSheet = true
//                    }
//                }
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Settings")
        }
        .alert("Reset Journal?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                dataManager.entries = []
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
  
}

