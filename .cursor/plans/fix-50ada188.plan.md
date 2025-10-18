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