# Plan to Migrate the Relationship Check-in App to Supabase

## Overview and Goals

The goal is to replace the current CloudKit + Sign in with Apple backend with Supabase for both authentication and data storage, without changing the user experience. After migration, users will log in with an email/password (Supabase Auth) instead of Apple ID, and all app data will be stored in a Supabase Postgres database (no iCloud storage).

Key objectives include:

- **Full Backend Replacement**: Eliminate CloudKit and use Supabase entirely for user auth and database (same app functionality, new backend).
- **Email/Password Auth**: Implement Supabase's email + password authentication flow for login/signup.
- **Database Schema Migration**: Recreate the data model (Couple, DailyEntry, etc.) in Supabase's SQL database. We don't need a 1:1 schema copy – we can redesign tables for clarity and security as long as the app behavior remains the same.
- **Pairing Logic**: Reimplement the "invite partner" pairing feature using Supabase (e.g., invite codes/links) in a way that fits Supabase's model. This may involve changes to how invites are generated or accepted (since Supabase has no direct analog to CloudKit sharing), but it should achieve the same result: exactly two users paired per "couple".
- **Security & Privacy**: Ensure the new solution is secure and private. Supabase will require enabling Row-Level Security so that each couple's data is only visible to the two partnered users, preserving the privacy model (no one else can access your data).

Following this plan, the app should behave identically from the users' perspective (daily check-ins, notifications, history, etc.), with Supabase seamlessly handling auth and data behind the scenes.

## 1. Set Up the Supabase Project and Auth Configuration

**Create a Supabase Project**: If not done already, create a new project in the Supabase Dashboard. Make note of the Project URL and API keys (in particular the anon public key for client-side use, and the service role key for admin operations). These will be needed in the app code for initializing the Supabase client.

**Configure Auth Provider**: In the Supabase Dashboard under Authentication > Settings, enable Email/Password sign-ups (this is enabled by default). Since we plan to use basic email login, you can disable any other providers (Apple, Google, etc.) unless you want to add them later.

**Optional - Email Confirmation**: Decide if new users must confirm their email address. By default, Supabase will send a confirmation email for sign-ups. For a smoother UX (closer to the Apple ID flow which didn't require extra confirmation), you might disable "Confirm email" in the auth settings. This way, signUp() returns an active session immediately without requiring the user to verify their email first.

**Environment Variables**: In your app, prepare to store the Supabase credentials. You can add them to a config (for example, in Swift you might store the URL and anon key securely, perhaps in the code or an .xcconfig since the anon key is okay to expose on the client). These will be used to initialize the Supabase client SDK.

**Initialize Supabase in the App**: Add the official Supabase Swift SDK to the Xcode project via Swift Package Manager. Then initialize the client at app launch with your Supabase project URL and anon key. For example:

```swift
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
  supabaseKey: "YOUR_ANON_PUBLIC_KEY"
)
```

This initializes the Supabase client and handles JWT token storage and authentication for making authenticated requests.

**Persisting User Session**: The Supabase Swift SDK will automatically persist the user's session (JWT) and refresh it as needed, so users stay logged in across app launches. Ensure this is working by testing that after signing in, the session is retained (the SDK likely uses Keychain or UserDefaults for token storage).

**Result**: At this stage, we have a Supabase project ready with email/password auth enabled, and our app knows how to connect to Supabase. Next, we'll set up the database schema to mirror the CloudKit data model.

## 2. Define the Database Schema in Supabase

With Supabase's Postgres, we will create tables equivalent to the CloudKit record types (Couple and DailyEntry), with adjustments for relational database structure. Below is a proposed schema design:

### Table: couples

Represents a pairing of two users (similar to the CloudKit "Couple" record).

- **id**: UUID primary key for the couple (we can use UUIDs so that invite links can be based on them, making them hard to guess).
- **owner_user_id**: UUID referencing the Supabase Auth user who initiated/owns the couple.
- **partner_user_id**: UUID referencing the other user (can be NULL until the partner joins).
- **invite_code**: Text or UUID used as an invite token for pairing. This could default to the same value as id or a separate random code. Using a random invite code is helpful if you don't want to expose the raw couple UUID in invites, but using the UUID itself as the token is also acceptable (it's essentially random).
- (Optional) Additional fields as needed – e.g., a created timestamp, etc., though not strictly necessary for functionality.

