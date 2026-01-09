import SwiftUI
import WebKit
import Combine

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    let calendar = Calendar.current
    @State private var currentMonth = Date()
    @State private var selectedDay: Date?
    
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        return (1...range.count).compactMap { day in
            calendar.date(bySetting: .day, value: day, of: currentMonth)
        }
    }
    
    var entriesByDate: [Date: [BaitEntry]] {
        Dictionary(grouping: dataManager.entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    HStack {
                        Button("<") {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                        Spacer()
                        Text(currentMonth.formatted(.dateTime.month().year()))
                            .font(.title)
                        Spacer()
                        Button(">") {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    }
                    .padding()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.headline)
                        }
                        ForEach(daysInMonth, id: \.self) { day in
                            let entryCount = entriesByDate[day]?.count ?? 0
                            let hasEntries = entryCount > 0
                            let bestBait = hasEntries ? Dictionary(grouping: entriesByDate[day] ?? [], by: { $0.baitName }).max(by: { $0.value.count < $1.value.count })?.key ?? "" : ""
                            
                            Button(action: {
                                selectedDay = hasEntries ? day : nil
                            }) {
                                VStack {
                                    Text("\(calendar.component(.day, from: day))")
                                        .foregroundColor(hasEntries ? .white : .darkIceBlue)
                                    if hasEntries {
                                        Text("\(entryCount)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                        Text(bestBait)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(hasEntries ? Color.iceBlue : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .navigationTitle("Calendar")
            .sheet(item: $selectedDay) { day in
                DayDetailsView(day: day)
                    .environmentObject(dataManager)
            }
        }
    }
}

extension Date: Identifiable {
    public var id: UUID { UUID() }
}

struct IceBaitMainInterface: View {
    @State private var operationalResourceUri: String? = ""
    
    var body: some View {
        ZStack {
            if let operationalResourceUri = operationalResourceUri, let uriAddress = URL(string: operationalResourceUri) {
                IceWebWrapper(uriAddress: uriAddress)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: configureStartingUri)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            reviseWithTemporaryUri()
        }
    }
    
    private func configureStartingUri() {
        let temporaryUri = UserDefaults.standard.string(forKey: "temp_url")
        let savedUri = UserDefaults.standard.string(forKey: "archived_location") ?? ""
        operationalResourceUri = temporaryUri ?? savedUri
        
        if temporaryUri != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
    
    private func reviseWithTemporaryUri() {
        if let temporaryUri = UserDefaults.standard.string(forKey: "temp_url"), !temporaryUri.isEmpty {
            operationalResourceUri = nil
            operationalResourceUri = temporaryUri
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

struct IceWebWrapper: UIViewRepresentable {
    let uriAddress: URL
    
    @StateObject private var webController = IceWebController()
    
    func makeCoordinator() -> IcePathCoordinator {
        IcePathCoordinator(controller: webController)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webController.initializeCentralDisplay()
        webController.centralDisplay.uiDelegate = context.coordinator
        webController.centralDisplay.navigationDelegate = context.coordinator
        
        webController.tokenManager.fetchAndImplementTokens()
        webController.centralDisplay.load(URLRequest(url: uriAddress))
        
        return webController.centralDisplay
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class IceWebController: ObservableObject {
    @Published var centralDisplay: WKWebView!
    
    private var watchers = Set<AnyCancellable>()
    
    func initializeCentralDisplay() {
        let displaySettings = constructDisplaySettings()
        centralDisplay = WKWebView(frame: .zero, configuration: displaySettings)
        modifyDisplayProperties(on: centralDisplay)
    }
    
    private func constructDisplaySettings() -> WKWebViewConfiguration {
        let settings = WKWebViewConfiguration()
        settings.allowsInlineMediaPlayback = true
        settings.mediaTypesRequiringUserActionForPlayback = []
        
        let settingsOptions = WKPreferences()
        settingsOptions.javaScriptEnabled = true
        settingsOptions.javaScriptCanOpenWindowsAutomatically = true
        settings.preferences = settingsOptions
        
        let pageOptions = WKWebpagePreferences()
        pageOptions.allowsContentJavaScript = true
        settings.defaultWebpagePreferences = pageOptions
        
        return settings
    }
    
    private func modifyDisplayProperties(on display: WKWebView) {
        display.scrollView.minimumZoomScale = 1.0
        display.scrollView.maximumZoomScale = 1.0
        display.scrollView.bounces = false
        display.scrollView.bouncesZoom = false
        display.allowsBackForwardNavigationGestures = true
    }
    
    @Published var additionalDisplays: [WKWebView] = []
    
    let tokenManager = TokenManager()
    
    func reversePath(to address: URL? = nil) {
        if !additionalDisplays.isEmpty {
            if let lastAdd = additionalDisplays.last {
                lastAdd.removeFromSuperview()
                additionalDisplays.removeLast()
            }
            
            if let goalAddress = address {
                centralDisplay.load(URLRequest(url: goalAddress))
            }
        } else if centralDisplay.canGoBack {
            centralDisplay.goBack()
        }
    }
    
    func revitalizeResource() {
        centralDisplay.reload()
    }
}

class TokenManager {
    func fetchAndImplementTokens() {
        guard let preservedTokens = UserDefaults.standard.object(forKey: "preserved_tokens") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        
        let tokenRepository = IceWebController().centralDisplay?.configuration.websiteDataStore.httpCookieStore
        
        let interpretedTokens = preservedTokens.values.flatMap { $0.values }.compactMap { attributes in
            HTTPCookie(properties: attributes as [HTTPCookiePropertyKey: Any])
        }
        
        interpretedTokens.forEach { token in
            tokenRepository?.setCookie(token)
        }
    }
    
    func collectAndPreserveTokens(from display: WKWebView) {
        display.configuration.websiteDataStore.httpCookieStore.getAllCookies { tokens in
            var zoneMapping: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for token in tokens {
                var subMapping = zoneMapping[token.domain] ?? [:]
                if let props = token.properties {
                    subMapping[token.name] = props
                }
                zoneMapping[token.domain] = subMapping
            }
            
            UserDefaults.standard.set(zoneMapping, forKey: "preserved_tokens")
        }
    }
}

class CodeInserter {
    func insertImprovements(to display: WKWebView) {
        let improvementScript = """
        (function() {
            const dimensionElement = document.createElement('meta');
            dimensionElement.name = 'viewport';
            dimensionElement.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(dimensionElement);
            
            const layoutElement = document.createElement('style');
            layoutElement.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(layoutElement);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        display.evaluateJavaScript(improvementScript) { _, mistake in
            if let mistake = mistake { print("Improvement insertion error: \(mistake)") }
        }
    }
}

class IcePathCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    private var rerouteCount = 0
    
    init(controller: IceWebController) {
        self.webController = controller
        super.init()
    }
    
    private var webController: IceWebController
    
    private let codeInserter = CodeInserter()
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let addDisplay = WKWebView(frame: .zero, configuration: configuration)
        prepareAddDisplay(addDisplay)
        secureConstraintsToAdd(addDisplay)
        
        webController.additionalDisplays.append(addDisplay)
        
        let swipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeMotion))
        swipeRecognizer.edges = .left
        addDisplay.addGestureRecognizer(swipeRecognizer)
        
        if verifyPathRequest(navigationAction.request) {
            addDisplay.load(navigationAction.request)
        }
        
        return addDisplay
    }
    
    @objc func handleEdgeMotion(_ sensor: UIScreenEdgePanGestureRecognizer) {
        guard sensor.state == .ended,
              let presentDisplay = sensor.view as? WKWebView else { return }
        
        if presentDisplay.canGoBack {
            presentDisplay.goBack()
        } else if webController.additionalDisplays.last === presentDisplay {
            webController.reversePath(to: nil)
        }
    }
    
    private func verifyPathRequest(_ request: URLRequest) -> Bool {
        guard let pathString = request.url?.absoluteString,
              !pathString.isEmpty,
              pathString != "about:blank" else { return false }
        return true
    }
    
    private var earlierAddress: URL?
    
    private let rerouteLimit = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let secureTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: secureTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func prepareAddDisplay(_ display: WKWebView) {
        display.translatesAutoresizingMaskIntoConstraints = false
        display.scrollView.isScrollEnabled = true
        display.scrollView.minimumZoomScale = 1.0
        display.scrollView.maximumZoomScale = 1.0
        display.scrollView.bounces = false
        display.scrollView.bouncesZoom = false
        display.allowsBackForwardNavigationGestures = true
        display.navigationDelegate = self
        display.uiDelegate = self
        webController.centralDisplay.addSubview(display)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        codeInserter.insertImprovements(to: webView)
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects,
           let backupAddress = earlierAddress {
            webView.load(URLRequest(url: backupAddress))
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        rerouteCount += 1
        
        if rerouteCount > rerouteLimit {
            webView.stopLoading()
            if let backupAddress = earlierAddress {
                webView.load(URLRequest(url: backupAddress))
            }
            return
        }
        
        earlierAddress = webView.url
        webController.tokenManager.collectAndPreserveTokens(from: webView)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let pathAddress = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        earlierAddress = pathAddress
        
        let schemeKind = (pathAddress.scheme ?? "").lowercased()
        let fullPathStr = pathAddress.absoluteString.lowercased()
        
        let approvedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let approvedBeginnings = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let isApproved = approvedSchemes.contains(schemeKind) ||
                         approvedBeginnings.contains { fullPathStr.hasPrefix($0) } ||
                         fullPathStr == "about:blank"
        
        if isApproved {
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(pathAddress, options: [:]) { _ in }
        
        decisionHandler(.cancel)
    }
    
    private func secureConstraintsToAdd(_ display: WKWebView) {
        NSLayoutConstraint.activate([
            display.leadingAnchor.constraint(equalTo: webController.centralDisplay.leadingAnchor),
            display.trailingAnchor.constraint(equalTo: webController.centralDisplay.trailingAnchor),
            display.topAnchor.constraint(equalTo: webController.centralDisplay.topAnchor),
            display.bottomAnchor.constraint(equalTo: webController.centralDisplay.bottomAnchor)
        ])
    }
}
