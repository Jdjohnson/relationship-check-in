//
//  NotificationService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import UserNotifications
import SwiftUI

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
}

