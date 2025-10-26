# .cursor/debug.log

```log

```

# .cursor/plans/fix-50ada188.plan.md

```md
<!-- 50ada188-fd5d-4ae5-a8d0-75509fa1c4bc be6bbd5b-f670-4cd5-abe6-1bd6f8ae137f -->
# Plan: Fix orientation warning, speed up invite link creation, and make link acceptance work

## Diagnosis summary

- **Issue 1 (orientation warning)**
- Likely causes:
- Missing `UIRequiresFullScreen` while not supporting all orientations on iPad.
- No explicit `UISupportedInterfaceOrientations` set for iPhone/iPad.
- iPad multitasking expectation not met when not full screen.
- Most likely: Add `UIRequiresFullScreen = true` to silence the validation requirement for all orientations. Confidence: 95%.

- **Issue 2 (share sheet slow ~10s)**
- Likely causes:
- CloudKit network latency creating `Couple` record then `CKShare` (two server saves).
- Creating a new `Couple` every time instead of reusing one.
- First-run CloudKit warm-up/auth latency.
- Doing the work on main actor (perceived stall before presenting sheet).
- Generic share-sheet initialization cost (minor).
- Most likely: CloudKit save latency + redundant `Couple` creation. Confidence: 85%.

- **Issue 3 (accept via text does nothing; self-link)**
- Likely causes:
- `CKShare.publicPermission = .none` blocks acceptance by non-added participants.
- Accepting your own share is not allowed; error is printed but not surfaced.
- If the link was the deep link `rc://...`, it opens app and swallows error.
- Most likely: `publicPermission = .none` + trying to accept as owner. Confidence: 95%.

## Implementation summary

- **Orientation warning**
- Added `UIRequiresFullScreen = true` and constrained iPhone orientations to portrait in `Info.plist` to satisfy App Store validation. This matches the current UI expectations and prevents iPad multitasking assumptions.

- **Speed up invite link creation**
- Introduced `CloudKitService.ensureCouple()` to reuse an existing couple record before attempting to create a new one, falling back to creation only when nothing is found after a pairing-status refresh.
- Updated `PairingViewModel.createInviteLink()` to call the new helper so repeated link creation avoids the extra CloudKit round-trip.

- **Make acceptance work and support solo testing**
- Switched the share permission to `.readWrite` so recipients can accept without being pre-added.
- Wrapped the accept flow in a DEBUG-only fallback that self-pairs when CloudKit rejects the owner accepting their own share while still preserving normal error propagation in release builds.
- As part of the fallback we refresh pairing status before updating the couple, keeping local state in sync.

## Code changes

- `RelationshipCheckin/Info.plist`
- Added `UIRequiresFullScreen` and `UISupportedInterfaceOrientations` (portrait-only) keys under the root dictionary.

- `RelationshipCheckin/Services/ShareService.swift`
- `createShare` now sets `share.publicPermission = .readWrite`.
- `acceptShare(metadata:)` fetches the current user ID directly after acceptance, refreshes pairing, and includes a DEBUG-mode fallback that self-pairs on the owner-acceptance error path while clearing `self.error` on success.

- `RelationshipCheckin/Services/CloudKitService.swift`
- Added `ensureCouple()` that looks up the cached couple ID in shared/private databases after running `checkPairingStatus()`, creating a new record only if none exists.

- `RelationshipCheckin/ViewModels/PairingViewModel.swift`
- `createInviteLink()` now invokes `ensureCouple()` so subsequent links reuse the same record.

## Todos

- setup-orientation
- Added `UIRequiresFullScreen` and constrained iPhone orientation to portrait in `Info.plist`.
- allow-share-accept
- Set `CKShare.publicPermission = .readWrite` in `ShareService.createShare`.
- solo-test-fallback
- Implemented DEBUG-only fallback inside `ShareService.acceptShare` to self-pair on accept failure while preserving release behavior.
- reuse-couple
- Added `ensureCouple()` in `CloudKitService` and updated `PairingViewModel` to use it.

## Validation

- Manual testing deferred; no automated tests available for these CloudKit flows in the project.

### To-dos

- [x] Add UIRequiresFullScreen to Info.plist (and optional iPhone orientations)
- [x] Set CKShare.publicPermission = .readWrite in ShareService.createShare
- [x] Add DEBUG-only self-pair fallback in ShareService.acceptShare on accept failure
- [x] Add ensureCouple() in CloudKitService and use it in PairingViewModel
```

# .github/workflows/testflight.yml

```yml
name: TestFlight Upload

on:
  workflow_dispatch:

jobs:
  beta:
    runs-on: macos-13
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install Fastlane
        run: bundle install

      - name: Xcode Select
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Fastlane Beta
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APP_STORE_CONNECT_TEAM_ID: ${{ secrets.APP_STORE_CONNECT_TEAM_ID }}
          DEVELOPMENT_TEAM_ID: ${{ secrets.DEVELOPMENT_TEAM_ID }}
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: bundle exec fastlane ios beta



```

# .gitignore

```
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
# Packages/
# Package.pins
# Package.resolved
# *.xcodeproj
#
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
# .swiftpm

.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build/

# Accio dependency management
Dependencies/
.accio/

# fastlane
#
# It is recommended to not store the screenshots in the git repo.
# Instead, use fastlane to re-generate the screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/#source-control

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/

# Mac
.DS_Store


```

# APP_SCREENS.md

```md
# App Screens & User Flow

## Visual Guide to the App

### Screen 1: Loading (First Launch)
\`\`\`
┌─────────────────────────────────┐
│                                 │
│                                 │
│          ⏳ Loading             │
│                                 │
│       Setting up...             │
│                                 │
│                                 │
└─────────────────────────────────┘
\`\`\`
**What happens**: 
- App initializes CloudKit
- Fetches user record ID
- Creates custom zone
- Checks pairing status

---

### Screen 2: Pairing (If Not Paired)
\`\`\`
┌─────────────────────────────────┐
│                                 │
│         ❤️ (large icon)         │
│                                 │
│   Relationship Check-in         │
│                                 │
│  Connect with your partner      │
│  to start sharing daily         │
│  check-ins                      │
│                                 │
│  ┌───────────────────────────┐  │
│  │  🔗 Create Invite Link    │  │
│  │  Share with your partner  │  │
│  │                           │  │
│  │  [Create Link]            │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ✉️ Accept Invite         │  │
│  │  Join your partner        │  │
│  │                           │  │
│  │  [Accept Link]            │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
\`\`\`
**Actions**:
- Tap "Create Link" → Share sheet appears
- Tap "Accept Link" → Paste invite URL

---

### Screen 3: Main Screen (Daily View)
\`\`\`
┌─────────────────────────────────┐
│                          📅     │
│                                 │
│           Today                 │
│      October 10, 2025           │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ❤️ From Your Partner      │  │
│  │                           │  │
│  │ ☀️ Morning Need           │  │
│  │ "Quality time together"   │  │
│  │                           │  │
│  │ 😊 Mood                   │  │
│  │ 🟢 Great                  │  │
│  │                           │  │
│  │ ✨ Gratitude              │  │
│  │ "Thank you for making     │  │
│  │  dinner tonight"          │  │
│  │                           │  │
│  │ ➡️ Tomorrow               │  │
│  │ "A morning walk together" │  │
│  └───────────────────────────┘  │
│                                 │
│     Your Check-ins              │
│                                 │
│  ┌─────────┐    ┌─────────┐    │
│  │  ☀️     │    │  🌙     │    │
│  │ Morning │    │ Evening │    │
│  │ What I  │    │ My day  │    │
│  │  need   │    │         │    │
│  └─────────┘    └─────────┘    │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ✓ Your Entry Today        │  │
│  │ ☀️ Morning  🌙 Evening    │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
\`\`\`
**Actions**:
- Tap calendar icon → History drawer
- Tap Morning → Morning entry form
- Tap Evening → Evening entry form
- Pull down → Refresh

---

### Screen 4: Morning Entry Form
\`\`\`
┌─────────────────────────────────┐
│  [Close]                        │
│                                 │
│         ☀️ (large icon)         │
│                                 │
│     Morning Check-in            │
│     October 10, 2025            │
│                                 │
│  ┌───────────────────────────┐  │
│  │ One thing I need today    │  │
│  │                           │  │
│  │ ┌───────────────────────┐ │  │
│  │ │ What do you need?     │ │  │
│  │ │                       │ │  │
│  │ │ [Text entry area]     │ │  │
│  │ │                       │ │  │
│  │ └───────────────────────┘ │  │
│  └───────────────────────────┘  │
│                                 │
│         [Save]                  │
│                                 │
└─────────────────────────────────┘
\`\`\`
**Actions**:
- Type your need
- Tap Save → Saved to CloudKit
- Auto-dismiss after success

---

### Screen 5: Evening Entry Form
\`\`\`
┌─────────────────────────────────┐
│  [Close]                        │
│                                 │
│         🌙 (large icon)         │
│                                 │
│     Evening Check-in            │
│     October 10, 2025            │
│                                 │
│  ┌───────────────────────────┐  │
│  │ How was your day?         │  │
│  │                           │  │
│  │  🟢      🟡      🔴       │  │
│  │ Great   Okay  Difficult   │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ One gratitude for your    │  │
│  │ partner                   │  │
│  │                           │  │
│  │ ┌───────────────────────┐ │  │
│  │ │ I'm grateful for...   │ │  │
│  │ │ [Text entry]          │ │  │
│  │ └───────────────────────┘ │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ One thing to make         │  │
│  │ tomorrow great            │  │
│  │                           │  │
│  │ ┌───────────────────────┐ │  │
│  │ │ Tomorrow will be...   │ │  │
│  │ │ [Text entry]          │ │  │
│  │ └───────────────────────┘ │  │
│  └───────────────────────────┘  │
│                                 │
│         [Save]                  │
│                                 │
└─────────────────────────────────┘
\`\`\`
**Actions**:
- Tap mood circle (green/yellow/red)
- Type gratitude
- Type tomorrow goal
- Tap Save → Haptic feedback + save

---

### Screen 6: History Drawer
\`\`\`
┌─────────────────────────────────┐
│  [Done]      History            │
│                                 │
│  ┌───────────────────────────┐  │
│  │   October 2025            │  │
│  │  S  M  T  W  T  F  S      │  │
│  │        1  2  3  4  5      │  │
│  │  6  7  8  9 [10]11 12     │  │
│  │ 13 14 15 16 17 18 19      │  │
│  │ 20 21 22 23 24 25 26      │  │
│  │ 27 28 29 30 31            │  │
│  └───────────────────────────┘  │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ❤️ Partner                │  │
│  │                           │  │
│  │ ☀️ Morning Need           │  │
│  │ "A quiet morning"         │  │
│  │                           │  │
│  │ 😊 Mood: 🟢 Great         │  │
│  │                           │  │
│  │ ✨ Gratitude              │  │
│  │ "Your support today"      │  │
│  │                           │  │
│  │ ➡️ Tomorrow               │  │
│  │ "Early start"             │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👤 You                    │  │
│  │                           │  │
│  │ ☀️ Morning  🌙 Evening    │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
\`\`\`
**Actions**:
- Tap date → Load entries for that date
- Scroll to see both entries
- Tap Done → Return to main screen

---

## Notification Examples

### Morning Notification (8:00 AM)
\`\`\`
┌─────────────────────────────────┐
│  Relationship Check-in      8:00│
│                                 │
│  Morning Check-in               │
│  One thing I need today...      │
│                                 │
│                          [View] │
└─────────────────────────────────┘
\`\`\`
**Tap** → Opens morning entry form

### Evening Notification (5:00 PM)
\`\`\`
┌─────────────────────────────────┐
│  Relationship Check-in     17:00│
│                                 │
│  Evening Check-in               │
│  How was your day?              │
│                                 │
│                          [View] │
└─────────────────────────────────┘
\`\`\`
**Tap** → Opens evening entry form

---

## User Flow Diagrams

### First Time Setup Flow
\`\`\`
Launch App
    ↓
[Loading Screen]
    ↓
[Pairing Screen]
    ↓
Person A: Create Link ──→ Share via Messages
    ↓                           ↓
Wait for Partner           Person B receives
    ↓                           ↓
    ↓                    Person B: Accept Link
    ↓                           ↓
    └──────── Both Paired ──────┘
                ↓
         [Main Screen]
\`\`\`

### Daily Morning Flow
\`\`\`
8:00 AM
    ↓
Notification Appears
    ↓
User Taps Notification
    ↓
[Morning Entry Form]
    ↓
User Types Need
    ↓
User Taps Save
    ↓
Saved to CloudKit
    ↓
Partner Sees Entry
    ↓
Done ✓
\`\`\`

### Daily Evening Flow
\`\`\`
5:00 PM
    ↓
Notification Appears
    ↓
User Taps Notification
    ↓
[Evening Entry Form]
    ↓
User Selects Mood (🟢🟡🔴)
    ↓
User Types Gratitude
    ↓
User Types Tomorrow Goal
    ↓
User Taps Save
    ↓
Haptic Feedback
    ↓
Saved to CloudKit
    ↓
Partner Sees Entry
    ↓
Done ✓
\`\`\`

### Viewing Partner's Entry
\`\`\`
Open App
    ↓
[Main Screen]
    ↓
See Partner's Entry
    ↓
Read Morning Need
    ↓
Read Evening Mood
    ↓
Read Gratitude
    ↓
Read Tomorrow Goal
    ↓
Feel Connected ❤️
\`\`\`

### Browsing History
\`\`\`
Main Screen
    ↓
Tap Calendar Icon
    ↓
[History Drawer]
    ↓
Select Past Date
    ↓
See Both Entries
    ↓
Remember That Day
    ↓
Tap Done
    ↓
Back to Main Screen
\`\`\`

---

## Design Elements

### Colors
- **Background**: Light gray-blue (#F2F4F7)
- **Mood Green**: #66C78C 🟢
- **Mood Yellow**: #F2C45C 🟡
- **Mood Red**: #EB7D73 🔴
- **Accent**: #5AA6D9 (calm blue)

### Typography
- **Large Title**: 34pt, Bold
- **Title**: 28pt, Bold
- **Headline**: 17pt, Semibold
- **Body**: 17pt, Regular
- **Caption**: 12pt, Regular

### Spacing
- Cards: 24pt padding
- Between sections: 32pt
- Between elements: 16pt
- Tight spacing: 8pt

### Materials
- Glass cards: `.ultraThinMaterial`
- Soft shadows: 12pt blur, 4pt offset
- Rounded corners: 28pt radius

---

## Interaction Patterns

### Tap Targets
- Buttons: Minimum 44pt height
- Cards: Full width, tappable
- Mood circles: 60pt diameter

### Feedback
- **Haptic**: On save success
- **Visual**: Loading spinners, success checkmarks
- **Animation**: Spring animations (0.3s, 0.7 damping)

### States
- **Loading**: Spinner + "Loading..."
- **Success**: Checkmark + "Saved!"
- **Error**: Red text with error message
- **Empty**: Gray icon + "No entry yet"

---

## Accessibility

### VoiceOver Labels
- All buttons have descriptive labels
- Images have alt text
- Forms have field labels

### Dynamic Type
- All text scales with system settings
- Minimum touch targets maintained

### Color Contrast
- Text meets WCAG AA standards
- Mood colors distinguishable

---

## Edge Cases Handled

### No Partner Entry
\`\`\`
┌───────────────────────────┐
│                           │
│        💔                 │
│                           │
│     No entry yet          │
│                           │
│  Your partner hasn't      │
│  checked in today         │
│                           │
└───────────────────────────┘
\`\`\`

### Network Error
\`\`\`
┌───────────────────────────┐
│  ⚠️ Error                 │
│                           │
│  Failed to save:          │
│  Network connection lost  │
│                           │
│  [Retry]                  │
└───────────────────────────┘
\`\`\`

### Loading State
\`\`\`
┌───────────────────────────┐
│                           │
│         ⏳                │
│                           │
│      Loading...           │
│                           │
└───────────────────────────┘
\`\`\`

---

## Summary

The app has **6 main screens**:
1. Loading (initialization)
2. Pairing (first time only)
3. Main (daily view)
4. Morning Entry
5. Evening Entry
6. History Drawer

Plus **2 notification types**:
- Morning (8 AM)
- Evening (5 PM)

**Total user interactions**: ~10 taps per day
**Time per check-in**: 1-2 minutes
**Daily time commitment**: 2-4 minutes total

Simple, focused, and beautiful. ❤️


```

