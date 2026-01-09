import SwiftUI

struct DayDetailsView: View {
    let day: Date
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    var entriesForDay: [BaitEntry] {
        dataManager.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
    
    var body: some View {
        NavigationView {
            List(entriesForDay) { entry in
                VStack(alignment: .leading) {
                    Text(entry.baitName)
                        .font(.headline)
                    Text("Fish: \(entry.fishType.rawValue)")
                    Text("Result: \(entry.result.rawValue)")
                    if let photoData = entry.photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

