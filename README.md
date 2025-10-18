# Relationship Check-in

A beautiful, private iOS app for couples to share daily check-ins with each other.

## Features

- **Daily Notifications**: Reminders at 8:00 AM and 5:00 PM
  - Morning: Share one thing you need today
  - Evening: Share your mood, gratitude, and hopes for tomorrow

- **Main Screen**: View your partner's daily check-in
- **History**: Browse past check-ins by date
- **Private & Secure**: CloudKit with Sign in with Apple, only for two users

## Design

Built with iOS 17+ using SwiftUI and featuring:
- Liquid Glass aesthetic with `.ultraThinMaterial`
- Spacious, clean layout
- Natural, pleasing colors
- Haptic feedback

## Setup

### Prerequisites

- Xcode 15+
- iOS 17+ deployment target
- Apple Developer account with CloudKit enabled
- Bundle ID: `com.jaradjohnson.RelationshipCheckin`

### CloudKit Configuration

1. Open the project in Xcode
2. Select your development team in Signing & Capabilities
3. Enable iCloud capability with CloudKit
4. Create the CloudKit container: `iCloud.com.jaradjohnson.RelationshipCheckin`

### CloudKit Schema

In CloudKit Dashboard, create the following record types:

#### Couple
- `ownerUserRecordID` (Reference to User)
- `partnerUserRecordID` (Reference to User, optional)

#### DailyEntry
- `date` (Date/Time)
- `authorUserRecordID` (Reference to User)
- `morningNeed` (String, optional)
- `eveningMood` (Int64, optional) - 0=green, 1=yellow, 2=red
- `gratitude` (String, optional)
- `tomorrowGreat` (String, optional)
- `couple` (Reference to Couple)

### Deep Links

The app supports the following deep link scheme: `rc://`

- `rc://entry/morning` - Opens morning check-in
- `rc://entry/evening` - Opens evening check-in

### Notifications

Local notifications are scheduled automatically:
- 8:00 AM daily - Morning check-in reminder
- 5:00 PM daily - Evening check-in reminder

## Usage

### First Time Setup

1. Launch the app and sign in with Apple ID
2. One person creates an invite link and shares it via Messages/Email
3. Partner accepts the invite link
4. Both users are now paired and can see each other's check-ins

### Daily Check-ins

- Tap notification to go directly to the entry screen
- Or use the quick action buttons on the main screen
- Morning: Share what you need today
- Evening: Share your mood (green/yellow/red), gratitude, and tomorrow's goal

### Viewing History

- Tap the calendar icon in the top right
- Select any past date to view both check-ins from that day

## Architecture

- **MVVM Pattern**: Clean separation of concerns
- **CloudKit**: Private database with sharing for two users
- **Services Layer**: CloudKit, Share, Notification, DeepLink services
- **Design System**: Reusable components and consistent styling

## Privacy

- All data stored in your private iCloud account
- Shared only with your partner via CloudKit sharing
- No third-party servers or analytics
- Sign in with Apple for authentication

## Distribution

Deploy via TestFlight:
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Add both users as internal testers
4. Deploy CloudKit schema from Development to Production

## License

Private app for personal use.

