import UIKit
import CloudKit

final class RCAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        CloudKitService.shared.restorePersistedState()
        return true
    }

    func application(_ application: UIApplication,
                     userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task { @MainActor in
            do {
                try await ShareService.shared.acceptShare(metadata: metadata)

                NotificationCenter.default.post(name: .rcShareAccepted, object: nil)
            } catch {
                NotificationCenter.default.post(name: .rcShareFailed, object: error)
            }
        }
    }
}

extension Notification.Name {
    static let rcShareAccepted = Notification.Name("rcShareAccepted")
    static let rcShareFailed = Notification.Name("rcShareFailed")
}
