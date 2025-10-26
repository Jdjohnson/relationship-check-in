import UIKit
import CloudKit

final class RCAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task {
            do {
                let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
                _ = try await container.accept([metadata])
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