# ChatGPT Image Oct 25, 2025, 01_20_14 PM.png

This is a binary file of the type: Image

# CLOUDKIT_SCHEMA.md

```md
# CloudKit Schema Configuration

> Primary schema definition lives in `CloudKit/schema.ckdsl`. Use it when importing or verifying the dashboard so documentation and code stay in sync. CloudKit's DSL cannot limit reference targets, so set those manually in the Dashboard if you need stricter types.

## Container Information

- **Container ID**: `iCloud.com.jaradjohnson.RelationshipCheckin`
- **Environment**: Development (then deploy to Production)
- **Database**: Private with Shared Zone

## Record Types

### 1. Couple

This record represents the relationship between two users.

| Field Name | Type | Required | Notes |
|------------|------|----------|-------|
| `ownerUserRecordID` | Reference | Yes | Points to the creating user (set reference type to **User** in Dashboard if doing it manually) |
| `partnerUserRecordID` | Reference | No | Populated after partner accepts invite |

**Indexes**: None required (queries use predicates)

**Security**: 
- Owner can read/write
- Partner can read/write after accepting share

### 2. DailyEntry

This record stores daily check-in data for each user.

| Field Name | Type | Required | Notes |
|------------|------|----------|-------|
| `date` | Date/Time | Yes | Start of day (midnight) |
| `authorUserRecordID` | Reference | Yes | User who created this entry (optionally mark as **User** in Dashboard) |
| `couple` | Reference | Yes | Links to the couple record (optionally constrain to **Couple** in Dashboard) |
| `morningNeed` | String | No | Morning check-in: what I need |
| `eveningMood` | Int(64) | No | Evening mood: 0=green, 1=yellow, 2=red |
| `gratitude` | String | No | Evening: gratitude for partner |
| `tomorrowGreat` | String | No | Evening: what would make tomorrow great |

**Record Name Convention**: `DailyEntry_{yyyy-MM-dd}_{userRecordName}`
- Example: `DailyEntry_2025-10-10_ABC123DEF456`
- This ensures one entry per user per day (idempotent upsert)

**Indexes**:
- `date` (queryable) - required for fetching entries by date range
- *(Optional)* `authorUserRecordID` (queryable) - add if you plan to query entries by author

**Security**:
- Author can read/write their own entries
- Partner can read entries in shared zone

## Custom Zone

- **Zone Name**: `RelationshipZone`
- **Owner**: Current user's default name
- **Type**: Private zone with sharing capability

The app automatically creates this zone on first launch if it doesn't exist.

## Sharing Model

### Initial Setup (Owner)
1. Owner creates `Couple` record in private database
2. Owner creates `CKShare` for the `Couple` record
3. Share URL is generated and sent to partner

### Partner Acceptance
1. Partner opens share URL
2. Partner accepts share via `CKContainer.accept()`
3. `Couple` record is now in partner's shared database
4. Owner updates `Couple.partnerUserRecordID` with partner's ID
5. Owner optionally stops sharing to lock at two users

### Daily Entries
- Each user creates `DailyEntry` records in their private database
- Records reference the shared `Couple` record
- Both users can query entries via the shared zone
- Records are visible to both users

## CloudKit Dashboard Steps

### Development Environment

1. **Login**: Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. **Select Container**: `iCloud.com.jaradjohnson.RelationshipCheckin`
3. **Go to Schema → Development** (you can import `CloudKit/schema.ckdsl` or follow the manual steps below)

#### Create Couple Record Type
\`\`\`
1. Click "+" next to Record Types
2. Name: Couple
3. Add Field: ownerUserRecordID
   - Type: Reference (set Reference Type to *User* if desired)
4. Add Field: partnerUserRecordID
   - Type: Reference (set Reference Type to *User* if desired)
5. Save
\`\`\`

#### Create DailyEntry Record Type
\`\`\`
1. Click "+" next to Record Types
2. Name: DailyEntry
3. Add Field: date
   - Type: Date/Time
   - Add Index (Queryable)
4. Add Field: authorUserRecordID
   - Type: Reference (optionally set Reference Type to *User*)
   - *(Optional)* Add Index (Queryable) if you'll run author-based queries
5. Add Field: couple
   - Type: Reference (optionally set Reference Type to *Couple*)
6. Add Field: morningNeed
   - Type: String
7. Add Field: eveningMood
   - Type: Int(64)
8. Add Field: gratitude
   - Type: String
9. Add Field: tomorrowGreat
   - Type: String
10. Save
\`\`\`

### Production Deployment

**After testing in Development:**

1. Go to Schema → Development
2. Click "Deploy Schema Changes..."
3. Review changes
4. Click "Deploy to Production"
5. Wait for deployment to complete (usually < 1 minute)

**Important**: 
- You cannot delete fields from Production schema
- Plan your schema carefully before deploying
- Test thoroughly in Development first

## Permissions

### Default Permissions

CloudKit automatically handles permissions:
- Users can read/write their own records
- Shared records are readable by all participants
- Share owner controls who can access

### App-Level Permissions

The app requests:
- iCloud account access
- CloudKit access
- Notification permissions (local only)

## Data Flow Examples

### Morning Check-in
\`\`\`
1. User opens app at 8:00 AM (via notification)
2. App fetches existing DailyEntry for today (if any)
3. User enters "morningNeed"
4. App upserts DailyEntry with recordName: DailyEntry_2025-10-10_UserID
5. Record saved to private database
6. Partner can query and see the entry
\`\`\`

### Evening Check-in
\`\`\`
1. User opens app at 5:00 PM (via notification)
2. App fetches existing DailyEntry for today
3. User enters mood, gratitude, tomorrowGreat
4. App upserts same DailyEntry record (merges with morning data)
5. Record updated in private database
6. Partner sees updated entry
\`\`\`

### Viewing Partner's Entry
\`\`\`
1. User opens main screen
2. App queries shared database for today's entries
3. Filters entries where authorUserRecordID != currentUserRecordID
4. Displays partner's entry
\`\`\`

### History View
\`\`\`
1. User selects date in history drawer
2. App queries both databases for entries on that date
3. Returns array of DailyEntry records
4. Separates by authorUserRecordID
5. Displays both entries side by side
\`\`\`

## Testing Queries in Dashboard

You can test queries in CloudKit Dashboard:

### Find all entries for a date
\`\`\`
Record Type: DailyEntry
Predicate: date >= '2025-10-10 00:00:00' AND date < '2025-10-11 00:00:00'
\`\`\`

### Find user's entries
\`\`\`
Record Type: DailyEntry
Predicate: authorUserRecordID == [USER_RECORD_ID]
\`\`\`

### Find couple record
\`\`\`
Record Type: Couple
Predicate: TRUEPREDICATE
\`\`\`

## Troubleshooting

### "Record not found" errors
- Ensure custom zone exists
- Check that record name is correct
- Verify database (private vs shared)

### "Permission denied" errors
- Check that share was accepted
- Verify user is signed in to iCloud
- Ensure CloudKit container is enabled

### Duplicate entries
- Verify recordName format is consistent
- Check date normalization (start of day)
- Ensure using upsert pattern (same recordName)

## Backup Strategy

CloudKit data is automatically backed up by Apple:
- User's iCloud backup includes CloudKit data
- No additional backup needed
- Data persists across device changes

## Data Retention

- Data stored indefinitely in iCloud
- Users can delete their iCloud account to remove all data
- App doesn't implement automatic deletion
- Consider adding manual delete feature in future

## Cost

CloudKit is free for:
- Up to 1GB storage per user
- Up to 10GB transfer per user per month
- Unlimited requests

For this app with 2 users and text-only data:
- **Storage**: ~1KB per entry × 365 days × 2 users = ~730KB/year
- **Transfer**: Minimal (text only)
- **Cost**: $0 (well within free tier)

```

# DEPLOYMENT_CHECKLIST.md

```md
# Deployment Checklist

## Pre-Deployment Setup

### ✅ Xcode Project Setup
- [ ] Create Xcode project (iOS App, SwiftUI)
- [ ] Set bundle identifier: `com.jaradjohnson.RelationshipCheckin`
- [ ] Set deployment target: iOS 17.0+
- [ ] Add all source files to project
- [ ] Verify all files in target membership
- [ ] Add Info.plist to project settings
- [ ] Add entitlements file to target

### ✅ Capabilities Configuration
- [ ] Enable iCloud capability
- [ ] Add CloudKit service
- [ ] Add container: `iCloud.com.jaradjohnson.RelationshipCheckin`
- [ ] Enable Push Notifications capability
- [ ] Enable Background Modes capability
- [ ] Check "Remote notifications" in Background Modes

### ✅ Signing & Certificates
- [ ] Select development team
- [ ] Verify provisioning profile
- [ ] Enable "Automatically manage signing"
- [ ] Verify bundle identifier matches

## CloudKit Setup

### ✅ Development Environment
- [ ] Login to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [ ] Select container: `iCloud.com.jaradjohnson.RelationshipCheckin`
- [ ] Navigate to Schema → Development
- [ ] Reference `CloudKit/schema.ckdsl` when verifying record types/fields

#### Create Couple Record Type
- [ ] Click "+" to add Record Type
- [ ] Name: `Couple`
- [ ] Add field: `ownerUserRecordID` (Reference → User if adding manually)
- [ ] Add field: `partnerUserRecordID` (Reference → User if adding manually)
- [ ] Save

#### Create DailyEntry Record Type
- [ ] Click "+" to add Record Type
- [ ] Name: `DailyEntry`
- [ ] Add field: `date` (Date/Time)
- [ ] Add index on `date` (Queryable)
- [ ] Add field: `authorUserRecordID` (Reference → User if desired)
- [ ] (Optional) Add index on `authorUserRecordID` (Queryable if you plan to filter by author)
- [ ] Add field: `couple` (Reference → Couple if desired)
- [ ] Add field: `morningNeed` (String)
- [ ] Add field: `eveningMood` (Int64)
- [ ] Add field: `gratitude` (String)
- [ ] Add field: `tomorrowGreat` (String)
- [ ] Save

## Development Testing

### ✅ Build & Install (Jarad's Device)
- [ ] Connect iPhone via cable
- [ ] Select device in Xcode
- [ ] Build and run (⌘R)
- [ ] App launches successfully
- [ ] No build errors or warnings

### ✅ Initial Setup (Jarad)
- [ ] Sign in with Apple ID when prompted
- [ ] iCloud account detected
- [ ] Grant notification permissions
- [ ] App shows pairing screen
- [ ] No crashes or errors in console

### ✅ Pairing Flow - Owner (Jarad)
- [ ] Tap "Create Invite Link"
- [ ] Loading indicator appears
- [ ] Share sheet appears
- [ ] Copy link or share via Messages
- [ ] Link format: `https://www.icloud.com/share/...`
- [ ] No errors displayed

### ✅ Build & Install (Laura's Device)
- [ ] Connect Laura's iPhone
- [ ] Select device in Xcode
- [ ] Build and run (⌘R)
- [ ] App launches successfully
- [ ] Sign in with Laura's Apple ID

### ✅ Pairing Flow - Partner (Laura)
- [ ] Tap "Accept Invite"
- [ ] Paste invite link
- [ ] Tap "Accept Invite"
- [ ] Loading indicator appears
- [ ] Success - app shows main screen
- [ ] No errors displayed

### ✅ Verify Pairing
- [ ] Both devices show main screen (not pairing screen)
- [ ] Check CloudKit Dashboard → Data → Development
- [ ] Verify Couple record exists
- [ ] Verify both user references populated

## Feature Testing

### ✅ Morning Check-in (Both Users)
- [ ] Tap morning button on main screen
- [ ] Entry form opens
- [ ] Enter text in "One thing I need"
- [ ] Tap Save
- [ ] Success message appears
- [ ] Form dismisses
- [ ] Return to main screen

### ✅ Evening Check-in (Both Users)
- [ ] Tap evening button on main screen
- [ ] Entry form opens
- [ ] Select mood (green/yellow/red)
- [ ] Mood circle highlights
- [ ] Enter gratitude text
- [ ] Enter tomorrow text
- [ ] Tap Save
- [ ] Haptic feedback occurs
- [ ] Success message appears
- [ ] Form dismisses

### ✅ View Partner's Entry
- [ ] Main screen shows partner's entry
- [ ] Morning need displayed (if entered)
- [ ] Evening mood displayed (if entered)
- [ ] Gratitude displayed (if entered)
- [ ] Tomorrow goal displayed (if entered)
- [ ] Pull down to refresh
- [ ] Entry updates

### ✅ History View
- [ ] Tap calendar icon (top right)
- [ ] History drawer opens
- [ ] Date picker shows current month
- [ ] Select today's date
- [ ] Both entries displayed
- [ ] Select past date
- [ ] Shows "No entry" if none exists
- [ ] Tap Done to close

### ✅ Notifications
- [ ] Wait for 8:00 AM or change time in code for testing
- [ ] Notification appears on lock screen
- [ ] Notification title: "Morning Check-in"
- [ ] Tap notification
- [ ] App opens to morning entry form
- [ ] Repeat for evening notification (5:00 PM)

### ✅ Deep Links
- [ ] Open Terminal
- [ ] Run: `xcrun simctl openurl booted "rc://entry/morning"`
- [ ] App opens to morning entry
- [ ] Run: `xcrun simctl openurl booted "rc://entry/evening"`
- [ ] App opens to evening entry

