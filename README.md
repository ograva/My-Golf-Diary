# My Golf Diary

My Golf Diary is a phone app for one clear record of your golf: how far you hit each club, what happened on each hole, and what you learned on the range.

You do not need an account. What you log stays on the phone, so a full round works with no signal. Four tabs sit along the bottom. Switch tabs when you change what you are doing.

The app follows your phone’s light or dark setting.

## What you can do

### My Bag

Look up a club before you pull it. The bag opens with a starter set: driver, fairway woods, a hybrid, a couple of irons, a pitching wedge, and a putter, each with a sample average. Clubs are grouped into woods, hybrids, irons, wedges, and the putter. Tap a club to read or rewrite its swing note, then tap **Save notes**. A range session updates the shortest, usual, and longest numbers for that club.

### On Course

Play the hole from one screen. You see the hole number, the par, and your running score. Choose the par, the club, and where the ball is lying: tee, fairway, rough, bunker, green, or penalty. When you are standing at the ball, tap **Record shot at ball**. The phone asks for location the first time. Each shot joins the list for that hole, with the distance from the shot before it.

On the same screen you can:

- add a one-stroke or two-stroke penalty
- mark a mulligan
- concede the hole
- tap **Finish hole** to move on, or **Finish round** on the 18th

### Scorecard

See the round as a card: eighteen holes, the front nine, the back nine, and the total against par. Tap a hole to correct the par, strokes, penalties, mulligans, or a concede. **Start new round** begins a fresh card and leaves earlier rounds in the list.

### Range

Practice one club at a time. Pick the club, tap **Hit** as you go through the pile, and write down the shortest, average, and longest ball of that block. Add a tempo note if you want it to stay with that club. **Save drill** stores the session and updates that club’s average in My Bag. Leaving the counter at zero saves the block as ten balls. If you only know the average, type that and leave the other two blank.

## A round, start to finish

1. Open **My Bag** and read the yardage and the note for the clubs you expect to hit.
2. On the first tee, open **On Course**. Set the par and the club, then record a shot each time you reach the ball.
3. Mark a penalty, a mulligan, or a concede before you leave the hole. Tap **Finish hole** on the way to the next tee.
4. After the round, open **Scorecard** and tap any hole that does not match what you remember.
5. Next time you are on the range, open **Range**, run a block for one club, and save it so My Bag stays current.

## Open the app

The project lives in [`golf_diary_app`](golf_diary_app/). With Flutter installed:

```bash
cd golf_diary_app
flutter pub get
flutter run
```

Allow location when the phone asks, if you want the distance between shots.

A cloud copy is optional. The diary already works with no signal. The cloud icon on each tab syncs with Firestore database `my-golf-diary` after you turn on **Anonymous** sign-in in the Firebase console and deploy [`firestore.rules`](firestore.rules):

```bash
firebase deploy --only firestore:my-golf-diary
```

The first sync signs in anonymously. Clubs, rounds, shots, and range sessions then download and upload under `users/{uid}/...`. A newer `updatedAtMs` wins. Deleting a club tells other devices to drop it. The web app stores the same SQLite diary in IndexedDB and uses this sync. Data written earlier under `users/local_user` is not moved.

## Browser / PWA storage

On the web build, the same SQLite diary runs inside the browser (WASM + IndexedDB). Clubs, notes, rounds, and range sessions stay on that browser and survive a refresh. Sync copies them to Firestore so another browser or the Android app signed into the same anonymous user can restore them. A new browser without that user starts its own diary until it syncs.

Before `flutter build web` or `flutter run -d chrome`, generate the web SQLite assets once (or after upgrading `sqflite_common_ffi_web`):

```bash
cd golf_diary_app
dart run sqflite_common_ffi_web:setup
```

To run the app’s checks:

```bash
cd golf_diary_app
flutter test
```
