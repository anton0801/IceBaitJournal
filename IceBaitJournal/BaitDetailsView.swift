import SwiftUI

struct BaitDetailsView: View {
    @EnvironmentObject var dataManager: DataManager
    let baitName: String
    
    var entries: [BaitEntry] {
        dataManager.entries.filter { $0.baitName == baitName }
    }
    
    var type: String {
        entries.first?.baitType.rawValue ?? ""
    }
    
    var totalUses: Int {
        entries.count
    }
    
    var bestResult: String {
        entries.max(by: { $0.result.score < $1.result.score })?.result.rawValue ?? ""
    }
    
    var fishCaught: String {
        Array(Set(entries.map { $0.fishType.rawValue })).joined(separator: ", ")
    }
    
    var photos: [UIImage] {
        entries.compactMap { entry in
            if let data = entry.photoData {
                return UIImage(data: data)
            }
            return nil
        }
    }
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(baitName)
                    .font(.largeTitle)
                    .foregroundColor(.darkIceBlue)
                
                CardView(title: "Type", value: type)
                CardView(title: "Total Uses", value: "\(totalUses)")
                CardView(title: "Best Result", value: bestResult)
                CardView(title: "Fish Caught", value: fishCaught)
                
                if !photos.isEmpty {
                    Text("Photos")
                        .font(.headline)
                        .foregroundColor(.darkIceBlue)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photos, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
        .navigationTitle("Bait Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .alert("Delete this bait and all its entries?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataManager.entries.removeAll { $0.baitName == baitName }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