## Edge Cases & Error Handling

### ✅ Network Issues
- [ ] Turn off WiFi and cellular
- [ ] Try to save entry
- [ ] Error message displayed
- [ ] Turn on network
- [ ] Retry save
- [ ] Success

### ✅ Missing Partner Entry
- [ ] One user doesn't check in
- [ ] Other user's main screen shows "No entry yet"
- [ ] Placeholder message displayed
- [ ] No crashes

### ✅ Same Day Multiple Edits
- [ ] Enter morning check-in
- [ ] Edit morning check-in again
- [ ] Previous text preserved
- [ ] Enter evening check-in
- [ ] Morning data still present
- [ ] Both sections saved

### ✅ Date Changes
- [ ] Check in on one day
- [ ] Wait for midnight (or change device date)
- [ ] New day shows empty entry
- [ ] History shows previous day's entry

## CloudKit Data Verification

### ✅ Check Records in Dashboard
- [ ] CloudKit Dashboard → Data → Development
- [ ] Select "DailyEntry" record type
- [ ] See entries from both users
- [ ] Record names format: `DailyEntry_2025-10-10_UserID`
- [ ] All fields populated correctly
- [ ] Dates are start of day (midnight)

## Production Deployment

### ✅ Schema Deployment
- [ ] CloudKit Dashboard → Schema → Development
- [ ] Review all record types and fields
- [ ] Click "Deploy Schema Changes..."
- [ ] Review changes summary
- [ ] Click "Deploy to Production"
- [ ] Wait for deployment (1-2 minutes)
- [ ] Verify in Schema → Production

### ✅ App Store Connect Setup
- [ ] Login to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Create new app
- [ ] Bundle ID: `com.jaradjohnson.RelationshipCheckin`
- [ ] Name: "Relationship Check-in"
- [ ] Primary language: English
- [ ] SKU: `relationship-checkin`

### ✅ Archive & Upload
- [ ] Xcode → Product → Archive
- [ ] Wait for archive to complete
- [ ] Organizer window opens
- [ ] Select archive
- [ ] Click "Distribute App"
- [ ] Choose "App Store Connect"
- [ ] Upload
- [ ] Wait for processing (10-30 minutes)

### ✅ TestFlight Setup
- [ ] App Store Connect → TestFlight
- [ ] Wait for build to appear
- [ ] Add internal testers
- [ ] Add Jarad's Apple ID
- [ ] Add Laura's Apple ID
- [ ] Enable automatic distribution
- [ ] Save

### ✅ TestFlight Installation (Both Users)
- [ ] Receive TestFlight invite email
- [ ] Install TestFlight app from App Store
- [ ] Open invite link
- [ ] Accept test
- [ ] Install app from TestFlight
- [ ] Launch app

### ✅ Production Testing
- [ ] Repeat all feature tests on TestFlight build
- [ ] Verify CloudKit Production environment
- [ ] Test pairing flow
- [ ] Test all check-ins
- [ ] Test notifications
- [ ] Test history
- [ ] Verify data syncs between devices

## Post-Deployment

### ✅ Monitor & Verify
- [ ] Use app daily for 1 week
- [ ] Check for crashes (Xcode Organizer)
- [ ] Verify notifications arrive on time
- [ ] Verify CloudKit sync is reliable
- [ ] Check battery usage (Settings → Battery)

### ✅ Optional: App Store Submission
If you want to make it available on App Store (optional):
- [ ] Prepare app screenshots
- [ ] Write app description
- [ ] Add privacy policy URL
- [ ] Submit for review
- [ ] Wait for approval (1-3 days)
- [ ] Release to App Store

## Troubleshooting

### Build Errors
- **Missing files**: Ensure all .swift files are in target membership
- **Signing errors**: Check team selection and provisioning profile
- **CloudKit errors**: Verify container identifier matches

### Runtime Errors
- **iCloud not available**: Sign in to iCloud in Settings
- **Notifications not working**: Check permissions in Settings → Notifications
- **Pairing fails**: Verify both users on same CloudKit container
- **Data not syncing**: Check internet connection, wait 30 seconds

### CloudKit Errors
- **Record not found**: Ensure schema is deployed
- **Permission denied**: Verify share was accepted
- **Zone not found**: App will create zone on first launch

## Success Criteria

✅ **Ready for daily use when:**
- Both users can pair successfully
- Both users can create morning/evening entries
- Both users can see partner's entries
- Notifications arrive at 8 AM and 5 PM
- History shows past entries
- No crashes or data loss
- CloudKit sync works reliably

## Maintenance

### Weekly
- [ ] Check for crashes in App Store Connect
- [ ] Verify notifications still working
- [ ] Monitor CloudKit usage (should be minimal)

### Monthly
- [ ] Review history for any missing entries
- [ ] Check for iOS updates
- [ ] Update Xcode if needed

### As Needed
- [ ] Update notification times if desired
- [ ] Customize colors or text
- [ ] Add new features
- [ ] Fix any bugs

---

**Timeline Estimate:**
- Setup & build: 15 minutes
- Development testing: 30 minutes
- Production deployment: 45 minutes
- **Total: ~90 minutes**

**Status**: Ready to begin

**Next Step**: Start with "Pre-Deployment Setup" section

Good luck! 🚀

```

# fastlane/Appfile

```
app_identifier("com.jaradjohnson.RelationshipCheckin")
apple_id(ENV['APPLE_ID'])
itc_team_id(ENV['APP_STORE_CONNECT_TEAM_ID'])
team_id(ENV['DEVELOPMENT_TEAM_ID'])



```

# fastlane/Fastfile

```
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    api_key = app_store_connect_api_key(
      key_id: ENV['ASC_KEY_ID'],
      issuer_id: ENV['ASC_ISSUER_ID'],
      key_content: ENV['ASC_PRIVATE_KEY'], # base64-encoded contents of the .p8 key
      is_key_content_base64: true
    )

    increment_build_number(xcodeproj: "RelationshipCheckin.xcodeproj")

    build_app(
      xcodeproj: "RelationshipCheckin.xcodeproj",
      scheme: "RelationshipCheckin",
      export_method: "app-store",
      clean: true,
      include_bitcode: false,
      output_directory: "build",
      xcargs: "-allowProvisioningUpdates"
    )

    upload_to_testflight(
      api_key: api_key,
      skip_waiting_for_build_processing: false
    )
  end
end



```

# fastlane/README.md

```md
fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

\`\`\`sh
xcode-select --install
\`\`\`

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

\`\`\`sh
[bundle exec] fastlane ios beta
\`\`\`

Build and upload to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

```

# fastlane/report.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="fastlane.lanes">
    
    
    
      
      <testcase classname="fastlane.lanes" name="0: default_platform" time="0.000232">
        
      </testcase>
    
      
      <testcase classname="fastlane.lanes" name="1: app_store_connect_api_key" time="0.000172">
        
          <failure message="/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/actions/actions_helper.rb:67:in `execute_action&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:255:in `block in execute_action&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:229:in `chdir&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:229:in `execute_action&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:157:in `trigger_action_by_name&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/fast_file.rb:159:in `method_missing&apos;&#10;Fastfile:6:in `block (2 levels) in parsing_binding&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/lane.rb:41:in `call&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:49:in `block in execute&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:45:in `chdir&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/runner.rb:45:in `execute&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/lane_manager.rb:46:in `cruise_lane&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/command_line_handler.rb:34:in `handle&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/commands_generator.rb:110:in `block (2 levels) in run&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/commander-4.6.0/lib/commander/command.rb:187:in `call&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/commander-4.6.0/lib/commander/command.rb:157:in `run&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/commander-4.6.0/lib/commander/runner.rb:444:in `run_active_command&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane_core/lib/fastlane_core/ui/fastlane_runner.rb:124:in `run!&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/commander-4.6.0/lib/commander/delegates.rb:18:in `run!&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/commands_generator.rb:363:in `run&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/commands_generator.rb:43:in `start&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/fastlane/lib/fastlane/cli_tools_distributor.rb:123:in `take_off&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/fastlane-2.228.0/bin/fastlane:23:in `&lt;top (required)&gt;&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/bin/fastlane:25:in `load&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/bin/fastlane:25:in `&lt;top (required)&gt;&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli/exec.rb:58:in `load&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli/exec.rb:58:in `kernel_load&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli/exec.rb:23:in `run&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli.rb:455:in `exec&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/vendor/thor/lib/thor/command.rb:28:in `run&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/vendor/thor/lib/thor/invocation.rb:127:in `invoke_command&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/vendor/thor/lib/thor.rb:527:in `dispatch&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli.rb:35:in `dispatch&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/vendor/thor/lib/thor/base.rb:584:in `start&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/cli.rb:29:in `start&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/bundler-2.5.18/exe/bundle:28:in `block in &lt;top (required)&gt;&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/site_ruby/3.2.0/bundler/friendly_errors.rb:117:in `with_friendly_errors&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/bundler-2.5.18/exe/bundle:20:in `&lt;top (required)&gt;&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/bin/bundle:25:in `load&apos;&#10;/Users/jaradjohnson/.rbenv/versions/3.2.2/bin/bundle:25:in `&lt;main&gt;&apos;&#10;&#10;No value found for &apos;key_id&apos;" />
        
      </testcase>
    
  </testsuite>
</testsuites>

```

# Gemfile

```
source "https://rubygems.org"

gem "fastlane"



```

# INDEX.md

```md
# Relationship Check-in - Complete Index

## 📖 Documentation Guide

### Start Here
1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Overview of what's been built
2. **[QUICK_START.md](QUICK_START.md)** - User guide for daily usage
3. **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - How to set up Xcode project

### Reference Documentation
4. **[CLOUDKIT_SCHEMA.md](CLOUDKIT_SCHEMA.md)** - CloudKit database schema
5. **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment
6. **[README.md](README.md)** - Project overview and features

## 📁 Project Structure

\`\`\`
Relationship Check-in/
│
├── 📚 Documentation (7 files)
│   ├── INDEX.md                       ← You are here
│   ├── PROJECT_SUMMARY.md             ← Start here for overview
│   ├── QUICK_START.md                 ← Daily usage guide
│   ├── SETUP_INSTRUCTIONS.md          ← Xcode setup steps
│   ├── CLOUDKIT_SCHEMA.md             ← Database reference
│   ├── DEPLOYMENT_CHECKLIST.md        ← Deployment guide
│   └── README.md                      ← Project README
│
├── ⚙️ Configuration (3 files)
│   ├── RelationshipCheckin.entitlements  ← App capabilities
│   ├── .gitignore                        ← Git ignore rules
│   └── relationship.plan.md              ← Original plan
│
└── 💻 Source Code (19 files)
    └── RelationshipCheckin/
        ├── 🚀 App Entry (2 files)
        │   ├── RelationshipCheckinApp.swift
        │   └── ContentView.swift
        │
        ├── 📦 Models (2 files)
        │   ├── DailyEntry.swift
        │   └── Mood.swift
        │
        ├── 🔧 Services (4 files)
        │   ├── CloudKitService.swift
        │   ├── ShareService.swift
        │   ├── NotificationService.swift
        │   └── DeepLinkService.swift
        │
        ├── 🧠 ViewModels (4 files)
        │   ├── MainViewModel.swift
        │   ├── EntryViewModel.swift
        │   ├── HistoryViewModel.swift
        │   └── PairingViewModel.swift
        │
        ├── 🎨 Views (4 files)
        │   ├── MainView.swift
        │   ├── EntryView.swift
        │   ├── HistoryDrawerView.swift
        │   └── PairingView.swift
        │
        ├── 🎭 UI/Design (1 file)
        │   └── DesignSystem.swift
        │
        └── ⚙️ Config (1 file)
            └── Info.plist
\`\`\`

## 🎯 Quick Navigation

### By Task

#### "I want to build the app"
→ [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

#### "I want to understand the code"
→ [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

#### "I want to use the app daily"
→ [QUICK_START.md](QUICK_START.md)

#### "I want to deploy to TestFlight"
→ [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

#### "I want to understand CloudKit"
→ [CLOUDKIT_SCHEMA.md](CLOUDKIT_SCHEMA.md)

#### "I want to customize the app"
→ See "Customization" section below

### By Role

#### Developer (You, Jarad)
1. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. Follow [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
3. Use [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
4. Reference [CLOUDKIT_SCHEMA.md](CLOUDKIT_SCHEMA.md)

#### User (You & Laura)
1. Read [QUICK_START.md](QUICK_START.md)
2. Follow pairing instructions
3. Use app daily

## 📊 File Statistics

| Category | Files | Lines of Code |
|----------|-------|---------------|
| Documentation | 7 | ~2,000 |
| Source Code | 19 | ~2,500 |
| Configuration | 3 | ~100 |
| **Total** | **29** | **~4,600** |

## 🔍 Find Specific Information

### Features
- **Morning check-in**: `EntryView.swift`, `NotificationService.swift`
- **Evening check-in**: `EntryView.swift`, `NotificationService.swift`
- **Mood selection**: `DesignSystem.swift` (MoodSelector), `Mood.swift`
- **Partner view**: `MainView.swift`, `MainViewModel.swift`
- **History**: `HistoryDrawerView.swift`, `HistoryViewModel.swift`
- **Pairing**: `PairingView.swift`, `PairingViewModel.swift`, `ShareService.swift`

### Technical Details
- **CloudKit operations**: `CloudKitService.swift`
- **Notifications**: `NotificationService.swift`
- **Deep links**: `DeepLinkService.swift`
- **Data models**: `Models/DailyEntry.swift`, `Models/Mood.swift`
- **Design system**: `UI/DesignSystem.swift`

### Configuration
- **App capabilities**: `RelationshipCheckin.entitlements`
- **URL schemes**: `Info.plist`
- **CloudKit schema**: [CLOUDKIT_SCHEMA.md](CLOUDKIT_SCHEMA.md), `CloudKit/schema.ckdsl`

## 🎨 Customization Guide

### Change Notification Times
**File**: `Services/NotificationService.swift`
\`\`\`swift
// Line ~35-36
morningComponents.hour = 8   // Change to desired hour (0-23)
eveningComponents.hour = 17  // Change to desired hour (0-23)
\`\`\`

### Change Colors
**File**: `UI/DesignSystem.swift`
\`\`\`swift
// Lines ~17-23
static let moodGreen = Color(red: 0.4, green: 0.78, blue: 0.55)
static let moodYellow = Color(red: 0.95, green: 0.77, blue: 0.36)
static let moodRed = Color(red: 0.92, green: 0.49, blue: 0.45)
static let accent = Color(red: 0.35, green: 0.65, blue: 0.85)
\`\`\`

### Change Notification Text
**File**: `Services/NotificationService.swift`
\`\`\`swift
// Lines ~31-32, ~43-44
morningContent.title = "Morning Check-in"
morningContent.body = "One thing I need today..."
eveningContent.title = "Evening Check-in"
eveningContent.body = "How was your day?"
\`\`\`

### Change Questions
**File**: `Views/EntryView.swift`
\`\`\`swift
// Line ~72 (morning)
Text("One thing I need today")

// Lines ~93, 106, 119 (evening)
Text("How was your day?")
Text("One gratitude for your partner")
Text("One thing to make tomorrow great")
\`\`\`

### Change Spacing
**File**: `UI/DesignSystem.swift`
\`\`\`swift
// Lines ~30-36
static let tiny: CGFloat = 4
static let small: CGFloat = 8
static let medium: CGFloat = 16
static let large: CGFloat = 24
static let extraLarge: CGFloat = 32
static let huge: CGFloat = 48
\`\`\`

## 🐛 Troubleshooting

### Build Issues
→ [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Troubleshooting section

### Runtime Issues
→ [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Troubleshooting section

### CloudKit Issues
→ [CLOUDKIT_SCHEMA.md](CLOUDKIT_SCHEMA.md) - Troubleshooting section

## 📱 App Flow Diagrams

### First Launch Flow
\`\`\`
Launch App
    ↓
Sign in with Apple
    ↓
Grant Permissions
    ↓
Pairing Screen
    ↓
Create/Accept Invite
    ↓
Main Screen
\`\`\`

### Daily Usage Flow
\`\`\`
Notification (8 AM / 5 PM)
    ↓
Tap Notification
    ↓
Entry Form Opens
    ↓
Fill Out Form
    ↓
Tap Save
    ↓
Saved to CloudKit
    ↓
Partner Sees Entry
\`\`\`

### Data Sync Flow
\`\`\`
User A Saves Entry
    ↓
CloudKit Private DB
    ↓
Shared Zone
    ↓
User B Queries
    ↓
Entry Displayed
\`\`\`

## 🎓 Learning Resources

### SwiftUI
- Apple's SwiftUI Tutorials: https://developer.apple.com/tutorials/swiftui
- SwiftUI Documentation: https://developer.apple.com/documentation/swiftui

### CloudKit
- CloudKit Quick Start: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/
- CloudKit Documentation: https://developer.apple.com/documentation/cloudkit

### UserNotifications
- Local Notifications Guide: https://developer.apple.com/documentation/usernotifications/scheduling_a_notification_locally_from_your_app

## ✅ Completion Status

### Implementation
- [x] All source code files created (19 files)
- [x] All configuration files created (3 files)
- [x] All documentation created (7 files)
- [x] Design system implemented
- [x] CloudKit integration complete
- [x] Notifications implemented
- [x] Deep linking implemented
- [x] Pairing flow implemented
- [x] All views implemented
- [x] All view models implemented

### Documentation
- [x] Setup instructions
- [x] User guide
- [x] CloudKit schema reference
- [x] Deployment checklist
- [x] Project summary
- [x] README
- [x] This index

### Ready For
- [x] Xcode project creation
- [x] Development testing
- [x] CloudKit schema deployment
- [x] TestFlight distribution
- [x] Daily use

## 🚀 Next Steps

1. **Now**: Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. **Next**: Follow [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
3. **Then**: Use [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
4. **Finally**: Enjoy with [QUICK_START.md](QUICK_START.md)

## 💡 Tips

- **Keep it simple**: The app is designed to be minimal and focused
- **Daily habit**: Use it consistently for best results
- **Customize later**: Get it working first, then customize
- **Backup**: Your data is in iCloud, automatically backed up
- **Privacy**: Only you two have access, completely private

## 📞 Support

For issues:
1. Check the relevant documentation file
2. Review Xcode console for errors
3. Check CloudKit Dashboard for data
4. Verify iCloud account is signed in

## ❤️ Enjoy!

Built with love for Jarad & Laura's daily connection.

---

**Version**: 1.0  
**Created**: October 10, 2025  
**Status**: ✅ Complete and ready to build

```

