import SwiftUI

struct BaitsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var baitGroups: [String: [BaitEntry]] {
        Dictionary(grouping: dataManager.entries, by: { $0.baitName })
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(baitGroups.keys.sorted(), id: \.self) { name in
                    let entries = baitGroups[name]!
                    let type = entries.first?.baitType.rawValue ?? ""
                    let count = entries.count
                    let avg = Double(entries.reduce(0) { $0 + $1.result.score }) / Double(count)
                    
                    NavigationLink(destination: BaitDetailsView(baitName: name)) {
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.headline)
                                .foregroundColor(.darkIceBlue)
                            Text("Type: \(type) | Uses: \(count) | Avg Score: \(String(format: "%.1f", avg))")
                                .font(.subheadline)
                                .foregroundColor(.silverAccent)
                        }
                    }
                }
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Baits")
        }
    }
}
