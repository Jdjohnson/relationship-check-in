# Quick Start Guide

## For You (Jarad) and Laura

### Initial Setup (Do Once)

#### 1. Create Xcode Project
```bash
# Open Xcode
# File → New → Project → iOS App
# Product Name: RelationshipCheckin
# Organization Identifier: com.jaradjohnson
# Interface: SwiftUI
# Save to: /Users/jaradjohnson/Projects/Relationship Check-in/
```

#### 2. Add All Files to Xcode
- Drag the `RelationshipCheckin` folder into Xcode
- Ensure all `.swift` files are added to target
- Add `Info.plist` and `RelationshipCheckin.entitlements`

#### 3. Enable Capabilities
In Xcode → Target → Signing & Capabilities:
- ✅ iCloud → CloudKit → `iCloud.com.jaradjohnson.RelationshipCheckin`
- ✅ Push Notifications
- ✅ Background Modes → Remote notifications

#### 4. Set Up CloudKit Schema
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select container: `iCloud.com.jaradjohnson.RelationshipCheckin`
3. Create record types (see CLOUDKIT_SCHEMA.md):
   - **Couple**: ownerUserRecordID, partnerUserRecordID
   - **DailyEntry**: date, authorUserRecordID, couple, morningNeed, eveningMood, gratitude, tomorrowGreat

#### 5. Build and Install
- Connect your iPhone
- Select your device in Xcode
- Click Run (⌘R)
- Sign in with Apple ID when prompted
- Allow notifications

### Pairing (Do Once Together)

#### Jarad (Owner):
1. Open app
2. Tap **"Create Invite Link"**
3. Share link with Laura via Messages

#### Laura (Partner):
1. Open app
2. Tap **"Accept Invite"**
3. Paste the link from Jarad
4. Tap **"Accept Invite"**

✅ You're now paired!

### Daily Usage

#### Morning (8:00 AM)
1. Notification appears: "Morning Check-in"
2. Tap notification
3. Enter "One thing I need today"
4. Tap Save
5. Done! ☀️

#### Evening (5:00 PM)
1. Notification appears: "Evening Check-in"
2. Tap notification
3. Select mood: 🟢 Green / 🟡 Yellow / 🔴 Red
4. Enter gratitude for your partner
5. Enter one thing to make tomorrow great
6. Tap Save
7. Done! 🌙

#### Viewing Partner's Entry
1. Open app anytime
2. Main screen shows partner's check-in for today
3. Pull down to refresh

#### Viewing History
1. Tap calendar icon (top right)
2. Select any past date
3. See both your entries from that day

## Features at a Glance

| Feature | Description |
|---------|-------------|
| 🌅 Morning Check-in | Share what you need (8 AM notification) |
| 🌆 Evening Check-in | Share mood, gratitude, hope (5 PM notification) |
| 💕 Partner View | See your partner's daily entry |
| 📅 History | Browse past check-ins by date |
| 🔒 Private | Only you two, stored in iCloud |
| ✨ Beautiful | Liquid glass design, spacious layout |

## Notification Times

- **Morning**: 8:00 AM daily
- **Evening**: 5:00 PM daily

To change times, edit `NotificationService.swift`:
```swift
morningComponents.hour = 8  // Change to desired hour
eveningComponents.hour = 17 // Change to desired hour (17 = 5 PM)
```

## Tips

### Best Practices
- ✅ Check in daily (even if brief)
- ✅ Be honest about your mood
- ✅ Express specific gratitude
- ✅ Keep "tomorrow great" actionable

### If You Miss a Day
- No problem! You can enter check-ins anytime
- Tap the morning/evening buttons on main screen
- Previous entries are saved and visible in history

### If Notifications Don't Appear
1. Settings → Notifications → RelationshipCheckin
2. Ensure "Allow Notifications" is ON
3. Check "Sounds" and "Badges" are enabled

### If Partner's Entry Doesn't Show
1. Pull down on main screen to refresh
2. Check internet connection
3. Ensure both signed in to iCloud
4. Wait a few seconds for CloudKit sync

## Customization Ideas

### Change Colors
Edit `DesignSystem.swift`:
```swift
static let moodGreen = Color(red: 0.4, green: 0.78, blue: 0.55)
static let moodYellow = Color(red: 0.95, green: 0.77, blue: 0.36)
static let moodRed = Color(red: 0.92, green: 0.49, blue: 0.45)
```

### Change Notification Text
Edit `NotificationService.swift`:
```swift
morningContent.title = "Good morning! ☀️"
morningContent.body = "What do you need today?"

eveningContent.title = "Evening reflection 🌙"
eveningContent.body = "How was your day?"
```

### Add More Questions
Edit `EntryView.swift` to add additional fields, then update:
- `DailyEntry.swift` model
- `CloudKitService.swift` save/fetch logic
- CloudKit schema in dashboard

## Troubleshooting

### App Won't Build
- ✅ Check all files are added to target
- ✅ Verify deployment target is iOS 17+
- ✅ Ensure signing team is selected

### Can't Sign In
- ✅ Sign in to iCloud in Settings
- ✅ Enable iCloud Drive
- ✅ Check internet connection

### Can't Pair
- ✅ Both users signed in to iCloud
- ✅ Both using same CloudKit container
- ✅ Share link is valid (not expired)

### Data Not Syncing
- ✅ Check internet connection
- ✅ Wait 10-30 seconds for CloudKit sync
- ✅ Pull to refresh on main screen
- ✅ Restart app if needed

## Support

For issues:
1. Check SETUP_INSTRUCTIONS.md
2. Review CLOUDKIT_SCHEMA.md
3. Check Xcode console for errors
4. Verify CloudKit Dashboard shows records

## Privacy & Security

- ✅ All data in your private iCloud
- ✅ Only you two have access
- ✅ No third-party servers
- ✅ No analytics or tracking
- ✅ Sign in with Apple (secure)

## Future Ideas

Consider adding:
- [ ] Weekly/monthly summaries
- [ ] Photo attachments
- [ ] Custom questions
- [ ] Mood trends over time
- [ ] Export to PDF
- [ ] Apple Watch complications
- [ ] Widgets for home screen
- [ ] Shared calendar events

---

Enjoy your daily connection! ❤️

Built with love for Jarad & Laura