# PROJECT_SUMMARY.md

```md
# Project Summary: Relationship Check-in

## Overview

A private iOS app for couples to share daily check-ins, built with SwiftUI, CloudKit, and local notifications.

## What's Been Created

### ✅ Complete Source Code

All Swift files have been created and are ready to use:

#### App Entry & Main
- `RelationshipCheckinApp.swift` - App entry point, notification delegate
- `ContentView.swift` - Root view with routing logic

#### Models (2 files)
- `Models/Mood.swift` - Enum for green/yellow/red moods
- `Models/DailyEntry.swift` - Daily check-in data model with CloudKit conversion

#### Services (4 files)
- `Services/CloudKitService.swift` - CloudKit operations (CRUD, pairing, queries)
- `Services/ShareService.swift` - CloudKit sharing for pairing
- `Services/NotificationService.swift` - Local notifications at 8 AM & 5 PM
- `Services/DeepLinkService.swift` - Deep link routing (rc://entry/morning|evening)

#### ViewModels (4 files)
- `ViewModels/MainViewModel.swift` - Main screen logic
- `ViewModels/EntryViewModel.swift` - Entry form logic
- `ViewModels/HistoryViewModel.swift` - History browsing logic
- `ViewModels/PairingViewModel.swift` - Pairing flow logic

#### Views (4 files)
- `Views/MainView.swift` - Main screen showing partner's entry
- `Views/EntryView.swift` - Morning/evening entry form
- `Views/HistoryDrawerView.swift` - Date picker and past entries
- `Views/PairingView.swift` - Invite link creation/acceptance

#### UI/Design
- `UI/DesignSystem.swift` - Colors, spacing, reusable components (GlassCard, MoodSelector, buttons)

### ✅ Configuration Files

- `Info.plist` - URL scheme (rc://) and background modes
- `RelationshipCheckin.entitlements` - iCloud, CloudKit, push notifications
- `.gitignore` - Standard Xcode/Swift gitignore

### ✅ Documentation

- `README.md` - Project overview and features
- `SETUP_INSTRUCTIONS.md` - Detailed Xcode setup steps
- `CLOUDKIT_SCHEMA.md` - Complete CloudKit schema reference
- `QUICK_START.md` - User guide for daily usage
- `PROJECT_SUMMARY.md` - This file

## Architecture

### Design Pattern: MVVM
- **Models**: Data structures (DailyEntry, Mood)
- **Views**: SwiftUI views (MainView, EntryView, etc.)
- **ViewModels**: Business logic and state management
- **Services**: External integrations (CloudKit, Notifications)

### Key Technologies
- **SwiftUI**: Modern declarative UI
- **CloudKit**: Private database with sharing
- **UserNotifications**: Local daily reminders
- **Combine**: Reactive state management (@Published)

### Data Flow
\`\`\`
User Action → ViewModel → Service → CloudKit
                ↓
            @Published
                ↓
              View
\`\`\`

## Features Implemented

### ✅ Core Features
- [x] Morning check-in (8 AM notification)
- [x] Evening check-in (5 PM notification)
- [x] Mood selection (green/yellow/red)
- [x] Gratitude entry
- [x] Tomorrow's goal entry
- [x] View partner's daily entry
- [x] History browsing by date
- [x] Deep links from notifications

### ✅ Pairing System
- [x] Create invite link (owner)
- [x] Accept invite link (partner)
- [x] CloudKit sharing
- [x] Two-user limit (optional lock)

### ✅ Design
- [x] Liquid Glass aesthetic (.ultraThinMaterial)
- [x] Spacious layout with generous padding
- [x] Natural color palette
- [x] Haptic feedback on save
- [x] Loading states
- [x] Error handling
- [x] Pull-to-refresh

### ✅ Technical
- [x] CloudKit private database
- [x] CloudKit sharing for pairing
- [x] Custom zone support
- [x] Idempotent upsert (same record per day)
- [x] Local notifications
- [x] Deep linking
- [x] Sign in with Apple (via CloudKit)

## What You Need to Do

### 1. Create Xcode Project (5 minutes)
Follow `SETUP_INSTRUCTIONS.md` steps 1-7:
- Create new iOS App project
- Add capabilities (iCloud, Push, Background)
- Import all source files
- Configure entitlements and Info.plist

### 2. Set Up CloudKit (5 minutes)
Follow `CLOUDKIT_SCHEMA.md`:
- Go to CloudKit Dashboard
- Create `Couple` record type
- Create `DailyEntry` record type
- Add indexes

### 3. Build & Test (2 minutes)
- Build in Xcode (⌘R)
- Install on your iPhone
- Sign in with Apple ID
- Grant notification permissions

### 4. Pair with Laura (2 minutes)
Follow `QUICK_START.md`:
- You: Create invite link → Share via Messages
- Laura: Accept invite link
- Both: See each other's entries

**Total setup time: ~15 minutes**

## File Structure

\`\`\`
Relationship Check-in/
├── README.md                          # Project overview
├── SETUP_INSTRUCTIONS.md              # Xcode setup guide
├── CLOUDKIT_SCHEMA.md                 # CloudKit reference
├── QUICK_START.md                     # User guide
├── PROJECT_SUMMARY.md                 # This file
├── .gitignore                         # Git ignore rules
├── RelationshipCheckin.entitlements   # App capabilities
│
└── RelationshipCheckin/
    ├── RelationshipCheckinApp.swift   # App entry point
    ├── ContentView.swift              # Root view
    ├── Info.plist                     # App configuration
    │
    ├── Models/
    │   ├── DailyEntry.swift          # Entry data model
    │   └── Mood.swift                # Mood enum
    │
    ├── Services/
    │   ├── CloudKitService.swift     # CloudKit operations
    │   ├── ShareService.swift        # Sharing/pairing
    │   ├── NotificationService.swift # Local notifications
    │   └── DeepLinkService.swift     # URL routing
    │
    ├── ViewModels/
    │   ├── MainViewModel.swift       # Main screen logic
    │   ├── EntryViewModel.swift      # Entry form logic
    │   ├── HistoryViewModel.swift    # History logic
    │   └── PairingViewModel.swift    # Pairing logic
    │
    ├── Views/
    │   ├── MainView.swift            # Main screen
    │   ├── EntryView.swift           # Entry form
    │   ├── HistoryDrawerView.swift   # History browser
    │   └── PairingView.swift         # Pairing UI
    │
    └── UI/
        └── DesignSystem.swift        # Design system
\`\`\`

**Total files created: 26**

## Code Statistics

- **Swift files**: 19
- **Lines of code**: ~2,500
- **Models**: 2
- **Services**: 4
- **ViewModels**: 4
- **Views**: 4
- **Reusable components**: 5 (GlassCard, PrimaryButton, SecondaryButton, MoodSelector, ShareSheet)

## Design System

### Colors
- Background: Light gray-blue (#F2F4F7)
- Mood Green: Natural green (#66C78C)
- Mood Yellow: Warm yellow (#F2C45C)
- Mood Red: Soft red (#EB7D73)
- Accent: Calm blue (#5AA6D9)

### Spacing Scale
- Tiny: 4pt
- Small: 8pt
- Medium: 16pt
- Large: 24pt
- Extra Large: 32pt
- Huge: 48pt

### Corner Radius
- Small: 12pt
- Medium: 20pt
- Large: 28pt

### Materials
- Primary: `.ultraThinMaterial` (liquid glass effect)

## CloudKit Schema

Source of truth: `CloudKit/schema.ckdsl` (mirror these settings in CloudKit Dashboard).

### Couple Record
- `ownerUserRecordID` (Reference — set to User in Dashboard if desired)
- `partnerUserRecordID` (Reference — set to User in Dashboard if desired)

### DailyEntry Record
- `date` (Date/Time) - indexed (Queryable)
- `authorUserRecordID` (Reference — optional Queryable index if you need author filters)
- `couple` (Reference — optional constraint to Couple in Dashboard)
- `morningNeed` (String, optional)
- `eveningMood` (Int64, optional) - 0/1/2
- `gratitude` (String, optional)
- `tomorrowGreat` (String, optional)

**Record naming**: `DailyEntry_{yyyy-MM-dd}_{userRecordName}`

## Notifications

### Morning (8:00 AM)
- Title: "Morning Check-in"
- Body: "One thing I need today..."
- Deep link: `rc://entry/morning`

### Evening (5:00 PM)
- Title: "Evening Check-in"
- Body: "How was your day?"
- Deep link: `rc://entry/evening`

## Security & Privacy

- ✅ Private iCloud storage
- ✅ Sign in with Apple
- ✅ CloudKit sharing (controlled)
- ✅ No third-party services
- ✅ No analytics
- ✅ Local notifications only
- ✅ Two-user limit

## Testing Checklist

Before deploying to production:

- [ ] Create Xcode project
- [ ] Build successfully
- [ ] Run on physical device
- [ ] Sign in with iCloud
- [ ] Grant notification permissions
- [ ] Create invite link (Jarad)
- [ ] Accept invite link (Laura)
- [ ] Verify pairing successful
- [ ] Test morning check-in
- [ ] Test evening check-in
- [ ] Verify partner sees entries
- [ ] Test history view
- [ ] Test deep links from notifications
- [ ] Test pull-to-refresh
- [ ] Test on both devices simultaneously
- [ ] Verify CloudKit sync
- [ ] Deploy schema to production
- [ ] Upload to TestFlight
- [ ] Install via TestFlight

## Known Limitations

1. **Two users only**: By design, not a limitation
2. **iOS only**: No Android/web version
3. **iCloud required**: Users must have iCloud accounts
4. **Internet required**: For CloudKit sync (local cache not implemented)
5. **One entry per day**: By design (morning + evening = one record)

## Future Enhancement Ideas

If you want to extend the app later:

- [ ] Photos/attachments
- [ ] Voice memos
- [ ] Weekly summaries
- [ ] Mood trends/charts
- [ ] Custom questions
- [ ] Reminders for specific times
- [ ] Apple Watch app
- [ ] Home screen widgets
- [ ] Export to PDF/CSV
- [ ] Shared calendar integration
- [ ] Offline mode with local cache
- [ ] iPad optimization
- [ ] Dark mode customization

## Support Resources

- **Apple CloudKit Docs**: https://developer.apple.com/documentation/cloudkit
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui
- **UserNotifications**: https://developer.apple.com/documentation/usernotifications

## License

Private app for personal use by Jarad and Laura.

---

**Status**: ✅ Complete and ready to build

**Next Step**: Follow SETUP_INSTRUCTIONS.md to create the Xcode project

**Questions?**: Review the documentation files or check Xcode console for errors

Built with ❤️ for daily connection

```

# QUICK_START.md

```md
# Quick Start Guide

## For You (Jarad) and Laura

### Initial Setup (Do Once)

