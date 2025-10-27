//
//  RelationshipCheckinApp.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import SwiftUI
import UserNotifications

@main
struct RelationshipCheckinApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(RCAppDelegate.self) var appDelegate
    @StateObject private var cloudKitService = CloudKitService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var deepLinkService = DeepLinkService.shared
    
    init() {
        // Configure notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(notificationService)
                .environmentObject(deepLinkService)
                .onOpenURL { url in
                    // Ensure main-actor handling
                    Task { @MainActor in
                        deepLinkService.handle(url: url)
                    }
                }
                .task {
                    await cloudKitService.initialize()
                    await notificationService.requestPermission()
                    notificationService.scheduleNotifications()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { try? await cloudKitService.checkPairingStatus() }
                }
        }
    }
}

// Notification delegate to handle notification taps
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let deeplinkString = response.notification.request.content.userInfo["deeplink"] as? String,
           let url = URL(string: deeplinkString) {
            // Hop to the main actor for UI-bound deep link handling (Swift 6 strict isolation)
            Task { @MainActor in
                DeepLinkService.shared.handle(url: url)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
