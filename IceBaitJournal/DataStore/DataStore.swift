import Foundation

class DataManager: ObservableObject {
    @Published var entries: [BaitEntry] = [] {
        didSet {
            save()
        }
    }
    
    init() {
        load()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "entries")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "entries"),
           let loaded = try? JSONDecoder().decode([BaitEntry].self, from: data) {
            entries = loaded
        }
    }
}
