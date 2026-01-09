import Foundation

struct JournalSetup {
    static let flyerCode = "6757083299"
    static let flyerDevCode = "AndVbizAewCuP5aMyGJfBg"
}

enum BaitType: String, Codable, CaseIterable {
    case jig = "Jig"
    case spoon = "Spoon"
    case balancer = "Balancer"
    case liveBait = "Live Bait"
}

struct StoredLocationUseCase {
    func activate() -> URL? {
        let programStore = ProgramStateStoreImpl()
        return programStore.fetchArchivedLocation()
    }
}

enum JournalFault: Error {
    case locationComposeFail
    case replyCheckFail
    case detailsDecodeFail
    case dataEncodeFail
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
    var photoData: Data?
}

protocol ProgramStateStore {
    var isFreshStart: Bool { get }
    func fetchArchivedLocation() -> URL?
    func archiveLocation(_ url: String)
    func defineProgramStatus(_ status: String)
    func markStartCompleted()
    func fetchProgramStatus() -> String?
}

class ProgramStateStoreImpl: ProgramStateStore {
    private let prefs = UserDefaults.standard
    
    var isFreshStart: Bool {
        !prefs.bool(forKey: "startedBefore")
    }
    
    func fetchArchivedLocation() -> URL? {
        if let str = prefs.string(forKey: "archived_location"), let url = URL(string: str) {
            return url
        }
        return nil
    }
    
    func archiveLocation(_ url: String) {
        prefs.set(url, forKey: "archived_location")
    }
    
    func defineProgramStatus(_ status: String) {
        prefs.set(status, forKey: "program_status")
    }
    
    func markStartCompleted() {
        prefs.set(true, forKey: "startedBefore")
    }
    
    func fetchProgramStatus() -> String? {
        prefs.string(forKey: "program_status")
    }
}

protocol AuthStateStore {
    func defineLastAuthQuery(_ date: Date)
    func confirmAuth(_ confirmed: Bool)
    func rejectAuth(_ rejected: Bool)
    func isAuthConfirmed() -> Bool
    func isAuthRejected() -> Bool
    func fetchLastAuthQuery() -> Date?
}

class AuthStateStoreImpl: AuthStateStore {
    private let prefs = UserDefaults.standard
    
    func defineLastAuthQuery(_ date: Date) {
        prefs.set(date, forKey: "auth_query_time")
    }
    
    func confirmAuth(_ confirmed: Bool) {
        prefs.set(confirmed, forKey: "auth_confirmed")
    }
    
    func rejectAuth(_ rejected: Bool) {
        prefs.set(rejected, forKey: "auth_rejected")
    }
    
    func isAuthConfirmed() -> Bool {
        prefs.bool(forKey: "auth_confirmed")
    }
    
    func isAuthRejected() -> Bool {
        prefs.bool(forKey: "auth_rejected")
    }
    
    func fetchLastAuthQuery() -> Date? {
        prefs.object(forKey: "auth_query_time") as? Date
    }
}