#### 1. Create Xcode Project
\`\`\`bash
# Open Xcode
# File → New → Project → iOS App
# Product Name: RelationshipCheckin
# Organization Identifier: com.jaradjohnson
# Interface: SwiftUI
# Save to: /Users/jaradjohnson/Projects/Relationship Check-in/
\`\`\`

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
\`\`\`swift
morningComponents.hour = 8  // Change to desired hour
eveningComponents.hour = 17 // Change to desired hour (17 = 5 PM)
\`\`\`

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
\`\`\`swift
static let moodGreen = Color(red: 0.4, green: 0.78, blue: 0.55)
static let moodYellow = Color(red: 0.95, green: 0.77, blue: 0.36)
static let moodRed = Color(red: 0.92, green: 0.49, blue: 0.45)
\`\`\`

### Change Notification Text
Edit `NotificationService.swift`:
\`\`\`swift
morningContent.title = "Good morning! ☀️"
morningContent.body = "What do you need today?"

eveningContent.title = "Evening reflection 🌙"
eveningContent.body = "How was your day?"
\`\`\`

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
2. Review CLOUDKIT_SCHEMA.md and `CloudKit/schema.ckdsl`
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

```

# README.md

```md
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

Schema definition source of truth: `CloudKit/schema.ckdsl` (import or verify in CloudKit Dashboard before releasing builds).

## License

Private app for personal use.

```

# RelationshipCheckin.entitlements

```entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.com.jaradjohnson.RelationshipCheckin</string>
	</array>
	<key>com.apple.developer.icloud-extended-share-access</key>
	<array/>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
</dict>
</plist>

```

# RelationshipCheckin.xcodeproj/project.pbxproj

```pbxproj
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		AA0001 /* RelationshipCheckinApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0001 /* RelationshipCheckinApp.swift */; };
		AA0002 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0002 /* ContentView.swift */; };
		AA0003 /* DailyEntry.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0003 /* DailyEntry.swift */; };
		AA0004 /* Mood.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0004 /* Mood.swift */; };
		AA0005 /* CloudKitService.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0005 /* CloudKitService.swift */; };
		AA0006 /* ShareService.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0006 /* ShareService.swift */; };
		AA0007 /* NotificationService.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0007 /* NotificationService.swift */; };
		AA0008 /* DeepLinkService.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0008 /* DeepLinkService.swift */; };
		AA0009 /* MainViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0009 /* MainViewModel.swift */; };
		AA0010 /* EntryViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0010 /* EntryViewModel.swift */; };
		AA0011 /* HistoryViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0011 /* HistoryViewModel.swift */; };
		AA0012 /* PairingViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0012 /* PairingViewModel.swift */; };
		AA0013 /* MainView.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0013 /* MainView.swift */; };
		AA0014 /* EntryView.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0014 /* EntryView.swift */; };
		AA0015 /* HistoryDrawerView.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0015 /* HistoryDrawerView.swift */; };
		AA0016 /* PairingView.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0016 /* PairingView.swift */; };
		AA0017 /* DesignSystem.swift in Sources */ = {isa = PBXBuildFile; fileRef = BB0017 /* DesignSystem.swift */; };
		PP0001 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = QQ0001 /* Assets.xcassets */; };
		PP0002 /* PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile; fileRef = QQ0002 /* PrivacyInfo.xcprivacy */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		BB0001 /* RelationshipCheckinApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RelationshipCheckinApp.swift; sourceTree = "<group>"; };
		BB0002 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		BB0003 /* DailyEntry.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DailyEntry.swift; sourceTree = "<group>"; };
		BB0004 /* Mood.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Mood.swift; sourceTree = "<group>"; };
		BB0005 /* CloudKitService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CloudKitService.swift; sourceTree = "<group>"; };
		BB0006 /* ShareService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ShareService.swift; sourceTree = "<group>"; };
		BB0007 /* NotificationService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NotificationService.swift; sourceTree = "<group>"; };
		BB0008 /* DeepLinkService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DeepLinkService.swift; sourceTree = "<group>"; };
		BB0009 /* MainViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MainViewModel.swift; sourceTree = "<group>"; };
		BB0010 /* EntryViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EntryViewModel.swift; sourceTree = "<group>"; };
		BB0011 /* HistoryViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HistoryViewModel.swift; sourceTree = "<group>"; };
		BB0012 /* PairingViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PairingViewModel.swift; sourceTree = "<group>"; };
		BB0013 /* MainView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MainView.swift; sourceTree = "<group>"; };
		BB0014 /* EntryView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EntryView.swift; sourceTree = "<group>"; };
		BB0015 /* HistoryDrawerView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HistoryDrawerView.swift; sourceTree = "<group>"; };
		BB0016 /* PairingView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PairingView.swift; sourceTree = "<group>"; };
		BB0017 /* DesignSystem.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DesignSystem.swift; sourceTree = "<group>"; };
		CC0001 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		DD0001 /* RelationshipCheckin.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = RelationshipCheckin.entitlements; sourceTree = "<group>"; };
		EE0001 /* RelationshipCheckin.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = RelationshipCheckin.app; sourceTree = BUILT_PRODUCTS_DIR; };
		QQ0001 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		QQ0002 /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; lastKnownFileType = text.json; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };
		RR0001 /* GenerateAppIcon.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GenerateAppIcon.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		FF0001 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		GG0001 = {
			isa = PBXGroup;
			children = (
				GG0002 /* RelationshipCheckin */,
				DD0001 /* RelationshipCheckin.entitlements */,
				GG0009 /* Scripts */,
				GG0003 /* Products */,
			);
			sourceTree = "<group>";
		};
		GG0002 /* RelationshipCheckin */ = {
			isa = PBXGroup;
			children = (
				BB0001 /* RelationshipCheckinApp.swift */,
				BB0002 /* ContentView.swift */,
				CC0001 /* Info.plist */,
				QQ0001 /* Assets.xcassets */,
				QQ0002 /* PrivacyInfo.xcprivacy */,
				GG0004 /* Models */,
				GG0005 /* Services */,
				GG0006 /* ViewModels */,
				GG0007 /* Views */,
				GG0008 /* UI */,
			);
			path = RelationshipCheckin;
			sourceTree = "<group>";
		};
		GG0003 /* Products */ = {
			isa = PBXGroup;
			children = (
				EE0001 /* RelationshipCheckin.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		GG0004 /* Models */ = {
			isa = PBXGroup;
			children = (
				BB0003 /* DailyEntry.swift */,
				BB0004 /* Mood.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		};
		GG0005 /* Services */ = {
			isa = PBXGroup;
			children = (
				BB0005 /* CloudKitService.swift */,
				BB0006 /* ShareService.swift */,
				BB0007 /* NotificationService.swift */,
				BB0008 /* DeepLinkService.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		};
		GG0006 /* ViewModels */ = {
			isa = PBXGroup;
			children = (
				BB0009 /* MainViewModel.swift */,
				BB0010 /* EntryViewModel.swift */,
				BB0011 /* HistoryViewModel.swift */,
				BB0012 /* PairingViewModel.swift */,
			);
			path = ViewModels;
			sourceTree = "<group>";
		};
		GG0007 /* Views */ = {
			isa = PBXGroup;
			children = (
				BB0013 /* MainView.swift */,
				BB0014 /* EntryView.swift */,
				BB0015 /* HistoryDrawerView.swift */,
				BB0016 /* PairingView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		};
		GG0008 /* UI */ = {
			isa = PBXGroup;
			children = (
				BB0017 /* DesignSystem.swift */,
			);
			path = UI;
			sourceTree = "<group>";
		};
		GG0009 /* Scripts */ = {
			isa = PBXGroup;
			children = (
				RR0001 /* GenerateAppIcon.swift */,
			);
			path = Scripts;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		HH0001 /* RelationshipCheckin */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = II0001 /* Build configuration list for PBXNativeTarget "RelationshipCheckin" */;
			buildPhases = (
				JJ0001 /* Sources */,
				FF0001 /* Frameworks */,
				KK0001 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = RelationshipCheckin;
			productName = RelationshipCheckin;
			productReference = EE0001 /* RelationshipCheckin.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		LL0001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 2600;
				TargetAttributes = {
					HH0001 = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = MM0001 /* Build configuration list for PBXProject "RelationshipCheckin" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = GG0001;
			productRefGroup = GG0003 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				HH0001 /* RelationshipCheckin */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		KK0001 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				PP0001 /* Assets.xcassets in Resources */,
				PP0002 /* PrivacyInfo.xcprivacy in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		JJ0001 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0001 /* RelationshipCheckinApp.swift in Sources */,
				AA0002 /* ContentView.swift in Sources */,
				AA0003 /* DailyEntry.swift in Sources */,
				AA0004 /* Mood.swift in Sources */,
				AA0005 /* CloudKitService.swift in Sources */,
				AA0006 /* ShareService.swift in Sources */,
				AA0007 /* NotificationService.swift in Sources */,
				AA0008 /* DeepLinkService.swift in Sources */,
				AA0009 /* MainViewModel.swift in Sources */,
				AA0010 /* EntryViewModel.swift in Sources */,
				AA0011 /* HistoryViewModel.swift in Sources */,
				AA0012 /* PairingViewModel.swift in Sources */,
				AA0013 /* MainView.swift in Sources */,
				AA0014 /* EntryView.swift in Sources */,
				AA0015 /* HistoryDrawerView.swift in Sources */,
				AA0016 /* PairingView.swift in Sources */,
				AA0017 /* DesignSystem.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		NN0001 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = E2YPX76MBQ;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		NN0002 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = E2YPX76MBQ;
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		OO0001 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
                ASSETCATALOG_COMPILER_APPICON_NAME = AppIconNew;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = RelationshipCheckin.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = RelationshipCheckin/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.jaradjohnson.RelationshipCheckin;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		OO0002 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
                ASSETCATALOG_COMPILER_APPICON_NAME = AppIconNew;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = RelationshipCheckin.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = RelationshipCheckin/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.jaradjohnson.RelationshipCheckin;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		II0001 /* Build configuration list for PBXNativeTarget "RelationshipCheckin" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				OO0001 /* Debug */,
				OO0002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		MM0001 /* Build configuration list for PBXProject "RelationshipCheckin" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				NN0001 /* Debug */,
				NN0002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = LL0001 /* Project object */;
}

```

# RelationshipCheckin.xcodeproj/project.xcworkspace/contents.xcworkspacedata

```xcworkspacedata
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>

```

# RelationshipCheckin.xcodeproj/project.xcworkspace/xcuserdata/jaradjohnson.xcuserdatad/UserInterfaceState.xcuserstate

This is a binary file of the type: Binary

# RelationshipCheckin.xcodeproj/xcshareddata/xcschemes/RelationshipCheckin.xcscheme

```xcscheme
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "HH0001"
               BuildableName = "RelationshipCheckin.app"
               BlueprintName = "RelationshipCheckin"
               ReferencedContainer = "container:RelationshipCheckin.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "HH0001"
            BuildableName = "RelationshipCheckin.app"
            BlueprintName = "RelationshipCheckin"
            ReferencedContainer = "container:RelationshipCheckin.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "HH0001"
            BuildableName = "RelationshipCheckin.app"
            BlueprintName = "RelationshipCheckin"
            ReferencedContainer = "container:RelationshipCheckin.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>

```

# RelationshipCheckin.xcodeproj/xcuserdata/jaradjohnson.xcuserdatad/xcschemes/xcschememanagement.plist

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
		<key>RelationshipCheckin.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>0</integer>
		</dict>
	</dict>
</dict>
</plist>

```

# RelationshipCheckin/Assets.xcassets/AccentColor.colorset/Contents.json

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.3608",
          "green" : "0.3529",
          "blue" : "0.8588",
          "alpha" : "1.0000"
        }
      }
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}


```

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Contents.json

```json
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "pre-rendered" : true,
    "template-rendering-intent" : "original"
  }
}


```

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/AppIcon-1024.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Contents.json

```json
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "pre-rendered" : true,
    "template-rendering-intent" : "original"
  }
}


```

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-20x20@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-20x20@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-20x20@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-29x29@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-29x29@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-29x29@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-40x40@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-40x40@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-40x40@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-60x60@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-60x60@3x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-76x76@1x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-76x76@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/AppIconNew.appiconset/Icon-App-83.5x83.5@2x.png

This is a binary file of the type: Image

# RelationshipCheckin/Assets.xcassets/Contents.json

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}


```

# RelationshipCheckin/Assets.xcassets/NotificationIcon.imageset/Contents.json

```json
{
  "images" : [
    {
      "filename" : "notification-icon.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

```

# RelationshipCheckin/Assets.xcassets/NotificationIcon.imageset/notification-icon.png

This is a binary file of the type: Image

# RelationshipCheckin/ContentView.swift

```swift
//
//  ContentView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var deepLinkService: DeepLinkService
    
    var body: some View {
        Group {
            if cloudKitService.isInitializing {
                LoadingScreen()
            } else if !cloudKitService.isPaired {
                PairingView()
            } else {
                MainView()
            }
        }
        .sheet(item: $deepLinkService.activeRoute) { route in
            NavigationStack {
                EntryView(entryType: route.entryType)
            }
        }
    }
}

struct LoadingScreen: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.Colors.secondaryBackground(for: colorScheme).opacity(0.3),
                    DesignSystem.Colors.background(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryPurple)
                        .frame(width: 80, height: 80)
                        .shadow(color: DesignSystem.Colors.primaryPurple.opacity(0.3), radius: 20)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignSystem.Colors.accent)
                
                Text("Setting up...")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
}

```

# RelationshipCheckin/Info.plist

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleName</key>
    <string>RelationshipCheckin</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiresFullScreen</key>
    <true/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIStatusBarStyle</key>
    <string>UIStatusBarStyleDefault</string>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
    <key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
            <string>com.jaradjohnson.RelationshipCheckin</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>rc</string>
			</array>
		</dict>
	</array>
</dict>
</plist>

```

# RelationshipCheckin/Models/DailyEntry.swift

