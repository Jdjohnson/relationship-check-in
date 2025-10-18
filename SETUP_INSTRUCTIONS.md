# Setup Instructions for Relationship Check-in

## Step-by-Step Xcode Setup

Since this is a new project, you'll need to create it in Xcode. Follow these steps:

### 1. Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose **iOS** → **App**
4. Configure:
   - Product Name: `RelationshipCheckin`
   - Team: Select your Apple Developer team
   - Organization Identifier: `com.jaradjohnson`
   - Bundle Identifier: `com.jaradjohnson.RelationshipCheckin`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll use CloudKit)
   - Include Tests: Optional
5. Save to: `/Users/jaradjohnson/Projects/Relationship Check-in/`

### 2. Add Capabilities

In Xcode, select the project → Target → Signing & Capabilities:

#### Add iCloud Capability
1. Click **+ Capability**
2. Add **iCloud**
3. Check **CloudKit**
4. Under Containers, click **+** and add: `iCloud.com.jaradjohnson.RelationshipCheckin`

#### Add Push Notifications
1. Click **+ Capability**
2. Add **Push Notifications**

#### Add Background Modes
1. Click **+ Capability**
2. Add **Background Modes**
3. Check **Remote notifications**

### 3. Configure Entitlements

The `RelationshipCheckin.entitlements` file has been created. Make sure it's added to your target:
- Select the file in Project Navigator
- In File Inspector, ensure it's in Target Membership

### 4. Configure Info.plist

The `Info.plist` file has been created with URL scheme configuration. Ensure it's set as the Info.plist file:
- Project Settings → Build Settings → Search "Info.plist"
- Set path to: `RelationshipCheckin/Info.plist`

### 5. Add Source Files to Xcode

All source files have been created in the correct directory structure. In Xcode:

1. Right-click on the `RelationshipCheckin` group
2. Add Files to "RelationshipCheckin"...
3. Select all the folders:
   - Models/
   - Services/
   - ViewModels/
   - Views/
   - UI/
4. Ensure "Copy items if needed" is **unchecked** (files are already in place)
5. Ensure "Create groups" is selected
6. Add to target: RelationshipCheckin

### 6. Replace Default Files

Replace the default `RelationshipCheckinApp.swift` and `ContentView.swift` with the ones provided.

### 7. Set Deployment Target

- Project Settings → General → Deployment Info
- Set **Minimum Deployments** to **iOS 17.0**

### 8. CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container: `iCloud.com.jaradjohnson.RelationshipCheckin`
3. Go to **Schema** → **Development**

#### Create Record Type: Couple
- Click **+** to add new Record Type
- Name: `Couple`
- Add Fields:
  - `ownerUserRecordID` - Type: Reference (User)
  - `partnerUserRecordID` - Type: Reference (User)

#### Create Record Type: DailyEntry
- Click **+** to add new Record Type
- Name: `DailyEntry`
- Add Fields:
  - `date` - Type: Date/Time
  - `authorUserRecordID` - Type: Reference (User)
  - `morningNeed` - Type: String
  - `eveningMood` - Type: Int(64)
  - `gratitude` - Type: String
  - `tomorrowGreat` - Type: String
  - `couple` - Type: Reference (Couple)

#### Create Custom Zone
The app will automatically create the custom zone `RelationshipZone` on first launch.

### 9. Build and Run

1. Select your iPhone or simulator (iOS 17+)
2. Build and run (Cmd+R)
3. Sign in with your Apple ID when prompted
4. Grant notification permissions

### 10. Testing with Two Devices

To test the pairing flow:

1. **Device 1** (Owner):
   - Launch app
   - Tap "Create Invite Link"
   - Share the link via Messages/Email

2. **Device 2** (Partner):
   - Launch app
   - Tap "Accept Invite"
   - Paste the invite link
   - Tap "Accept Invite"

3. Both devices should now be paired and able to see each other's check-ins

### 11. Deploy to Production (When Ready)

1. In CloudKit Dashboard, go to **Schema**
2. Click **Deploy to Production**
3. Review changes and confirm
4. Archive app in Xcode
5. Upload to App Store Connect
6. Add both users as TestFlight internal testers

## Troubleshooting

### iCloud/CloudKit Issues
- Ensure you're signed in to iCloud on your device
- Check that iCloud Drive is enabled
- Verify CloudKit container is created in Developer Portal

### Notifications Not Working
- Check notification permissions in Settings → Notifications
- Verify the app has permission to send notifications
- Check that notifications are scheduled (use Xcode debugger)

### Deep Links Not Working
- Verify URL scheme `rc` is in Info.plist
- Check that Associated Domains capability is properly configured
- Test with: `xcrun simctl openurl booted "rc://entry/morning"`

## File Structure

```
RelationshipCheckin/
├── RelationshipCheckinApp.swift
├── ContentView.swift
├── Models/
│   ├── DailyEntry.swift
│   └── Mood.swift
├── Services/
│   ├── CloudKitService.swift
│   ├── ShareService.swift
│   ├── NotificationService.swift
│   └── DeepLinkService.swift
├── ViewModels/
│   ├── MainViewModel.swift
│   ├── EntryViewModel.swift
│   ├── HistoryViewModel.swift
│   └── PairingViewModel.swift
├── Views/
│   ├── MainView.swift
│   ├── EntryView.swift
│   ├── HistoryDrawerView.swift
│   └── PairingView.swift
└── UI/
    └── DesignSystem.swift
```

## Next Steps

1. Create the Xcode project following steps 1-7
2. Build and test on your device
3. Set up CloudKit schema (step 8)
4. Test pairing with Laura's device
5. Customize colors/text if desired
6. Deploy to TestFlight when ready

Enjoy your daily check-ins! ❤️
