import SwiftUI

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var mostSuccessfulBait: String? {
        let grouped = Dictionary(grouping: dataManager.entries, by: { $0.baitName })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var mostCommonFish: String? {
        let grouped = Dictionary(grouping: dataManager.entries, by: { $0.fishType.rawValue })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key ?? "None"
    }
    
    var bestIceCondition: String? {
        let grouped = Dictionary(grouping: dataManager.entries, by: { $0.iceCondition.rawValue })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var totalFishingDays: Int {
        Set(dataManager.entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Statistics")
                        .font(.largeTitle)
                        .foregroundColor(.darkIceBlue)
                    
                    CardView(title: "Most Successful Bait", value: mostSuccessfulBait ?? "N/A")
                    CardView(title: "Most Common Fish", value: mostCommonFish ?? "N/A")
                    CardView(title: "Best Ice Conditions", value: bestIceCondition ?? "N/A")
                    CardView(title: "Total Fishing Days", value: "\(totalFishingDays)")
                }
                .padding()
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Stats")
        }
    }
}