**Notes**: In CloudKit, the Couple record stored references to two users (owner and partner). In Supabase, owner_user_id and partner_user_id will store the Supabase Auth UIDs of the two users. We can enforce that each user can belong to at most one couple (e.g., by writing application logic or constraints to prevent a user appearing in multiple couples). For instance, we might add a unique index on owner_user_id and another on partner_user_id to disallow reuse (since the app is only for two people total).

### Table: daily_entries

Represents the daily check-in data (similar to CloudKit "DailyEntry" records). Each entry is one user's check-in for a given date.

- **id**: UUID or bigserial primary key for the entry.
- **couple_id**: UUID foreign key referencing the couples table (which couple this entry belongs to).
- **author_user_id**: UUID referencing the user (Supabase Auth ID) who wrote this entry.
- **date**: Date (could be a date type or timestamp). We will use this to identify the day of the entry.
- **morning_need**: Text, the "one thing you need today" (morning check-in answer).
- **evening_mood**: Integer, the mood rating for evening (e.g., 0=green, 1=yellow, 2=red).
- **gratitude**: Text, something you're grateful for (evening check-in).
- **tomorrow_great**: Text, what you hope for tomorrow (evening check-in).

**Notes**: These fields correspond to the CloudKit DailyEntry record fields. We'll ensure couple_id and author_user_id are NOT NULL (an entry must belong to a couple and have an author). We can also enforce that each user has at most one entry per day: for example, add a unique constraint on (author_user_id, date) so that a user can't create two entries for the same day. This mirrors the logic in CloudKit where the record name was derived from user + date to ensure one per day.

### Optional - Table: profiles or user metadata

We might create a profiles table to store any user-specific data outside of auth (like a display name or a role). In CloudKit there was a Users record type with a roles list, but it doesn't seem critical for our app's functionality. Unless you need to store extra info per user, we can skip creating a profiles table for now. The Supabase Auth users table (built-in) will hold basics like the user's email and unique ID. You can later extend this with a profile table if needed (e.g., to store an avatar or name).

### Creating Tables and Policies

**Use the Table Editor or SQL Editor** to create the above tables. If using SQL, write CREATE TABLE statements for couples and daily_entries with the columns and types described. Since you plan to add the schema via the interface, ensure to also set up foreign key relations:

