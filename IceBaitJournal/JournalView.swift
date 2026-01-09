import SwiftUI

struct JournalView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var selectedFishType: FishType? = nil
    @State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    var filteredEntries: [BaitEntry] {
        dataManager.entries
            .filter { entry in
                (searchText.isEmpty || entry.baitName.lowercased().contains(searchText.lowercased()) || entry.notes.lowercased().contains(searchText.lowercased())) &&
                (selectedFishType == nil || entry.fishType == selectedFishType) &&
                entry.date >= startDate && entry.date <= endDate
            }
            .sorted { $0.date > $1.date }
    }
    
    var totalEntries: Int {
        filteredEntries.count
    }
    
    var mostEffectiveBait: String? {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.baitName })
        let averages = grouped.mapValues { entries in
            Double(entries.reduce(0) { $0 + $1.result.score }) / Double(entries.count)
        }
        return averages.max(by: { $0.value < $1.value })?.key
    }
    
    var lastEntry: BaitEntry? {
        filteredEntries.first
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 10) {
                    TextField("Search entries...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Filter by Fish", selection: $selectedFishType) {
                        Text("All").tag(FishType?.none)
                        ForEach(FishType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(FishType?.some(type))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                .padding()
                
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
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Journal")
        }
    }
}