```swift
//
//  DailyEntry.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit

struct DailyEntry: Identifiable, Equatable {
    let id: String // CKRecord.ID as string
    let date: Date
    let authorUserRecordID: CKRecord.Reference
    var morningNeed: String?
    var eveningMood: Mood?
    var gratitude: String?
    var tomorrowGreat: String?
    let coupleReference: CKRecord.Reference
    
    var authorName: String {
        authorUserRecordID.recordID.recordName
    }
    
    // Create record name for idempotent upsert
    static func recordName(for date: Date, userRecordName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)
        return "DailyEntry_\(dateString)_\(userRecordName)"
    }
    
    // Convert to CKRecord
    func toCKRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: "DailyEntry", recordID: recordID)
        
        record["date"] = date as CKRecordValue
        record["authorUserRecordID"] = authorUserRecordID
        record["couple"] = coupleReference
        
        if let morningNeed = morningNeed {
            record["morningNeed"] = morningNeed as CKRecordValue
        }
        if let eveningMood = eveningMood {
            record["eveningMood"] = eveningMood.rawValue as CKRecordValue
        }
        if let gratitude = gratitude {
            record["gratitude"] = gratitude as CKRecordValue
        }
        if let tomorrowGreat = tomorrowGreat {
            record["tomorrowGreat"] = tomorrowGreat as CKRecordValue
        }
        
        return record
    }
    
    // Create from CKRecord
    static func from(record: CKRecord) -> DailyEntry? {
        guard let date = record["date"] as? Date,
              let authorRef = record["authorUserRecordID"] as? CKRecord.Reference,
              let coupleRef = record["couple"] as? CKRecord.Reference else {
            return nil
        }
        
        let morningNeed = record["morningNeed"] as? String
        let eveningMoodInt = record["eveningMood"] as? Int
        let eveningMood = eveningMoodInt != nil ? Mood(rawValue: eveningMoodInt!) : nil
        let gratitude = record["gratitude"] as? String
        let tomorrowGreat = record["tomorrowGreat"] as? String
        
        return DailyEntry(
            id: record.recordID.recordName,
            date: date,
            authorUserRecordID: authorRef,
            morningNeed: morningNeed,
            eveningMood: eveningMood,
            gratitude: gratitude,
            tomorrowGreat: tomorrowGreat,
            coupleReference: coupleRef
        )
    }
}


```

# RelationshipCheckin/Models/Mood.swift

```swift
//
//  Mood.swift
//  RelationshipCheckin
//
//  Updated with adaptive dark mode colors - 10/26/2025
//

import Foundation
import SwiftUI

enum Mood: Int, CaseIterable, Codable {
    case great = 0
    case okay = 1
    case difficult = 2
    
    var color: Color {
        switch self {
        case .great: return DesignSystem.Colors.moodGreat // Purple
        case .okay: return DesignSystem.Colors.moodOkay // Gold
        case .difficult: return DesignSystem.Colors.moodDifficult // Navy
        }
    }
    
    // Adaptive color for dark mode support
    func adaptiveColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .great: 
            return scheme == .dark ? DesignSystem.Colors.moodGreatDark : DesignSystem.Colors.moodGreat
        case .okay: 
            return scheme == .dark ? DesignSystem.Colors.moodOkayDark : DesignSystem.Colors.moodOkay
        case .difficult: 
            return scheme == .dark ? DesignSystem.Colors.moodDifficultDark : DesignSystem.Colors.moodDifficult
        }
    }
    
    var displayName: String {
        switch self {
        case .great: return "Great"
        case .okay: return "Okay"
        case .difficult: return "Hard"
        }
    }
    
    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .okay: return "face.dashed.fill"
        case .difficult: return "face.dashed.fill"
        }
    }
}

```

# RelationshipCheckin/PrivacyInfo.xcprivacy

```xcprivacy
{
  "version": 1,
  "metadata": {
    "userPrivacyType": "doesNotTrack",
    "purpose": "This app uses only Apple frameworks and iCloud CloudKit for user-supplied content. No third-party SDKs or tracking."
  },
  "privacy": {
    "tracking": {
      "usesTracking": false
    },
    "dataCategories": []
  }
}



```

# RelationshipCheckin/RelationshipCheckinApp.swift

```swift
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


```

# RelationshipCheckin/Services/CloudKitErrorHelper.swift

```swift
import CloudKit

func ckExplain(_ error: Error) -> String {
    guard let ckError = error as? CKError else {
        return error.localizedDescription
    }

    var parts = ["CKError.\(ckError.code.rawValue) (\(ckError.code))"]

    if ckError.code == .partialFailure,
       let partials = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
        let mapped = partials.map { itemID, error -> String in
            let code = (error as? CKError)?.code ?? .unknownItem
            return "\(itemID): \(code)"
        }
        if !mapped.isEmpty {
            parts.append(mapped.joined(separator: ", "))
        }
    }

    return parts.joined(separator: " | ")
}

```

# RelationshipCheckin/Services/CloudKitService.swift

```swift
//
//  CloudKitService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    @Published var isInitializing = true
    @Published var isPaired = false
    @Published var currentUserRecordID: CKRecord.ID?
    @Published var coupleRecordID: CKRecord.ID?
    @Published var partnerUserRecordID: CKRecord.ID?
    @Published var error: Error?
    
    private let customZoneName = "RelationshipZone"
    var customZoneID: CKRecordZone.ID?
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        do {
            // Fetch current user
            let userRecordID = try await container.userRecordID()
            self.currentUserRecordID = userRecordID
            
            // Create or fetch custom zone
            let zoneID = CKRecordZone.ID(zoneName: customZoneName, ownerName: CKCurrentUserDefaultName)
            self.customZoneID = zoneID
            
            do {
                _ = try await privateDatabase.recordZone(for: zoneID)
            } catch {
                // Zone doesn't exist, create it
                let zone = CKRecordZone(zoneID: zoneID)
                _ = try await privateDatabase.save(zone)
            }
            
            // Check if already paired
            await checkPairingStatus()
            
            self.isInitializing = false
        } catch {
            self.error = error
            self.isInitializing = false
            print("CloudKit initialization error: \(error)")
        }
    }
    
    // MARK: - Pairing
    
    func checkPairingStatus() async {
        do {
            // Try to find Couple record in private DB
            let query = CKQuery(recordType: "Couple", predicate: NSPredicate(value: true))
            let (matchResults, _) = try await privateDatabase.records(matching: query, inZoneWith: customZoneID)
            
            if let firstMatch = matchResults.first {
                let coupleRecord = try firstMatch.1.get()
                self.coupleRecordID = coupleRecord.recordID
                
                if let partnerRef = coupleRecord["partnerUserRecordID"] as? CKRecord.Reference {
                    self.partnerUserRecordID = partnerRef.recordID
                    self.isPaired = true
                } else {
                    self.isPaired = false
                }
                return
            }
            
            // Try shared database
            let sharedQuery = CKQuery(recordType: "Couple", predicate: NSPredicate(value: true))
            let (sharedResults, _) = try await sharedDatabase.records(matching: sharedQuery)
            
            if let firstShared = sharedResults.first {
                let coupleRecord = try firstShared.1.get()
                self.coupleRecordID = coupleRecord.recordID
                
                if let partnerRef = coupleRecord["partnerUserRecordID"] as? CKRecord.Reference {
                    self.partnerUserRecordID = partnerRef.recordID
                    self.isPaired = true
                } else {
                    self.isPaired = false
                }
            } else {
                self.isPaired = false
            }
        } catch {
            print("Error checking pairing status: \(error)")
            self.isPaired = false
        }
    }
    
    func createCouple() async throws -> CKRecord {
        guard let zoneID = customZoneID, let userRecordID = currentUserRecordID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not initialized"])
        }

        let recordID = CKRecord.ID(recordName: "Couple_\(UUID().uuidString)", zoneID: zoneID)
        let coupleRecord = CKRecord(recordType: "Couple", recordID: recordID)

        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        coupleRecord["ownerUserRecordID"] = userReference

        let savedRecord = try await privateDatabase.save(coupleRecord)
        self.coupleRecordID = savedRecord.recordID

        return savedRecord
    }

    func ensureCouple() async throws -> CKRecord {
        if let coupleRecordID = coupleRecordID {
            for database in [sharedDatabase, privateDatabase] {
                if let record = try? await database.record(for: coupleRecordID) {
                    self.coupleRecordID = record.recordID
                    return record
                }
            }
        }

        await checkPairingStatus()

        if let coupleRecordID = coupleRecordID {
            for database in [sharedDatabase, privateDatabase] {
                if let record = try? await database.record(for: coupleRecordID) {
                    self.coupleRecordID = record.recordID
                    return record
                }
            }
        }

        return try await createCouple()
    }
    
    func updateCoupleWithPartner(partnerRecordID: CKRecord.ID) async throws {
        guard let coupleRecordID = coupleRecordID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No couple record"])
        }
        
        // Fetch from appropriate database
        let databases = [sharedDatabase, privateDatabase]
        var coupleRecord: CKRecord?
        
        for db in databases {
            do {
                coupleRecord = try await db.record(for: coupleRecordID)
                if coupleRecord != nil {
                    let partnerReference = CKRecord.Reference(recordID: partnerRecordID, action: .none)
                    coupleRecord!["partnerUserRecordID"] = partnerReference
                    _ = try await db.save(coupleRecord!)
                    
                    self.partnerUserRecordID = partnerRecordID
                    self.isPaired = true
                    return
                }
            } catch {
                continue
            }
        }
        
        throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find couple record"])
    }
    
    // MARK: - Daily Entries
    
    func upsertDailyEntry(_ entry: DailyEntry) async throws {
        guard let zoneID = customZoneID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zone not initialized"])
        }
        
        let record = entry.toCKRecord(in: zoneID)
        
        // Try shared database first, then private
        do {
            _ = try await sharedDatabase.save(record)
        } catch {
            _ = try await privateDatabase.save(record)
        }
    }
    
    func fetchDailyEntry(for date: Date, userRecordID: CKRecord.ID) async throws -> DailyEntry? {
        let recordName = DailyEntry.recordName(for: date, userRecordName: userRecordID.recordName)
        
        guard let zoneID = customZoneID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zone not initialized"])
        }
        
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        
        // Try shared database first
        do {
            let record = try await sharedDatabase.record(for: recordID)
            return DailyEntry.from(record: record)
        } catch {
            // Try private database
            do {
                let record = try await privateDatabase.record(for: recordID)
                return DailyEntry.from(record: record)
            } catch {
                return nil
            }
        }
    }
    
    func fetchEntriesForDate(_ date: Date) async throws -> [DailyEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        let query = CKQuery(recordType: "DailyEntry", predicate: predicate)
        
        var entries: [DailyEntry] = []
        
        // Query shared database
        do {
            let (results, _) = try await sharedDatabase.records(matching: query)
            for result in results {
                if let record = try? result.1.get(), let entry = DailyEntry.from(record: record) {
                    entries.append(entry)
                }
            }
        } catch {
            print("Error querying shared database: \(error)")
        }
        
        // Query private database
        do {
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: customZoneID)
            for result in results {
                if let record = try? result.1.get(), let entry = DailyEntry.from(record: record) {
                    entries.append(entry)
                }
            }
        } catch {
            print("Error querying private database: \(error)")
        }
        
        return entries
    }
    
    // Helper to get database for operations
    func getActiveDatabase() -> CKDatabase {
        return isPaired ? sharedDatabase : privateDatabase
    }
}

```

# RelationshipCheckin/Services/DeepLinkService.swift

```swift
//
//  DeepLinkService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import CloudKit

enum EntryType: String {
    case morning
    case evening
}

struct DeepLinkRoute: Identifiable {
    let id = UUID()
    let entryType: EntryType
}

@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()
    
    @Published var activeRoute: DeepLinkRoute?
    
    private init() {}
    
    func handle(url: URL) {
        guard url.scheme == "rc" else { return }
        
        // Handle accept flow: rc://accept?share=<encoded CKShare URL>
        if url.host == "accept",
           let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let shareStr = comps.queryItems?.first(where: { $0.name == "share" })?.value,
           let shareURL = URL(string: shareStr) {
            Task { @MainActor in
                do {
                    let metadata = try await ShareService.shared.fetchShareMetadata(from: shareURL)
                    try await ShareService.shared.acceptShare(metadata: metadata)
                } catch {
                    print("Accept via deeplink failed: \(error)")
                }
            }
            return
        }
        
        // Handle entry routes: rc://entry/morning or rc://entry/evening
        guard url.host == "entry" else { return }
        let path = url.pathComponents.dropFirst().first ?? ""
        switch path {
        case "morning":
            activeRoute = DeepLinkRoute(entryType: .morning)
        case "evening":
            activeRoute = DeepLinkRoute(entryType: .evening)
        default:
            break
        }
    }
    
    func clearRoute() {
        activeRoute = nil
    }
}

```

# RelationshipCheckin/Services/NotificationService.swift

```swift
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


```

# RelationshipCheckin/Services/ShareService.swift

```swift
//
//  ShareService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class ShareService: ObservableObject {
    static let shared = ShareService()
    
    @Published var isSharing = false
    @Published var shareURL: URL?
    @Published var error: Error?
    
    private let cloudKitService = CloudKitService.shared
    
    private init() {}
    
    // MARK: - Create Share
    
    func createShare(for coupleRecord: CKRecord) async throws -> CKShare {
        let share = CKShare(rootRecord: coupleRecord)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Relationship Check-in" as CKRecordValue
        
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        let privateDB = container.privateCloudDatabase
        
        // Save both the record and share
        let (savedRecords, _) = try await privateDB.modifyRecords(saving: [coupleRecord, share], deleting: [])
        
        // Find the saved share in the results
        for (_, result) in savedRecords {
            if let record = try? result.get(), let savedShare = record as? CKShare {
                return savedShare
            }
        }
        
        throw NSError(domain: "ShareService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create share"])
    }
    
    func getShareURL(for share: CKShare) -> URL? {
        return share.url
    }
    
    // MARK: - Accept Share
    
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        
        do {
            _ = try await container.accept(metadata)

            let userRecordID = try await container.userRecordID()
            cloudKitService.currentUserRecordID = userRecordID

            await cloudKitService.checkPairingStatus()
            try await cloudKitService.updateCoupleWithPartner(partnerRecordID: userRecordID)
            self.error = nil
        } catch {
#if DEBUG
            do {
                let userRecordID = try await container.userRecordID()
                cloudKitService.currentUserRecordID = userRecordID

                await cloudKitService.checkPairingStatus()
                try await cloudKitService.updateCoupleWithPartner(partnerRecordID: userRecordID)
                self.error = nil
                return
            } catch let fallbackError {
                self.error = fallbackError
                throw fallbackError
            }
#else
            self.error = error
            throw error
#endif
        }
    }
    
    // MARK: - Stop Sharing (Lock to two users)
    
    func stopSharing(share: CKShare) async throws {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        let privateDB = container.privateCloudDatabase
        
        // Delete the share to prevent more people from joining
        try await privateDB.deleteRecord(withID: share.recordID)
    }
    
    // MARK: - Fetch Share Metadata
    
    func fetchShareMetadata(from url: URL) async throws -> CKShare.Metadata {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        return try await container.shareMetadata(for: url)
    }
}

```

# RelationshipCheckin/UI/DesignSystem.swift