- couples.owner_user_id and couples.partner_user_id should each have a foreign key reference to the Supabase auth users table (which is auth.users). Typically, you can make these UUID fields and later join them to auth.users.id via queries. (Note: The auth.users table isn't in the public schema, but you can create foreign key references to it in Supabase by referring to auth.users in the reference. Alternatively, you simply treat these as UUIDs and ensure via app logic they match actual user IDs.)
- daily_entries.author_user_id should also reference auth.users.id (the user who authored the entry).
- daily_entries.couple_id references couples.id.

**Enable Row Level Security (RLS)**: After creating the tables, enable RLS on them (in Supabase, you must turn on RLS to enforce policies). In the dashboard, toggle RLS "ON" for both new tables. Initially, with RLS on and no policies, the data will not be accessible until we add specific policies.

### Define Security Policies

We need to restrict data access so that each user can only read/write their own data or their pair's shared data. We will add policies for the couples and daily_entries tables:

**couples table policies:**

- **Select policy**: Allow a user to SELECT (read) a couple row if they are one of the members of that couple. In SQL policy form, something like: `auth.uid() = owner_user_id OR auth.uid() = partner_user_id`. This ensures only the two users in a couple can read that couple record.
- **Insert policy**: Allow inserting a new couple if the owner_user_id is the user themselves. (The app will create a couple record when a user initiates an invite; we must ensure they can insert that row with themselves as owner.) For example: `auth.uid() = owner_user_id` on insert.
- **Update policy**: Allow updating the couple to add a partner only in the intended scenario. We want to let the invited partner set the partner_user_id of their couple. We have to be careful: by default, a user who isn't yet part of the couple cannot pass the select policy to even see the row. One strategy is to create a special update policy: `auth.uid() IS NOT NULL AND partner_user_id IS NULL` (meaning any signed-in user can attempt to set the partner on an unpaired couple). This is a bit broad, so we'll combine it with application logic requiring a valid invite code. Essentially, the invite code is a secret "key" that a second user must have to know which couple to attach to. We will rely on the uniqueness/unguessability of the invite code (or couple UUID) to prevent unauthorized access. After the partner is set, the general select policy takes over to restrict access to just those two users.

Alternatively, for stricter security, we can avoid opening up update to all users by using a server-side function (described in the pairing section below) that runs with elevated privileges to add the partner. In that case, the partner wouldn't directly update the row; instead an RPC function would do it, and we could keep the policy simple (only owner/partner can update, and let the RPC handle the special case).

**daily_entries table policies:**

- **Select policy**: Allow a user to read daily_entries if they are part of the relevant couple. We can implement this by checking that the user is either the author or the partner in that entry's couple. For example, a policy could join to the couples table: `auth.uid() = daily_entries.author_user_id OR auth.uid() = (SELECT owner_user_id FROM couples WHERE id = daily_entries.couple_id) OR auth.uid() = (SELECT partner_user_id FROM couples WHERE id = daily_entries.couple_id)` – this ensures the user is one of the two in the associated couple. Another approach is to store each user's couple ID in a profile or JWT claim to simplify the check. But using a subquery in the policy as above is straightforward and ensures only the two relevant users can see the entries.
- **Insert policy**: Allow inserting a new daily entry if `auth.uid() = author_user_id AND auth.uid()` is a member of the couple specified. We might enforce via a check that the couple_id on the entry actually corresponds to a couple that the auth.uid() belongs to. This can be done with a subquery or a custom function. For simplicity, one can first fetch the user's couple (e.g., client side, you know your couple_id once paired) and use that in the insert; the policy can just ensure the author matches the token's user. For example: `auth.uid() = author_user_id` might suffice if we trust the client to only use their own couple_id.
- **Update policy**: Allow updates on daily_entries if `auth.uid() = author_user_id` (so users can edit their own entries). This will let a user add their evening responses to the entry they created in the morning, or make edits, but it prevents them from altering their partner's entries.
- **Delete policy**: Possibly not needed (the app likely doesn't delete entries), but you could restrict deletes to the author as well if needed.

Use Supabase's policy editor to create these rules. Supabase's docs example – "Individuals can view their own todos" – is analogous to our use case. We are essentially implementing "users can view and modify their own entries, plus view their partner's entries." Ensure to test these policies with the Policy Preview tool or with actual users to confirm they work as intended.

## 3. Implement Email/Password Authentication in the App

With the backend ready, update the iOS app to use Supabase Auth for login and account creation:

**New Login/Signup UI**: Replace the "Sign in with Apple" flow with a simple email & password form. Likely, you'll add screens for: Sign Up (create account with email, password) and Sign In (login with existing credentials). This can be a basic SwiftUI form where the user enters their email and password. Provide validation and feedback (e.g., password length requirements – Supabase default minimum is 6 characters).

**Using Supabase Auth API**: The Supabase Swift SDK provides async methods for authentication. For example:

- **Sign Up**: Call `try await supabase.auth.signUp(email: "user@example.com", password: "secret123")` to register a new user. Check the result for errors. If email confirmation is off, this will return a user session immediately; if confirmation is on, you may need to inform the user to check their email. You can also pass user metadata here if needed (not critical now, but an example: `signUp(..., data: ["full_name": .string("Alice")])` to store extra info).
- **Sign In**: Call `try await supabase.auth.signIn(email: "user@example.com", password: "secret123")` to log in an existing user. On success, Supabase provides a session token that the SDK will store, meaning the user is now authenticated for future API calls.
- **Sign Out**: If your app needs a logout option, use `try await supabase.auth.signOut()` to invalidate the session. This will also clear the stored credentials so that the next launch requires login.

The above calls can be integrated into your ViewModels. For instance, you might create an AuthViewModel that wraps these calls and updates published state (like `isLoggedIn`) based on success or failure. Handle errors (e.g., wrong password, user not found, etc.) and present messages to the user as needed. Supabase will return error messages for common auth issues.

**Password Reset**: Supabase can handle password resets via email if you enable it. You might not need this for a private app, but it's good to be aware. Users can request a reset email via `supabase.auth.resetPasswordForEmail("user@example.com")` which sends a link. If you enable this, you'd also implement a screen to capture the new password after the link (Supabase iOS SDK can handle the verification link via deep link). This is optional; since previously Apple ID took care of credentials, password reset is a new consideration with email login.

**Remove Apple Auth Code**: You can remove the Sign in with Apple capability and any related code (like ASAuthorizationController usage). Also update the app's provisioning: since we no longer need CloudKit/Apple auth, you can disable the iCloud capability in Xcode (if you want to avoid prompting for iCloud at app start). The app will now rely on the Supabase backend exclusively for identity.

After this step, the app should allow creating a new account (for Person A), and that user can log in and reach the main part of the app (though currently they will have no partner paired and an empty check-in history). We will address pairing next.

## 4. Reimplement the Pairing (Invite Partner) Logic

One of the biggest changes is how we handle inviting the partner, since CloudKit's sharing mechanism must be replaced. In the current app, one user creates a share link via CloudKit (CKShare), sends it to their partner, and upon accepting, the app links the two users in the Couple record. We will recreate this flow using Supabase in these steps:

**Generating an Invite**: When user A (logged in) wants to invite user B, the app will:

- Create a Couple record in Supabase with `owner_user_id = A's user ID` and `partner_user_id = NULL`. Also generate an `invite_code` (if using one separate from the couple's UUID). This can be done by calling `supabase.from("couples").insert(...)` with the appropriate fields. For example, you can generate a UUID in Swift for the id / invite_code or rely on Postgres to generate one (Supabase can auto-generate UUID PKs). On success, you get the new couple's ID (or you could fetch the code if generated server-side). Store this couple ID in the app state (e.g., in A's profile or local storage) because user A is now considered "paired pending acceptance".

**Share the Invite Code/Link**: Create a mechanism for A to share with B. This could be a custom URL using the app's URL scheme. For example, define a URL format like `rc://invite?<code>` or `rc://invite/<code>` that the app can open. If the app is installed, tapping such a link will launch it and pass the code. You can use SwiftUI/UIKit's environment to handle incoming deep links (e.g., via onOpenURL or the app delegate's URL handling). The invite link can be sent via iMessage, email, etc., using an iOS share sheet (UIActivityViewController) – essentially just share a short text like "Join me on Relationship Check-in: rc://invite/123e4567-e89b...".

Note: Instead of a custom URL scheme, you could also use a universal link or just copy-paste code manually, but since the app already has a custom scheme `rc://` for deep links, reusing it is convenient. Make sure to add a new path for invites (the README lists entry/morning and entry/evening but not an invite path, so you'll extend that).

**Accepting an Invite**: When user B receives the link (e.g., via Messages) and taps it, the app opens and we need to handle the invite:

- **App opens via Deep Link**: The app should parse the incoming URL to extract the invite code or couple ID. For example, if the link was `rc://invite/<invite_code>`, parse `<invite_code>`.
- **If user B is not logged in yet**: You must redirect them to the signup/login flow first. (In CloudKit, tapping the share would prompt Apple ID login if not already – here we handle it manually.) You might store the invite code temporarily (in a singleton or @AppStorage) while the user signs up. After B successfully creates an account and logs in (via Supabase Auth), detect if there's a pending invite code and proceed.
- **Join the Couple**: Now, with B authenticated and the invite code in hand, the app will connect B to A's couple. We have two approaches:

  - **Direct client update (simpler)**: Use the invite code to find and update the couples row. For example, the app can call `supabase.from("couples").update({ partner_user_id: B's UID }).eq("invite_code", code)` to set B as the partner. Because of RLS, we allowed updates on couples where partner_user_id is null (and using the code ensures we target the right row). This will succeed only if the invite code matches and the row was unclaimed. After this, the couple record now has both user IDs. You can then save the couple ID to B's state.

    **Security**: As mentioned, this approach relies on the invite code being secret. The update query itself is only allowed because of our special RLS policy (any auth user can update an unpaired couple). We must ensure the code is hard to guess (which it is if using a UUID or sufficiently random string). Once updated, no further changes or additional members can join – you could even have a trigger or additional update policy to forbid changing a non-null partner_id to another value (ensuring a couple remains two specific people). Also, you may want to clear or invalidate the invite code after use (you could set invite_code = NULL in the same update when filling partner_id). And similar to CloudKit's stopSharing() action, deleting or nulling the invite prevents reuse of that link.

  - **Edge Function / RPC (advanced)**: For a more secure pattern, implement the pairing on the server side. For example, create a Supabase Edge Function (a small TypeScript function deployed on Supabase) that takes an invite code and the calling user's token, and if valid, performs the pairing using the service role (bypassing RLS). This could further validate that the calling user isn't already in a couple, etc. The client would invoke this function instead of directly updating the table. The end result is the same, but it avoids opening up a broad update policy. However, given our use-case (private app, limited users), this overhead might not be necessary. It's mentioned as a potential improvement for scalability/security.

**Sync App State**: After a successful join, both user A and B should now be "paired" in the app's view. Update any local state or view models: e.g., set `isPaired = true` and store the `couple_id`. User A's app might also need to be informed that the partner joined. We can handle this by simply fetching the couple record periodically or using Supabase's real-time feature. Simpler: when B joins, have B's app write something (like insert a first dummy entry or just rely on both now having the same couple_id to fetch entries). User A can pull to refresh, or you could set up a listener on the couples table via Supabase's realtime subscription to get notified when the partner_id field gets filled. That way, A's app could automatically update when B joins. This is optional, but Supabase does support realtime on database changes if you want to use it.

**Finalize pairing**: Once the couple is formed, you can remove or ignore the invite code. In CloudKit, after accepting, they called stopSharing() to prevent more people from using the link. In Supabase, since we only allow one partner and we've set it, any further attempt to use the same code should be rejected (because partner_id is no longer null, the update policy or function will fail). For cleanliness, you might set the invite_code to NULL or some "used" status.

**Testing the Invite Flow**: Thoroughly test with two accounts: have one create an invite, send the link (you can simulate this by copying the link and using Simulator > Open URL or on device directly). Test the edge cases: what if B opens the link after already being paired or with an invalid code? Ensure the app handles errors (Supabase will return an error if update fails, e.g., due to RLS or no row found). Also test that once paired, each user can see the other's data (to be verified in the next section).

By implementing the above, we replicate the pairing logic in a way that "makes sense with Supabase," using either direct secure updates or an edge function, instead of CloudKit sharing. The UX remains: A taps "Invite Partner" -> share link -> B taps link and joins.

## 5. Replace CloudKit Data Operations with Supabase

With auth and pairing in place, the core app functionality – daily check-ins and viewing history – must be reworked to use Supabase queries instead of CloudKit fetches. Below are the changes to implement in the service or view model layer:

**Fetching the Current Couple**: In CloudKit, the app determined the current user's Couple record on launch (checking if already paired). With Supabase, after login you can query the couples table for any record containing the user's ID. For example:

```sql
supabase.from("couples").select("*").or("owner_user_id.eq.YOUR_UID,partner_user_id.eq.YOUR_UID")
```

With RLS, you could alternatively simply select all from couples and the policy will only return the row for which the user is owner/partner. This will tell you if the user is already paired or not. You might call this at app launch or store the couple_id upon pairing. The result of this query (if not empty) gives the couple_id and the partner's user ID. Save those in a global state (e.g., a SessionStore). If no couple is found, the user is not paired yet.

**Creating a Daily Entry (Morning Check-in)**: Formerly, the CloudKitService created or updated a DailyEntry record when the user submitted their morning need. Now, when user (say A) enters their morning check-in:

- Determine today's date (and possibly standardize to midnight as done before).
- Call `supabase.from("daily_entries").insert({...})` with a new entry object: include couple_id (the ID of A's couple), author_user_id (A's UID), date (today), and morning_need (the text input). Leave evening fields null/empty. Supabase will insert the row. Thanks to our insert policy, this will be allowed as long as A is authenticated and the author_user_id matches A. The response will include the created entry (with its generated id).

You may consider upsert behavior: Supabase Swift doesn't have a single upsert call like CloudKit's save does. But since we enforced one entry per user per day, you could either:
  - Check if an entry exists for today (see next bullet) and then update instead of insert, or
  - Use `supabase.from("daily_entries").upsert({...}, onConflict: "author_user_id,date")` if supported. Alternatively, simply attempt insert and handle the error if one exists (but with our unique constraint, a duplicate insert would error out, so safer to check first).

Edge case: If the user opens the morning screen twice, ensure not to duplicate entries. One approach: when navigating to the morning check-in, do a quick fetch for today's entry. If exists, use it (maybe they are editing). If not, then create.

**Updating a Daily Entry (Evening Check-in)**: When the user (A) later fills in the evening part (mood, gratitude, tomorrow's goal):

- Fetch today's entry if not already in memory (you might have saved it from the morning insert). You can query: `supabase.from("daily_entries").select("*").eq("date", today).eq("author_user_id", A's UID)` – with RLS, you could just filter by date and you'll only get your own entry.
- Then call `supabase.from("daily_entries").update({...}).eq("id", entry_id)` to update the fields evening_mood, gratitude, tomorrow_great. Our update policy allows this since A is the author.

Alternatively, we can combine creation and update: simply always upsert. But handling explicitly is fine.

**Fetching Partner's Entries (Main Screen & History)**: The main screen in the app shows your partner's latest check-in (for today) and possibly your own. The history screen allows browsing past dates and seeing both users' entries for a selected date. Here's how to retrieve data:

- To get both entries for a particular date (one by each partner), query the daily_entries table by date and couple. For example: `supabase.from("daily_entries").select("*").eq("date", selectedDate).eq("couple_id", myCoupleId)`. With RLS in place, the user will only get results if the couple_id matches their couple (which it does). This query should return up to 2 rows (one for each partner, if both have an entry that day).
- For the main screen (today's entries), do the same query for date = today. The result is an array of 0, 1, or 2 entries. If 2, then both partners have submitted; if 1, maybe only one person has done it so far (the app can handle that by showing one entry and waiting for the other). You might want to differentiate which entry is whose – the author_user_id will tell you. You can compare it to the current user's UID or the partner's UID. In CloudKit, they perhaps distinguished by record ownership; in Supabase you'll do it manually (e.g., if entry.author_user_id == my UID, that's my entry; if equals partner's UID, that's partner's entry).
- For history list (if you show a list of past dates), you might query all entries for the couple in a range or do it day-by-day when the user selects a date. The CloudKit code fetched entries by date range for a given day. In Supabase, you could fetch a range of dates if needed (using .gte() and .lt() filters). A straightforward approach: when user picks a date in calendar, perform the query for that specific date as above. If you want to show an overview of which days have entries, you might do a single query for all entries for that couple (the policy will return all of that couple's entries) and then group by date in the app. This is feasible if the data is small (which in a personal app it is). If needed, you can add an index on the date column to speed up date queries.

**Removing CloudKit Code**: You can now remove or bypass the CloudKitService and ShareService. All their functionality (initialization, zone handling, share creation, record fetches in private/shared DB, etc.) is obsolete. For instance, CloudKit's checkPairingStatus() and findCoupleRecord() are replaced by a direct Supabase query for the couple. The asynchronous patterns will now revolve around network calls to Supabase (which are also async but likely faster/simpler than CloudKit's sync/sharing). Remove any CloudKit-specific error handling or edge cases (e.g., CloudKit account status checks).

Also adjust any UI logic that depended on CloudKit's timing. Supabase calls should generally be quick, but you might want to show a loading indicator while fetching data. Use Swift concurrency (async/await) as shown in Supabase examples to fetch data in a task and update @State variables.

**Notifications & Offline**: The local notification schedule (8 AM / 5 PM reminders) can remain unchanged, as that was device-side. However, note that unlike CloudKit (which could queue writes offline to sync later when network returns), Supabase calls will require an internet connection at the time of use. You might want to handle offline scenarios gracefully (e.g., if a user tries to submit a check-in with no connection, cache it and submit later). Supabase does not automatically sync offline data, so it would be up to you to implement any caching if needed. In a personal app context, this might be an acceptable limitation (just something to be aware of).

At this point, all core features – account creation, pairing, creating daily entries, viewing partner's entries – are implemented via Supabase. The app no longer uses any CloudKit APIs; all data comes from Supabase queries. We've maintained the same data fields and logic, just using a different backend.

## 6. Testing and Data Migration

With the implementation complete, perform thorough testing and plan for migrating any existing data:

### Functional Testing:

**Sign Up/In**: Create two test accounts (you and your partner, for example). Ensure that both can sign up and log in via Supabase. Verify the email confirmation behavior if it's on (you receive an email and can activate) or off (immediate login).

**Pairing Flow**: Have one account invite the other. Test the entire invite flow end-to-end:
- User A creates an invite – verify a new row in couples is created (you can check in Supabase dashboard) with A's ID and partner NULL. Ensure the invite link is generated and can be opened.
- User B clicks the link – if B wasn't logged in, confirm the app handles it (prompts login). After B logs in, the pairing should complete: verify in the DB that the partner_user_id got filled with B's ID. Also verify that both A and B's app now treat them as paired (e.g., maybe the UI goes to the main screen automatically, etc.).
- Test that the invite link cannot be reused: if one of you tries clicking the same link again (or if a third account tried, if you create one for testing), it should fail. The app should handle this gracefully (e.g., show "Invite invalid or already used").
- If you implemented an edge function for invites, also test scenarios like invalid code or already paired user tries to accept an invite (should be handled server-side with an error).

**Daily Check-in**: After pairing, test creating entries:
- **Morning**: User A enters a morning check-in. Check that the entry appears in Supabase (in daily_entries table) with correct data. User B's app when refreshed (or via a fetch button) should retrieve nothing for that morning yet, or just A's entry if you choose to show partner's submission as soon as it's there.
- **Evening**: User A later enters evening info (update the same entry). Verify the database row got updated properly. Ensure the app shows the updated info.
- **Both entries**: User B does their check-in as well. Verify both entries exist for the day and each contains the right person's data. On each other's app, both entries should be visible for that date. Test the main screen logic that shows partner's latest entry.
- **History**: Try a past date history: make some dummy entries for previous days (you can either backdate via the app by temporarily allowing setting a custom date, or directly insert via SQL for testing). Ensure the history view can load two entries for any given date.

### Edge Cases:

- **Unpaired user entries**: If a user is not paired and somehow tries to create a DailyEntry, our app logic shouldn't allow it (perhaps the UI for check-ins is disabled until paired). But if it did, the insert policy requiring a valid couple might fail. Decide how you want to handle the period before pairing – maybe the app doesn't let you create entries until you have a partner (since the concept is for couples only). You could optionally allow "solo" entries by still creating a couple and treating them as single (but that's out of scope unless desired). Likely, you will keep the requirement that one must invite a partner to use the app beyond the landing screen.

- **Multiple couples**: Ensure that a user who is already in a couple cannot create a second couple or accept a second invite. In our design, if they tried to invite someone else while already paired, one of our constraints or checks should prevent it (or we simply hide the invite option once paired). If using the unique index on user IDs in couples, the insert would fail – handle that error gracefully. Similarly, if a paired user somehow tried to accept another invite, the server function or update might error out; the app should not normally allow this action in the UI.

### Performance Considerations:

With Supabase, network latency should be low, but test how quickly data appears. Possibly add loading spinners during network calls (e.g., when fetching history or waiting for an invite acceptance). Supabase's real-time could be a bonus: for instance, subscribe to the daily_entries table for your couple so that when your partner submits an entry, your app gets a push event. This could update the UI in near real-time (like a live feed). This is an enhancement, not required – initial version can rely on manual refresh.

### Data Migration (if needed):

If you have existing data in CloudKit from prior use (entries that you and your partner have already submitted), you may want to migrate it so it appears in the new system. Supabase won't pull data from CloudKit automatically, so consider:

**Exporting Data from CloudKit**: Apple's CloudKit Dashboard might allow you to query and export records. Alternatively, you could write a small script (or modify the app in a debug mode) to fetch all DailyEntry records via the CloudKit API and output them (e.g., print as JSON). Since this is a personal app, you might have at most a few dozen entries – manual copy is feasible. If the data volume is low, the simplest method might be to display past entries in the old app and copy-paste important ones.

**Import into Supabase**: You can insert historical entries into the daily_entries table using the SQL editor or a CSV import. Each entry will need a valid couple_id and author_user_id. One approach: after you and your partner are paired in the new system (so you have a couple_id), you can backfill entries for that couple. For each past date, insert two rows (one for each of you) with the content you have from CloudKit. You could do this via SQL INSERT statements. Make sure to disable RLS or use the service role (or the dashboard which bypasses RLS) when doing a bulk import.

**Importing Users**: Since you and your partner will just sign up in Supabase, we likely don't need to programmatically migrate the user accounts – you can each create an account. For a broader user base, one could use Supabase admin functions to create users ahead of time, but in this scenario manual signup is fine.

**Verification**: After importing, check that all past entries are correctly visible in the history screen of the app. This ensures the schema alignment is correct (dates, etc.).

### Privacy and Security Testing:

Finally, verify that the RLS policies truly prevent unauthorized access:

- Try to query data as one user that should belong to another (for example, in a test, use the Supabase API with one user's token to request another couple's ID or entries). It should return nothing or deny access. This confirms our policies like `auth.uid() = user_id` are effective. Supabase's policy tester can simulate another user ID to ensure no leakage.
- Ensure that even if one knows a random couple ID or entry ID, they cannot access it unless they are part of that couple. This is analogous to CloudKit's protection where only shared users had access.

By the end of testing, you should have confidence that the app works correctly on Supabase, and that all existing important data (if any) is carried over.

## 7. Deployment and Next Steps

With a successful migration in development, consider these final steps before releasing the updated app:

**Update App Configuration**: Remove the iCloud capability and entitlement since it's no longer needed, and add any required configuration for Supabase. Supabase endpoints use HTTPS, so as long as ATS (App Transport Security) allows HTTPS (it does by default), you're fine. No further entitlement is needed for network calls. If you added a custom URL scheme for invites, ensure it's declared in Info.plist (CFBundleURLSchemes). You likely already have `rc://` scheme registered from before (check Info.plist). Add an entry if not, so iOS knows to route rc:// links to your app.

**Monitoring and Logs**: Supabase provides logs in its dashboard. Since this is a new backend, keep an eye on the logs for errors, especially around auth and RLS rejections. During the initial rollout, you (and your partner) are effectively beta-testing the new setup, so watch for any "permission denied" or other issues in the Supabase logs when you perform actions. Adjust policies if needed.

**Analytics and Performance**: If desired, integrate Supabase's monitoring or add your own logging to track whether calls succeed. (The original app had no third-party analytics, and you might keep it that way for privacy.) Supabase itself will handle performance of the DB; given the small scale, there should be no issues.

**Documentation and Code Cleanup**: Update the README/documentation of the project to reflect the new architecture: e.g., note that data is stored in Supabase (hosted Postgres) rather than "private iCloud", and authentication is via email/password (with Supabase Auth) rather than Sign in with Apple. This is important for transparency since originally it was touted as having no third-party servers – now Supabase is a third-party cloud service, so adjust any privacy statements accordingly. Supabase is secure, but users (even if just internal) should know data isn't solely on their iCloud anymore.

**Possible Future Improvements**: Now that the app runs on Supabase, you have more flexibility:

- You could integrate cross-platform support (Android, web) since Supabase is not Apple-specific.
- You could enable OAuth providers (Supabase can support Sign in with Apple, Google, etc., if you ever want to reintroduce those for convenience – Supabase Auth makes it possible to link an Apple login to the same account, etc.).
- You could also utilize Supabase features like Edge Functions (for things like sending an email invite or processing data) and Storage (if you wanted to allow photo attachments in check-ins, for example). Those are outside our current scope but now available in your toolkit.

Finally, deploy the app update (TestFlight or App Store) and ensure both users update to this new version before fully discontinuing CloudKit. There might be a transition period where old data remains in iCloud; once confident, you could remove that legacy data. But since this is a private app, coordinating the switch is easier – you and your partner can likely migrate on a set day.

## Conclusion

Following this plan, the Relationship Check-in app will use Supabase for all authentication and data storage. The end result is the same UX – two users privately sharing daily updates – backed by a modern cloud stack. All data will be centralized in your Supabase project (accessible to you as the developer, and of course to the two users through the app with proper auth), and protected by database-level security policies. This migration sets the stage for easier maintenance and possible expansion of the app across platforms, while still keeping the personal, secure nature of the experience. Good luck with the implementation, and enjoy the benefits of your new Supabase backend!

## References

- [Supabase Documentation](https://supabase.com/docs)
- [Swift: Create a new user](https://supabase.com/docs/reference/swift/auth-signup)
- [Swift: Sign in a user](https://supabase.com/docs/reference/swift/auth-signinwithpassword)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Use Supabase with iOS and SwiftUI](https://supabase.com/docs/guides/getting-started/quickstarts/ios-swiftui)
- [Password-based Auth](https://supabase.com/docs/guides/auth/passwords)
- [Auth architecture](https://supabase.com/docs/guides/auth/architecture)
