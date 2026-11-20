# SHARD-SYNC-008: Link anonymous data

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-008 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-008 |
| **Priority** | High |
| **Status** | In Progress |
| **Complexity** | L |
| **Depends On** | SYNC-003, SYNC-005, SYNC-006 |

## Description

When this install is anonymous and already has a diary, Google or email sign-in should `linkWithCredential` so `users/{uid}` stays put. That link attempt is in `AccountAuthController`. If the credential is already in use, the login sheet opens a conflict dialog. **Upload this device, then download** is only a stub (`resolveLinkConflictUploadFirst`). **Replace this device with the account** is not on the dialog. Cancel dismisses the dialog and does not sign the player into the other account. Legacy `users/local_user` is still not migrated.

## Acceptance Criteria

- [x] Anonymous Google or email sign-in calls `linkWithCredential` before creating a second user.
- [x] `credential-already-in-use` and `email-already-in-use` on that link return the conflict marker (`isAccountLinkConflict`).
- [ ] The conflict dialog offers **Upload this device, then download** (push local rows, then LWW pull) and **Replace this device with the account** (pull only, second confirm before local rows are removed).
- [x] Cancel closes the dialog. Neither copy is discarded by opening the dialog. `users/local_user` is not migrated.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-008` covers the conflict marker and the upload stub message. The dialog key `account-conflict-upload-first` is only built after a live Firebase link failure, so the suite does not tap it.
- [ ] **Integration (if needed):** Anonymous install with a local club, then sign-in to an email that already exists: Cancel leaves the anonymous session; Upload then Download round-trips the club.
- [x] **Keys:** `account-conflict-upload-first` on the upload action in `account_login_sheet.dart`. Replace-this-device has no key until the control exists (`Wireframe_Settings.md` does not name it yet).

## Dev notes

- `golf_diary_app/lib/services/account_auth_controller.dart` (`signInWithGoogle`, `signInWithEmail`, `resolveLinkConflictUploadFirst`, `isAccountLinkConflict`)
- `golf_diary_app/lib/widgets/account_login_sheet.dart` (`_showLinkConflictDialog`)
- Do not drop local SQLite on Cancel or on a failed link.
- Architecture §6 linking. No silent data loss (PRD SYNC-008).