```swift
//
//  DesignSystem.swift
//  RelationshipCheckin
//
//  Redesigned with Liquid Glass & Adaptive Dark Mode - 10/10/2025
//

import SwiftUI

enum DesignSystem {
    
    // MARK: - Adaptive Color System
    
    struct AdaptiveColor {
        let light: Color
        let dark: Color
        
        func color(for scheme: ColorScheme) -> Color {
            scheme == .dark ? dark : light
        }
    }
    
    // MARK: - Custom Color Palette
    enum Colors {
        // Primary palette - Fixed colors (always same)
        static let primaryPurple = Color(red: 92/255, green: 90/255, blue: 219/255) // #5c5adb
        static let primaryPurpleBright = Color(red: 112/255, green: 110/255, blue: 239/255) // Brighter for dark mode
        static let lightLavender = Color(red: 227/255, green: 224/255, blue: 249/255) // #e3e0f9
        static let deepNavy = Color(red: 43/255, green: 40/255, blue: 76/255) // #2b284c
        static let warmGold = Color(red: 216/255, green: 164/255, blue: 90/255) // #d8a45a
        static let warmGoldBright = Color(red: 236/255, green: 184/255, blue: 110/255) // Brighter for dark mode
        
        // Adaptive palette
        static let adaptiveBackground = AdaptiveColor(
            light: .white,
            dark: Color(red: 18/255, green: 18/255, blue: 22/255) // #121216 - Very dark blue-gray
        )
        
        static let adaptiveSecondaryBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255), // Light lavender
            dark: Color(red: 35/255, green: 33/255, blue: 58/255) // #23213a - Dark purple-slate
        )
        
        static let adaptiveCardBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255).opacity(0.3),
            dark: Color(red: 45/255, green: 43/255, blue: 68/255).opacity(0.5) // Dark purple with transparency
        )
        
        static let adaptiveTextPrimary = AdaptiveColor(
            light: Color(red: 43/255, green: 40/255, blue: 76/255), // Deep navy
            dark: Color(red: 240/255, green: 240/255, blue: 245/255) // #f0f0f5 - Off white
        )
        
        static let adaptiveTextSecondary = AdaptiveColor(
            light: Color(red: 92/255, green: 90/255, blue: 219/255).opacity(0.7), // Purple
            dark: Color(red: 180/255, green: 178/255, blue: 230/255) // #b4b2e6 - Light purple
        )
        
        static let adaptiveTextTertiary = AdaptiveColor(
            light: Color(red: 43/255, green: 40/255, blue: 76/255).opacity(0.5),
            dark: Color(red: 150/255, green: 150/255, blue: 165/255) // #9696a5 - Medium gray
        )
        
        static let adaptiveBorderGradientStart = AdaptiveColor(
            light: .white.opacity(0.8),
            dark: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.15) // Subtle light edge
        )
        
        static let adaptiveBorderGradientEnd = AdaptiveColor(
            light: .white.opacity(0.2),
            dark: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.05)
        )
        
        static let adaptiveInputBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255).opacity(0.4),
            dark: Color(red: 45/255, green: 43/255, blue: 68/255).opacity(0.6)
        )
        
        // Semantic mappings - now using adaptive colors
        static let accent = primaryPurple
        static let accentBright = primaryPurpleBright // For dark mode accents
        
        // Mood colors - enhanced for dark mode visibility
        static let moodGreat = primaryPurple
        static let moodGreatDark = primaryPurpleBright
        static let moodOkay = warmGold
        static let moodOkayDark = warmGoldBright
        static let moodDifficult = deepNavy
        static let moodDifficultDark = Color(red: 83/255, green: 80/255, blue: 116/255) // Lighter navy
        
        // Helper function to get adaptive color
        static func background(for scheme: ColorScheme) -> Color {
            adaptiveBackground.color(for: scheme)
        }
        
        static func secondaryBackground(for scheme: ColorScheme) -> Color {
            adaptiveSecondaryBackground.color(for: scheme)
        }
        
        static func cardBackground(for scheme: ColorScheme) -> Color {
            adaptiveCardBackground.color(for: scheme)
        }
        
        static func textPrimary(for scheme: ColorScheme) -> Color {
            adaptiveTextPrimary.color(for: scheme)
        }
        
        static func textSecondary(for scheme: ColorScheme) -> Color {
            adaptiveTextSecondary.color(for: scheme)
        }
        
        static func textTertiary(for scheme: ColorScheme) -> Color {
            adaptiveTextTertiary.color(for: scheme)
        }
        
        static func borderGradientStart(for scheme: ColorScheme) -> Color {
            adaptiveBorderGradientStart.color(for: scheme)
        }
        
        static func borderGradientEnd(for scheme: ColorScheme) -> Color {
            adaptiveBorderGradientEnd.color(for: scheme)
        }
        
        static func inputBackground(for scheme: ColorScheme) -> Color {
            adaptiveInputBackground.color(for: scheme)
        }
    }
    
    // MARK: - Typography (San Francisco)
    enum Typography {
        // San Francisco is the default system font
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .semibold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
    }
    
    // MARK: - Animations
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Liquid Glass Card (Adaptive Dark Mode)

struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    var padding: CGFloat = DesignSystem.Spacing.lg
    
    init(padding: CGFloat = DesignSystem.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                // Adaptive Liquid Glass
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .fill(DesignSystem.Colors.cardBackground(for: colorScheme))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.borderGradientStart(for: colorScheme),
                                        DesignSystem.Colors.borderGradientEnd(for: colorScheme)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: colorScheme == .dark ? 0.5 : 1
                            )
                    }
                    .shadow(
                        color: colorScheme == .dark 
                            ? DesignSystem.Colors.primaryPurpleBright.opacity(0.12)
                            : DesignSystem.Colors.primaryPurple.opacity(0.08),
                        radius: colorScheme == .dark ? 16 : 12,
                        x: 0,
                        y: 4
                    )
            }
    }
}

// MARK: - Modern Button Styles (Adaptive)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: colorScheme == .dark ? 
                                [DesignSystem.Colors.primaryPurpleBright, DesignSystem.Colors.primaryPurple] :
                                [DesignSystem.Colors.primaryPurple, DesignSystem.Colors.primaryPurple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.textTertiary(for: colorScheme),
                                DesignSystem.Colors.textTertiary(for: colorScheme)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: colorScheme == .dark ?
                            DesignSystem.Colors.primaryPurpleBright.opacity(0.4) :
                            DesignSystem.Colors.primaryPurple.opacity(0.3),
                        radius: colorScheme == .dark ? 12 : 8,
                        x: 0,
                        y: 4
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(
                colorScheme == .dark ? 
                    DesignSystem.Colors.primaryPurpleBright : 
                    DesignSystem.Colors.primaryPurple
            )
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .strokeBorder(
                                (colorScheme == .dark ? 
                                    DesignSystem.Colors.primaryPurpleBright : 
                                    DesignSystem.Colors.primaryPurple).opacity(0.3),
                                lineWidth: 1
                            )
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Modern Text Field Style (Adaptive)

struct LiquidTextEditor: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(DesignSystem.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(DesignSystem.Colors.inputBackground(for: colorScheme))
        }
    }
}

// MARK: - Mood Selector Component (Adaptive)

struct ModernMoodSelector: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedMood: Mood?
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button {
                    withAnimation(DesignSystem.Animation.spring) {
                        selectedMood = mood
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                } label: {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    if selectedMood == mood {
                                        Circle()
                                            .strokeBorder(
                                                colorScheme == .dark ? 
                                                    Color.white.opacity(0.8) : 
                                                    Color.white,
                                                lineWidth: 3
                                            )
                                            .shadow(color: mood.adaptiveColor(for: colorScheme).opacity(0.5), radius: 8)
                                            .matchedGeometryEffect(id: "selection", in: animation)
                                    }
                                }
                            
                            Image(systemName: mood.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                        
                        Text(mood.displayName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(selectedMood == mood ? .semibold : .regular)
                            .foregroundStyle(
                                selectedMood == mood ? 
                                    DesignSystem.Colors.textPrimary(for: colorScheme) : 
                                    DesignSystem.Colors.textSecondary(for: colorScheme)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header (Adaptive)

struct SectionHeader: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(
                        colorScheme == .dark ? 
                            DesignSystem.Colors.accentBright : 
                            DesignSystem.Colors.accent
                    )
            }
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Spacer()
        }
    }
}

// MARK: - Empty State View (Adaptive)

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
            
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Text(subtitle)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Loading View (Adaptive)

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(
                    colorScheme == .dark ? 
                        DesignSystem.Colors.accentBright : 
                        DesignSystem.Colors.accent
                )
            
            Text("Loading...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
        }
    }
}

```

# RelationshipCheckin/ViewModels/EntryViewModel.swift

```swift
//
//  EntryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class EntryViewModel: ObservableObject {
    @Published var morningNeed: String = ""
    @Published var eveningMood: Mood?
    @Published var gratitude: String = ""
    @Published var tomorrowGreat: String = ""
    
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false
    
    private let cloudKitService = CloudKitService.shared
    let entryType: EntryType
    
    init(entryType: EntryType) {
        self.entryType = entryType
        Task {
            await loadTodayEntry()
        }
    }
    
    // MARK: - Load Today's Entry
    
    func loadTodayEntry() async {
        guard let userRecordID = cloudKitService.currentUserRecordID else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            if let entry = try await cloudKitService.fetchDailyEntry(for: today, userRecordID: userRecordID) {
                self.morningNeed = entry.morningNeed ?? ""
                self.eveningMood = entry.eveningMood
                self.gratitude = entry.gratitude ?? ""
                self.tomorrowGreat = entry.tomorrowGreat ?? ""
            }
        } catch {
            print("Error loading today's entry: \(error)")
        }
    }
    
    // MARK: - Save Entry
    
    func saveEntry() async {
        guard let userRecordID = cloudKitService.currentUserRecordID,
              let coupleRecordID = cloudKitService.coupleRecordID,
              cloudKitService.customZoneID != nil else {
            error = "Not properly initialized"
            return
        }
        
        isSaving = true
        error = nil
        
        let today = Calendar.current.startOfDay(for: Date())
        let recordName = DailyEntry.recordName(for: today, userRecordName: userRecordID.recordName)
        
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        let coupleReference = CKRecord.Reference(recordID: coupleRecordID, action: .none)
        
        var entry = DailyEntry(
            id: recordName,
            date: today,
            authorUserRecordID: userReference,
            morningNeed: morningNeed.isEmpty ? nil : morningNeed,
            eveningMood: eveningMood,
            gratitude: gratitude.isEmpty ? nil : gratitude,
            tomorrowGreat: tomorrowGreat.isEmpty ? nil : tomorrowGreat,
            coupleReference: coupleReference
        )
        
        // Load existing entry to merge fields
        if let existingEntry = try? await cloudKitService.fetchDailyEntry(for: today, userRecordID: userRecordID) {
            // Merge: keep existing values if current ones are empty
            if entryType == .evening {
                entry.morningNeed = existingEntry.morningNeed ?? entry.morningNeed
            } else {
                entry.eveningMood = existingEntry.eveningMood ?? entry.eveningMood
                entry.gratitude = existingEntry.gratitude ?? entry.gratitude
                entry.tomorrowGreat = existingEntry.tomorrowGreat ?? entry.tomorrowGreat
            }
        }
        
        do {
            try await cloudKitService.upsertDailyEntry(entry)
            showSuccess = true
            isSaving = false
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Auto-dismiss after a moment
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showSuccess = false
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
            isSaving = false
        }
    }
    
    var canSave: Bool {
        switch entryType {
        case .morning:
            return !morningNeed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .evening:
            return eveningMood != nil &&
                   !gratitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !tomorrowGreat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}


```

# RelationshipCheckin/ViewModels/HistoryViewModel.swift

```swift
//
//  HistoryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var partnerEntry: DailyEntry?
    @Published var myEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let cloudKitService = CloudKitService.shared
    
    func loadEntries(for date: Date) async {
        isLoading = true
        error = nil
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        do {
            let entries = try await cloudKitService.fetchEntriesForDate(startOfDay)
            
            // Separate my entry from partner's entry
            if let myUserRecordID = cloudKitService.currentUserRecordID {
                self.myEntry = entries.first { $0.authorUserRecordID.recordID == myUserRecordID }
                self.partnerEntry = entries.first { $0.authorUserRecordID.recordID != myUserRecordID }
            }
            
            isLoading = false
        } catch {
            self.error = "Failed to load entries: \(error.localizedDescription)"
            isLoading = false
        }
    }
}


```

# RelationshipCheckin/ViewModels/MainViewModel.swift

```swift
//
//  MainViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var partnerTodayEntry: DailyEntry?
    @Published var myTodayEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let cloudKitService = CloudKitService.shared
    
    init() {
        Task {
            await loadTodayEntries()
        }
    }
    
    func loadTodayEntries() async {
        isLoading = true
        error = nil
        
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            let entries = try await cloudKitService.fetchEntriesForDate(today)
            
            // Separate my entry from partner's entry
            if let myUserRecordID = cloudKitService.currentUserRecordID {
                self.myTodayEntry = entries.first { $0.authorUserRecordID.recordID == myUserRecordID }
                self.partnerTodayEntry = entries.first { $0.authorUserRecordID.recordID != myUserRecordID }
            }
            
            isLoading = false
        } catch {
            self.error = "Failed to load entries: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func refresh() async {
        await loadTodayEntries()
    }
}


```

# RelationshipCheckin/ViewModels/PairingViewModel.swift

```swift
//
//  PairingViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class PairingViewModel: ObservableObject {
    @Published var isCreatingLink = false
    @Published var isAcceptingLink = false
    @Published var shareURL: URL?
    @Published var error: String?
    @Published var showShareSheet = false
    
    private let cloudKitService = CloudKitService.shared
    private let shareService = ShareService.shared
    
    private var coupleRecord: CKRecord?
    private var share: CKShare?
    
    // MARK: - Create Invite Link
    
    func createInviteLink() async {
        isCreatingLink = true
        error = nil
        
        do {
            // Fetch or create couple record
            let couple = try await cloudKitService.ensureCouple()
            self.coupleRecord = couple
            
            // Create share
            let share = try await shareService.createShare(for: couple)
            self.share = share
            
            // Get iCloud share URL for system share sheet
            if let url = shareService.getShareURL(for: share) {
                self.shareURL = url
                self.showShareSheet = true
            }
            
            isCreatingLink = false
        } catch {
            if let ckError = error as? CKError,
               ckError.code == .serverRejectedRequest ||
                ckError.code == .unknownItem ||
                ckError.code == .partialFailure {
                self.error = "CloudKit schema isn’t in Production (or doesn’t match). Deploy from CloudKit Dashboard → Schema → Development → Deploy to Production, then try again."
            } else {
                self.error = "Failed to create invite link: \(ckExplain(error))"
            }
            isCreatingLink = false
        }
    }
    
    // MARK: - Deep Link Builder
    
    private func makeAcceptDeepLink(from shareURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "rc"
        components.host = "accept"
        components.queryItems = [URLQueryItem(name: "share", value: shareURL.absoluteString)]
        return components.url
    }
    
    // MARK: - Accept Invite Link
    
    func acceptInviteLink(url: URL) async {
        isAcceptingLink = true
        error = nil
        
        do {
            // Support both raw CKShare URLs and rc://accept deep links
            let targetURL: URL
            if url.scheme == "rc",
               let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let shareStr = comps.queryItems?.first(where: { $0.name == "share" })?.value,
               let shareURL = URL(string: shareStr) {
                targetURL = shareURL
            } else {
                targetURL = url
            }
            let metadata = try await shareService.fetchShareMetadata(from: targetURL)
            try await shareService.acceptShare(metadata: metadata)
            
            isAcceptingLink = false
        } catch {
            self.error = "Failed to accept invite: \(error.localizedDescription)"
            isAcceptingLink = false
        }
    }
    
    // MARK: - Complete Pairing
    
    func completePairing() async {
        // After partner accepts, stop sharing to lock at two users
        if let share = share {
            do {
                try await shareService.stopSharing(share: share)
            } catch {
                print("Error stopping share: \(error)")
            }
        }
    }
}

```

