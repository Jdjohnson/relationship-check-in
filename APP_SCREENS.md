# App Screens & User Flow

## Visual Guide to the App

### Screen 1: Loading (First Launch)
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│          ⏳ Loading             │
│                                 │
│       Setting up...             │
│                                 │
│                                 │
└─────────────────────────────────┘
```
**What happens**: 
- App initializes CloudKit
- Fetches user record ID
- Creates custom zone
- Checks pairing status

---

### Screen 2: Pairing (If Not Paired)
```
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
```
**Actions**:
- Tap "Create Link" → Share sheet appears
- Tap "Accept Link" → Paste invite URL

---

### Screen 3: Main Screen (Daily View)
```
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
```
**Actions**:
- Tap calendar icon → History drawer
- Tap Morning → Morning entry form
- Tap Evening → Evening entry form
- Pull down → Refresh

---

### Screen 4: Morning Entry Form
```
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
```
**Actions**:
- Type your need
- Tap Save → Saved to CloudKit
- Auto-dismiss after success

---

### Screen 5: Evening Entry Form
```
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
```
**Actions**:
- Tap mood circle (green/yellow/red)
- Type gratitude
- Type tomorrow goal
- Tap Save → Haptic feedback + save

---

### Screen 6: History Drawer
```
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
```
**Actions**:
- Tap date → Load entries for that date
- Scroll to see both entries
- Tap Done → Return to main screen

---

## Notification Examples

### Morning Notification (8:00 AM)
```
┌─────────────────────────────────┐
│  Relationship Check-in      8:00│
│                                 │
│  Morning Check-in               │
│  One thing I need today...      │
│                                 │
│                          [View] │
└─────────────────────────────────┘
```
**Tap** → Opens morning entry form

### Evening Notification (5:00 PM)
```
┌─────────────────────────────────┐
│  Relationship Check-in     17:00│
│                                 │
│  Evening Check-in               │
│  How was your day?              │
│                                 │
│                          [View] │
└─────────────────────────────────┘
```
**Tap** → Opens evening entry form

---

## User Flow Diagrams

### First Time Setup Flow
```
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
```

### Daily Morning Flow
```
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
```

### Daily Evening Flow
```
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
```

### Viewing Partner's Entry
```
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
```

### Browsing History
```
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
```

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
```
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
```

### Network Error
```
┌───────────────────────────┐
│  ⚠️ Error                 │
│                           │
│  Failed to save:          │
│  Network connection lost  │
│                           │
│  [Retry]                  │
└───────────────────────────┘
```

### Loading State
```
┌───────────────────────────┐
│                           │
│         ⏳                │
│                           │
│      Loading...           │
│                           │
└───────────────────────────┘
```

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

