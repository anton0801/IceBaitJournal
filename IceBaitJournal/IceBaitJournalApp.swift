import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

@main
struct IceBaitJournalApp: App {
    
    @UIApplicationDelegateAdaptor(BaitJournalEntry.self) var baitJournalEntry
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct BaitAlertParser {
    func parse(details: [AnyHashable: Any]) -> String? {
        var extractedUri: String?
        if let uri = details["url"] as? String {
            extractedUri = uri
        } else if let embeddedDetails = details["data"] as? [String: Any],
                  let embeddedUri = embeddedDetails["url"] as? String {
            extractedUri = embeddedUri
        }
        if let validUri = extractedUri {
            return validUri
        }
        return nil
    }
}


struct LocationComposer {
    private var appCode = ""
    private var devCode = ""
    private var deviceCode = ""
    private let rootLink = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    
    func defineAppCode(_ code: String) -> Self { copy(appCode: code) }
    func defineDevCode(_ code: String) -> Self { copy(devCode: code) }
    func defineDeviceCode(_ code: String) -> Self { copy(deviceCode: code) }
    
    func compose() -> URL? {
        guard !appCode.isEmpty, !devCode.isEmpty, !deviceCode.isEmpty else { return nil }
        var parts = URLComponents(string: rootLink + "id" + appCode)!
        parts.queryItems = [
            URLQueryItem(name: "devkey", value: devCode),
            URLQueryItem(name: "device_id", value: deviceCode)
        ]
        return parts.url
    }
    
    private func copy(appCode: String = "", devCode: String = "", deviceCode: String = "") -> Self {
        var duplicate = self
        if !appCode.isEmpty { duplicate.appCode = appCode }
        if !devCode.isEmpty { duplicate.devCode = devCode }
        if !deviceCode.isEmpty { duplicate.deviceCode = deviceCode }
        return duplicate
    }
}

class BaitJournalEntry: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var journalMetrics: [AnyHashable: Any] = [:]
    private var journalAccesses: [AnyHashable: Any] = [:]
    private let metricsDispatchedFlag = "metricsDispatched"
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        initializeHandlers()
        UIApplication.shared.registerForRemoteNotifications()
        manageStartupAlerts(launchOptions: launchOptions)
        initializeTracker()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(commenceMetrics),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        return true
    }
    
    private var journalClock: Timer?
    
    private func initializeHandlers() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    @objc private func commenceMetrics() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }
    
    func didResolveDeepLink(_ outcome: DeepLinkResult) {
        guard case .found = outcome.status,
              let accessObject = outcome.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: metricsDispatchedFlag) else { return }
        
        journalAccesses = accessObject.clickEvent
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": journalAccesses])
        journalClock?.invalidate()
        
        if !journalMetrics.isEmpty {
            dispatchCombinedMetrics()
        }
    }
    
    
    private func initializeTracker() {
        AppsFlyerLib.shared().appsFlyerDevKey = JournalSetup.flyerDevCode
        AppsFlyerLib.shared().appleAppID = JournalSetup.flyerCode
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        interpretAlert(userInfo)
        completionHandler(.newData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { [weak self] code, fault in
            guard fault == nil, let validCode = code else { return }
            self?.refreshCode(validCode)
        }
    }
    
    private func refreshCode(_ code: String) {
        UserDefaults.standard.set(code, forKey: "fcm_code")
        UserDefaults.standard.set(code, forKey: "alert_code")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        interpretAlert(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func onConversionDataFail(_ fault: Error) {
        dispatchMetrics(metrics: [:])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payloadDetails = notification.request.content.userInfo
        interpretAlert(payloadDetails)
        completionHandler([.banner, .sound])
    }
    
    func onConversionDataSuccess(_ metrics: [AnyHashable: Any]) {
        journalMetrics = metrics
        initiateCombineClock()
        if !journalAccesses.isEmpty {
            dispatchCombinedMetrics()
        }
    }
}

extension BaitJournalEntry {
    
    func initiateCombineClock() {
        journalClock?.invalidate()
        journalClock = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.dispatchCombinedMetrics()
        }
    }
    
    func interpretAlert(_ details: [AnyHashable: Any]) {
        let parser = BaitAlertParser()
        if let uriString = parser.parse(details: details) {
            UserDefaults.standard.set(uriString, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": uriString]
                )
            }
        }
    }
    
    func manageStartupAlerts(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let alertDetails = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            interpretAlert(alertDetails)
        }
    }
    
    func dispatchMetrics(metrics: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": metrics]
        )
    }
    
    private func dispatchCombinedMetrics() {
        var combinedMetrics = journalMetrics
        for (key, value) in journalAccesses {
            if combinedMetrics[key] == nil {
                combinedMetrics[key] = value
            }
        }
        dispatchMetrics(metrics: combinedMetrics)
        UserDefaults.standard.set(true, forKey: metricsDispatchedFlag)
    }
}

