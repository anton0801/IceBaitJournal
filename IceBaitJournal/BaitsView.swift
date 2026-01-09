import SwiftUI

struct BaitsView: View {
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
    }
    
    var baitGroups: [String: [BaitEntry]] {
        Dictionary(grouping: filteredEntries, by: { $0.baitName })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 10) {
                    TextField("Search baits...", text: $searchText)
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
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Baits")
        }
    }
}
