//
//  NotificationService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import UserNotifications
import SwiftUI
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            self.isAuthorized = granted
        } catch {
            print("Notification permission error: \(error)")
            self.isAuthorized = false
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleNotifications() {
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Morning notification at 8:00 AM
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Morning Check-in"
        morningContent.body = "One thing I need today..."
        morningContent.sound = .default
        morningContent.userInfo = ["deeplink": "rc://entry/morning"]
        if let attachment = makeAppIconAttachment() {
            morningContent.attachments = [attachment]
        }
        
        var morningComponents = DateComponents()
        morningComponents.hour = 8
        morningComponents.minute = 0
        
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "morning-checkin", content: morningContent, trigger: morningTrigger)
        
        // Evening notification at 5:00 PM
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening Check-in"
        eveningContent.body = "How was your day?"
        eveningContent.sound = .default
        eveningContent.userInfo = ["deeplink": "rc://entry/evening"]
        if let attachment = makeAppIconAttachment() {
            eveningContent.attachments = [attachment]
        }
        
        var eveningComponents = DateComponents()
        eveningComponents.hour = 17
        eveningComponents.minute = 0
        
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "evening-checkin", content: eveningContent, trigger: eveningTrigger)
        
        // Add both notifications
        center.add(morningRequest) { error in
            if let error = error {
                print("Error scheduling morning notification: \(error)")
            }
        }
        
        center.add(eveningRequest) { error in
            if let error = error {
                print("Error scheduling evening notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func makeAppIconAttachment() -> UNNotificationAttachment? {
        // Load from asset catalog
        guard let image = UIImage(named: "NotificationIcon") else { return nil }
        guard let pngData = image.pngData() else { return nil }
        do {
            let cachesDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            // Use a stable filename so we reuse the same file
            let fileURL = cachesDir.appendingPathComponent("notification-icon.png")
            try pngData.write(to: fileURL, options: .atomic)
            let attachment = try UNNotificationAttachment(identifier: "app-icon", url: fileURL, options: nil)
            return attachment
        } catch {
            print("Failed to create notification attachment: \(error)")
            return nil
        }
    }
}

