import SwiftUI

//extension Color {
//    static let iceWhite = Color.white
//    static let lightIceBlue = Color.blue.opacity(0.2)
//    static let iceBlue = Color.blue.opacity(0.5)
//    static let darkIceBlue = Color(red: 0.0, green: 0.2, blue: 0.5)
//    static let silverAccent = Color.gray.opacity(0.8)
//    static let frostBlue = Color(red: 0.678, green: 0.847, blue: 0.902) // LightSkyBlue
//    static let deepFreeze = Color(red: 0.0, green: 0.0, blue: 0.545) // DarkBlue
//}

extension Color {
    static let iceWhite: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemGray6 : UIColor.white
    })
    static let lightIceBlue: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.blue.withAlphaComponent(0.1) : UIColor.blue.withAlphaComponent(0.2)
    })
    static let iceBlue: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.blue.withAlphaComponent(0.7) : UIColor.blue.withAlphaComponent(0.5)
    })
    static let darkIceBlue: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemBlue : UIColor(red: 0.0, green: 0.2, blue: 0.5, alpha: 1.0)
    })
    static let silverAccent: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.gray.withAlphaComponent(0.6) : UIColor.gray.withAlphaComponent(0.8)
    })
    static let frostBlue: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0) : UIColor(red: 0.678, green: 0.847, blue: 0.902, alpha: 1.0)
    })
    static let deepFreeze: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.black : UIColor(red: 0.0, green: 0.0, blue: 0.545, alpha: 1.0)
    })
    static let glassBlur: Color = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.1) : UIColor.white.withAlphaComponent(0.3)
    })
}

struct StageAssessmentUseCase {
    func activate(setupMetrics: [String: Any], isFresh: Bool, tempLoc: String?) -> JournalStage {
        if setupMetrics.isEmpty {
            return .obsolete
        }
        if UserDefaults.standard.string(forKey: "program_status") == "Inactive" {
            return .obsolete
        }
        if isFresh && (setupMetrics["af_status"] as? String == "Organic") {
            return .setup
        }
        if tempLoc != nil {
            return .running
        }
        return .setup
    }
}

struct AuthQueryUseCase {
    func activate() -> Bool {
        let authStore = AuthStateStoreImpl()
        guard !authStore.isAuthConfirmed(), !authStore.isAuthRejected() else {
            return false
        }
        if let earlier = authStore.fetchLastAuthQuery(), Date().timeIntervalSince(earlier) < 259200 {
            return false
        }
        return true
    }
}

struct NaturalSetupUseCase {
    func activate(accessMetrics: [String: Any]) async throws -> [String: Any] {
        let hardwareStore = HardwareInfoStoreImpl()
        let composer = LocationComposer()
            .defineAppCode(JournalSetup.flyerCode)
            .defineDevCode(JournalSetup.flyerDevCode)
            .defineDeviceCode(hardwareStore.fetchTrackerId())
        guard let setupLoc = composer.compose() else {
            throw JournalFault.locationComposeFail
        }
        let (details, reply) = try await URLSession.shared.data(from: setupLoc)
        guard let httpReply = reply as? HTTPURLResponse, httpReply.statusCode == 200 else {
            throw JournalFault.replyCheckFail
        }
        guard let decoded = try? JSONSerialization.jsonObject(with: details) as? [String: Any] else {
            throw JournalFault.detailsDecodeFail
        }
        var combined = decoded
        for (k, v) in accessMetrics where combined[k] == nil {
            combined[k] = v
        }
        return combined
    }
}
