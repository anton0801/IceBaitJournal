import Foundation

enum BaitType: String, Codable, CaseIterable {
    case jig = "Jig"
    case spoon = "Spoon"
    case balancer = "Balancer"
    case liveBait = "Live Bait"
}

enum FishType: String, Codable, CaseIterable {
    case perch = "Perch"
    case pike = "Pike"
    case zander = "Zander"
    case roach = "Roach"
}

enum Result: String, Codable, CaseIterable {
    case noBites = "No Bites"
    case fewBites = "Few Bites"
    case goodBites = "Good Bites"
    
    var score: Int {
        switch self {
        case .noBites: return 0
        case .fewBites: return 1
        case .goodBites: return 2
        }
    }
}

enum IceCondition: String, Codable, CaseIterable {
    case thin = "Thin Ice"
    case normal = "Normal"
    case thick = "Thick Ice"
}

struct BaitEntry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var baitType: BaitType
    var baitName: String
    var fishType: FishType
    var result: Result
    var iceCondition: IceCondition
    var depth: Double?
    var notes: String
}
