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
