import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFishType: FishType? = nil
    @State private var selectedIceCondition: IceCondition? = nil
    @State private var selectedBait: String? = nil  // For tappable bar
    @State private var selectedMonth: Date? = nil  // For line chart tap
    
    var filteredEntries: [BaitEntry] {
        dataManager.entries
            .filter { entry in
                (selectedFishType == nil || entry.fishType == selectedFishType) &&
                (selectedIceCondition == nil || entry.iceCondition == selectedIceCondition)
            }
    }
    
    var mostSuccessfulBait: String? {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.baitName })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var mostCommonFish: String? {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.fishType.rawValue })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key ?? "None"
    }
    
    var bestIceCondition: String? {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.iceCondition.rawValue })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var totalFishingDays: Int {
        Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    
    // Bait Success Data for Bar Chart
    struct BaitSuccess: Identifiable {
        let id = UUID()
        let name: String
        let score: Double
    }
    
    var baitSuccessData: [BaitSuccess] {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.baitName })
        return grouped.map { (key: $0.key, value: Double($0.value.reduce(0) { $0 + $1.result.score }) / Double($0.value.count)) }
            .map { BaitSuccess(name: $0.0, score: $0.1) }
            .sorted { $0.score > $1.score }
    }
    
    // Activity Over Months for Line Chart
    struct MonthlyActivity: Identifiable {
        let id = UUID()
        let month: Date
        let count: Int
    }
    
    var monthlyActivityData: [MonthlyActivity] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
        }
        return grouped.map { MonthlyActivity(month: $0.key, count: $0.value.count) }
            .sorted { $0.month < $1.month }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Statistics")
                        .font(.largeTitle)
                        .foregroundColor(Color.darkIceBlue)
                    
                    HStack {
                        Picker("Fish Type", selection: $selectedFishType) {
                            Text("All").tag(FishType?.none)
                            ForEach(FishType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(FishType?.some(type))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Picker("Ice Condition", selection: $selectedIceCondition) {
                            Text("All").tag(IceCondition?.none)
                            ForEach(IceCondition.allCases, id: \.self) { cond in
                                Text(cond.rawValue).tag(IceCondition?.some(cond))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    
                    CardView(title: "Most Successful Bait", value: mostSuccessfulBait ?? "N/A")
                    CardView(title: "Most Common Fish", value: mostCommonFish ?? "N/A")
                    CardView(title: "Best Ice Conditions", value: bestIceCondition ?? "N/A")
                    CardView(title: "Total Fishing Days", value: "\(totalFishingDays)")
                    
                    if #available(iOS 16.0, *) {
                        // Bar Chart for Bait Success
                        Chart(baitSuccessData) { item in
                            BarMark(
                                x: .value("Bait", item.name),
                                y: .value("Avg Score", item.score)
                            )
                            .foregroundStyle(Color.iceBlue)
                            
                            if let selected = selectedBait, selected == item.name {
                                RectangleMark(
                                    x: .value("Bait", item.name),
                                    yStart: .value("Score", 0),
                                    yEnd: .value("Score", item.score)
                                )
                                .foregroundStyle(Color.silverAccent.opacity(0.4))
                                
//                                RuleMark(
//                                    x: .value("Bait", item.name),
//                                    y: .value("Score", item.score)
//                                )
//                                .annotation(position: .top) {
//                                    Text(String(format: "%.1f", item.score))
//                                        .font(.caption)
//                                        .padding(4)
//                                        .background(.ultraThinMaterial)
//                                        .cornerRadius(4)
//                                }
                            }
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .onTapGesture { location in
                                        let x = location.x - geometry[proxy.plotAreaFrame].origin.x
                                        if let name: String = proxy.value(atX: x) {
                                            selectedBait = (selectedBait == name) ? nil : name
                                        }
                                    }
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        Chart(monthlyActivityData) { item in
                            LineMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Entries", item.count)
                            )
                            .foregroundStyle(Color.iceBlue)
                            
                            if let selected = selectedMonth, Calendar.current.isDate(selected, equalTo: item.month, toGranularity: .month) {
                                RectangleMark(
                                    x: .value("Month", item.month, unit: .month),
                                    yStart: .value("Entries", 0),
                                    yEnd: .value("Entries", item.count)
                                )
                                .foregroundStyle(Color.silverAccent.opacity(0.4))
                                
//                                RuleMark(
//                                    x: .value("Month", item.month, unit: .month),
//                                    y: .value("Entries", item.count)
//                                )
//                                .annotation(position: .top) {
//                                    Text("\(item.count)")
//                                        .font(.caption)
//                                        .padding(4)
//                                        .background(.ultraThinMaterial)
//                                        .cornerRadius(4)
//                                }
                            }
                        }
                        
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .onTapGesture { location in
                                        let x = location.x - geometry[proxy.plotAreaFrame].origin.x
                                        if let month: Date = proxy.value(atX: x) {
                                            selectedMonth = (selectedMonth == month) ? nil : month
                                        }
                                    }
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    } else {
                        // Fallback
                        VStack {
                            Text("Bait Success (Fallback)")
                            ForEach(baitSuccessData) { item in
                                Text("\(item.name): \(String(format: "%.1f", item.score))")
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        VStack {
                            Text("Monthly Activity (Fallback)")
                            ForEach(monthlyActivityData) { item in
                                Text("\(item.month.formatted(.dateTime.month().year())): \(item.count)")
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    
                }
                .padding()
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color.iceWhite, Color.lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Stats")
        }
    }
}
