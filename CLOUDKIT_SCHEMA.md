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
```
1. Click "+" next to Record Types
2. Name: Couple
3. Add Field: ownerUserRecordID
   - Type: Reference (set Reference Type to *User* if desired)
4. Add Field: partnerUserRecordID
   - Type: Reference (set Reference Type to *User* if desired)
5. Save
```

#### Create DailyEntry Record Type
```
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
```

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
```
1. User opens app at 8:00 AM (via notification)
2. App fetches existing DailyEntry for today (if any)
3. User enters "morningNeed"
4. App upserts DailyEntry with recordName: DailyEntry_2025-10-10_UserID
5. Record saved to private database
6. Partner can query and see the entry
```

### Evening Check-in
```
1. User opens app at 5:00 PM (via notification)
2. App fetches existing DailyEntry for today
3. User enters mood, gratitude, tomorrowGreat
4. App upserts same DailyEntry record (merges with morning data)
5. Record updated in private database
6. Partner sees updated entry
```

### Viewing Partner's Entry
```
1. User opens main screen
2. App queries shared database for today's entries
3. Filters entries where authorUserRecordID != currentUserRecordID
4. Displays partner's entry
```

### History View
```
1. User selects date in history drawer
2. App queries both databases for entries on that date
3. Returns array of DailyEntry records
4. Separates by authorUserRecordID
5. Displays both entries side by side
```

## Testing Queries in Dashboard

You can test queries in CloudKit Dashboard:

### Find all entries for a date
```
Record Type: DailyEntry
Predicate: date >= '2025-10-10 00:00:00' AND date < '2025-10-11 00:00:00'
```

### Find user's entries
```
Record Type: DailyEntry
Predicate: authorUserRecordID == [USER_RECORD_ID]
```

### Find couple record
```
Record Type: Couple
Predicate: TRUEPREDICATE
```

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