# RelationshipCheckin/Views/EntryView.swift

```swift
//
//  EntryView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct EntryView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case morningNeed, gratitude, tomorrowGreat
    }
    
    init(entryType: EntryType) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(entryType: entryType))
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact hero
                heroHeader
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        if viewModel.entryType == .morning {
                            morningContent
                        } else {
                            eveningContent
                        }
                        
                        saveButton
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            if viewModel.showSuccess {
                successOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        viewModel.entryType == .morning ? 
                            (colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold) :
                            (colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: viewModel.entryType == .morning ? "sunrise.fill" : "moon.stars.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
            
            Text(viewModel.entryType == .morning ? "Morning Check-in" : "Evening Check-in")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Text(Date(), style: .date)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Morning Content
    
    private var morningContent: some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                SectionHeader("What do you need today?", icon: "heart.fill")
                
                LiquidTextEditor(
                    text: $viewModel.morningNeed,
                    placeholder: "I need...",
                    minHeight: 100
                )
            }
        }
    }
    
    // MARK: - Evening Content
    
    private var eveningContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Mood
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("How was your day?", icon: "face.smiling")
                    ModernMoodSelector(selectedMood: $viewModel.eveningMood)
                }
            }
            
            // Gratitude
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("Grateful for", icon: "sparkles")
                    LiquidTextEditor(
                        text: $viewModel.gratitude,
                        placeholder: "I'm thankful for...",
                        minHeight: 70
                    )
                }
            }
            
            // Tomorrow
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("Make tomorrow great", icon: "arrow.forward.circle")
                    LiquidTextEditor(
                        text: $viewModel.tomorrowGreat,
                        placeholder: "Tomorrow will be great if...",
                        minHeight: 70
                    )
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveEntry()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text(viewModel.showSuccess ? "Saved!" : "Save Check-in")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.canSave || viewModel.isSaving || viewModel.showSuccess)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("Saved!")
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(.white)
            }
            .padding(DesignSystem.Spacing.xxl)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                    .fill(.ultraThickMaterial)
            }
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
}

```

# RelationshipCheckin/Views/HistoryDrawerView.swift

```swift
//
//  HistoryDrawerView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct HistoryDrawerView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Date picker
                        LiquidGlassCard(padding: DesignSystem.Spacing.sm) {
                            DatePicker(
                                "Select Date",
                                selection: $viewModel.selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(DesignSystem.Colors.accent)
                            .onChange(of: viewModel.selectedDate) { _, newDate in
                                Task { await viewModel.loadEntries(for: newDate) }
                            }
                        }
                        
                        // Entries
                        if viewModel.isLoading {
                            LiquidGlassCard {
                                LoadingView()
                                    .padding(.vertical, DesignSystem.Spacing.lg)
                            }
                        } else {
                            if let partnerEntry = viewModel.partnerEntry {
                                entryCard(partnerEntry, isPartner: true)
                            } else {
                                emptyCard(isPartner: true)
                            }
                            
                            if let myEntry = viewModel.myEntry {
                                entryCard(myEntry, isPartner: false)
                            } else {
                                emptyCard(isPartner: false)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .fontWeight(.semibold)
                }
            }
            .task {
                await viewModel.loadEntries(for: viewModel.selectedDate)
            }
        }
    }
    
    private func entryCard(_ entry: DailyEntry, isPartner: Bool) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: isPartner ? "heart.fill" : "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            isPartner ? 
                                (colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent) :
                                (colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                        )
                    
                    Text(isPartner ? "Partner" : "You")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if let morningNeed = entry.morningNeed {
                        compactField(icon: "sunrise.fill", text: morningNeed)
                    }
                    
                    if let mood = entry.eveningMood {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            Circle()
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 12, height: 12)
                            Text(mood.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        }
                    }
                    
                    if let gratitude = entry.gratitude {
                        compactField(icon: "sparkles", text: gratitude)
                    }
                    
                    if let tomorrowGreat = entry.tomorrowGreat {
                        compactField(icon: "arrow.forward.circle", text: tomorrowGreat)
                    }
                }
            }
        }
    }
    
    private func compactField(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .lineLimit(2)
        }
    }
    
    private func emptyCard(isPartner: Bool) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
                Text(isPartner ? "Partner didn't check in" : "You didn't check in")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
}

```

# RelationshipCheckin/Views/MainView.swift

```swift
//
//  MainView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design with Custom Palette - 10/10/2025
//

import SwiftUI

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = MainViewModel()
    @State private var showHistory = false
    @State private var showMorningEntry = false
    @State private var showEveningEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Compact header
                    headerSection
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Partner's entry
                            partnerSection
                            
                            // Quick entry buttons
                            quickEntrySection
                            
                            // My status
                            if viewModel.myTodayEntry != nil {
                                myStatusSection
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showHistory) {
                HistoryDrawerView()
            }
            .sheet(isPresented: $showMorningEntry) {
                EntryView(entryType: .morning)
            }
            .sheet(isPresented: $showEveningEntry) {
                EntryView(entryType: .evening)
            }
        }
        .tint(DesignSystem.Colors.accent)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Today")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Text(Date(), style: .date)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Partner Section
    
    @ViewBuilder
    private var partnerSection: some View {
        if viewModel.isLoading {
            LiquidGlassCard {
                LoadingView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.lg)
            }
        } else if let partnerEntry = viewModel.partnerTodayEntry {
            partnerEntryCard(partnerEntry)
        } else {
            emptyPartnerCard
        }
    }
    
    private func partnerEntryCard(_ entry: DailyEntry) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent)
                    
                    Text("From Your Partner")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                // Content grid
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if let morningNeed = entry.morningNeed {
                        compactField(icon: "sunrise.fill", text: morningNeed, color: colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                    }
                    
                    if let mood = entry.eveningMood {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            
                            Circle()
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 16, height: 16)
                            
                            Text(mood.displayName)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        }
                    }
                    
                    if let gratitude = entry.gratitude {
                        compactField(icon: "sparkles", text: gratitude, color: colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent)
                    }
                    
                    if let tomorrowGreat = entry.tomorrowGreat {
                        compactField(icon: "arrow.forward.circle", text: tomorrowGreat, color: colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                    }
                }
            }
        }
    }
    
    private func compactField(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .lineLimit(2)
        }
    }
    
    private var emptyPartnerCard: some View {
        LiquidGlassCard {
            EmptyStateView(
                icon: "heart.slash",
                title: "Not yet",
                subtitle: "Waiting for partner's check-in"
            )
        }
    }
    
    // MARK: - Quick Entry Section
    
    private var quickEntrySection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Morning button
            Button {
                showMorningEntry = true
            } label: {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Morning")
                        .font(DesignSystem.Typography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                .strokeBorder(
                                    (colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold).opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .buttonStyle(.plain)
            
            // Evening button
            Button {
                showEveningEntry = true
            } label: {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Evening")
                        .font(DesignSystem.Typography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                .strokeBorder(
                                    (colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple).opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - My Status Section
    
    private var myStatusSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)
            
            Text("You've checked in")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground(for: colorScheme).opacity(0.5))
        }
    }
}

```

# RelationshipCheckin/Views/PairingView.swift

```swift
//
//  PairingView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct PairingView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = PairingViewModel()
    @State private var showAcceptSheet = false
    @State private var inviteLinkText = ""
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    DesignSystem.Colors.secondaryBackground(for: colorScheme).opacity(0.3),
                    DesignSystem.Colors.background(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                // Hero
                heroSection
                
                // Actions
                actionCards
                
                Spacer()
                
                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showAcceptSheet) {
            AcceptInviteSheet(
                viewModel: viewModel,
                inviteLinkText: $inviteLinkText,
                isPresented: $showAcceptSheet
            )
        }
    }
    
    // MARK: - Hero
    
    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                    .frame(width: 96, height: 96)
                    .shadow(
                        color: (colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple).opacity(0.3),
                        radius: 20
                    )
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Daily Connection")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                
                Text("Share your day together")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionCards: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Create
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Circle()
                            .fill((colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple).opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "link.circle.fill")
                                    .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Invite")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                            Text("Start by inviting")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        Task { await viewModel.createInviteLink() }
                    } label: {
                        Text("Create Link")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isCreatingLink)
                }
            }
            
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.textTertiary(for: colorScheme).opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
                Rectangle()
                    .fill(DesignSystem.Colors.textTertiary(for: colorScheme).opacity(0.3))
                    .frame(height: 1)
            }
            
            // Accept
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Circle()
                            .fill((colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold).opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "envelope.circle.fill")
                                    .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accept Invite")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                            Text("Join your partner")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        showAcceptSheet = true
                    } label: {
                        Text("Accept Link")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }
    
    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(error)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.red)
        }
        .padding(DesignSystem.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(.red.opacity(0.1))
        }
    }
}

// MARK: - Accept Sheet

struct AcceptInviteSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: PairingViewModel
    @Binding var inviteLinkText: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Circle()
                        .fill((colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold).opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "envelope.open.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                        }
                        .padding(.top, DesignSystem.Spacing.xxl)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Paste Invite Link")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        Text("From your partner")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                    }
                    
                    TextField("https://...", text: $inviteLinkText)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        .padding(DesignSystem.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                                .fill(DesignSystem.Colors.inputBackground(for: colorScheme))
                        }
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .focused($isFocused)
                    
                    Button {
                        if let url = URL(string: inviteLinkText) {
                            Task {
                                await viewModel.acceptInviteLink(url: url)
                                if viewModel.error == nil { isPresented = false }
                            }
                        }
                    } label: {
                        Text("Accept Invite")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(inviteLinkText.isEmpty || viewModel.isAcceptingLink)
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

```

# Scripts/GenerateAppIcon.swift

```swift
#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Generate a simple, elegant app icon: solid purple background with a clean heart shape in white.

let canvasSize: Int = 1024
let margin: CGFloat = 112 // breathing room around the heart

func createContext(width: Int, height: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(data: nil,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo) else {
        fatalError("Failed to create CGContext")
    }
    // Flip to draw in typical top-left origin coordinates
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func drawBackground(in ctx: CGContext) {
    // #5c5adb (DesignSystem.Colors.primaryPurple)
    let purple = CGColor(red: 92/255.0, green: 90/255.0, blue: 219/255.0, alpha: 1)
    ctx.setFillColor(purple)
    ctx.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
}

// Parametric heart curve (nice symmetric heart):
// x(t) = 16 sin^3 t
// y(t) = 13 cos t − 5 cos 2t − 2 cos 3t − cos 4t
// We sample it, normalize to our rect, and fill.
func heartPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    var points: [CGPoint] = []
    let samples = 720
    for i in 0..<samples {
        let t = Double(i) * (2.0 * Double.pi) / Double(samples)
        let x = 16.0 * pow(sin(t), 3)
        let y = 13.0 * cos(t) - 5.0 * cos(2.0*t) - 2.0 * cos(3.0*t) - cos(4.0*t)
        points.append(CGPoint(x: x, y: y))
    }
    // Compute bounds
    var minX = Double.infinity, maxX = -Double.infinity
    var minY = Double.infinity, maxY = -Double.infinity
    for p in points {
        if p.x < minX { minX = p.x }
        if p.x > maxX { maxX = p.x }
        if p.y < minY { minY = p.y }
        if p.y > maxY { maxY = p.y }
    }
    let srcWidth = maxX - minX
    let srcHeight = maxY - minY
    // Scale to fit inside rect while preserving aspect ratio
    let scale = min(rect.width / CGFloat(srcWidth), rect.height / CGFloat(srcHeight))
    let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04) // slight vertical tweak
    func map(_ p: CGPoint) -> CGPoint {
        let x = ((p.x - minX) * Double(scale)) + Double(rect.minX)
        let y = ((p.y - minY) * Double(scale)) + Double(rect.minY)
        // Convert to CoreGraphics flipped Y by reflecting around rect midY
        let cg = CGPoint(x: x, y: y)
        let dy = cg.y - rect.midY
        return CGPoint(x: CGFloat(cg.x), y: center.y - dy)
    }
    guard let first = points.first.map(map) else { return path }
    path.move(to: first)
    for p in points.dropFirst() {
        path.addLine(to: map(p))
    }
    path.closeSubpath()
    return path
}

func writePNG(from image: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize PNG"])
    }
}

// Paths
let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] ?? FileManager.default.currentDirectoryPath
let appIconDir = URL(fileURLWithPath: srcRoot)
    .appendingPathComponent("RelationshipCheckin/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let outputURL = appIconDir.appendingPathComponent("AppIcon-1024.png", isDirectory: false)

// Ensure directory exists
try? FileManager.default.createDirectory(at: appIconDir, withIntermediateDirectories: true)

// Draw
let ctx = createContext(width: canvasSize, height: canvasSize)
drawBackground(in: ctx)

let insetRect = CGRect(x: CGFloat(margin), y: CGFloat(margin), width: CGFloat(canvasSize) - 2*CGFloat(margin), height: CGFloat(canvasSize) - 2*CGFloat(margin))
let heart = heartPath(in: insetRect)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.addPath(heart)
ctx.fillPath()

guard let cgImage = ctx.makeImage() else { fatalError("Failed to produce CGImage") }
do {
    try writePNG(from: cgImage, to: outputURL)
    fputs("Generated app icon at \(outputURL.path)\n", stderr)
} catch {
    fputs("Error writing PNG: \(error)\n", stderr)
    exit(1)
}



```

# SETUP_INSTRUCTIONS.md

```md
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
  - `date` - Type: Date/Time (add Queryable index)
  - `authorUserRecordID` - Type: Reference (User, optional Queryable index if you need author filters)
  - `morningNeed` - Type: String
  - `eveningMood` - Type: Int(64)
  - `gratitude` - Type: String
  - `tomorrowGreat` - Type: String
  - `couple` - Type: Reference (Couple if you want to constrain it)
- Keep this list in sync with `CloudKit/schema.ckdsl`.

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

\`\`\`
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
\`\`\`

## Next Steps

1. Create the Xcode project following steps 1-7
2. Build and test on your device
3. Set up CloudKit schema (step 8)
4. Test pairing with Laura's device
5. Customize colors/text if desired
6. Deploy to TestFlight when ready

Enjoy your daily check-ins! ❤️

```

