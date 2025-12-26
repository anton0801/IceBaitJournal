import SwiftUI

struct JournalView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var totalEntries: Int {
        dataManager.entries.count
    }
    
    var mostEffectiveBait: String? {
        let grouped = Dictionary(grouping: dataManager.entries, by: { $0.baitName })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key
    }
    
    var lastEntry: BaitEntry? {
        dataManager.entries.sorted { $0.date > $1.date }.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("My Ice Journal")
                        .font(.largeTitle)
                        .foregroundColor(.darkIceBlue)
                    
                    CardView(title: "Total Entries", value: "\(totalEntries)")
                    CardView(title: "Most Effective Bait", value: mostEffectiveBait ?? "None")
                    
                    if let last = lastEntry {
                        CardView(title: "Last Entry", value: last.date.formatted(date: .abbreviated, time: .omitted) + " - " + last.baitName)
                    }
                }
                .padding()
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Journal")
        }
    }
}
