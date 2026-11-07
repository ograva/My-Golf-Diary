# My Golf Diary

This folder is the My Golf Diary app: a pocket record of your clubs, your rounds, and your range sessions.

Use it when you want a yardage you trust, a score that matches the hole you just played, or a note from a practice block. What you enter stays on the phone. You can play a full round with no account and no signal.

Four tabs run along the bottom. The app follows your phone’s light or dark setting.

## My Bag

Your clubs, sorted into woods, hybrids, irons, wedges, and the putter. The bag opens with a starter set and a sample average for each club: driver, fairway woods, a hybrid, a couple of irons, a pitching wedge, and a putter.

- Tap a category to see only those clubs.
- Each club shows its shortest, usual, and longest yardage.
- Tap a club, rewrite the swing note, and tap **Save notes**.

A range session updates those yardages.

## On Course

The screen to keep open while you play.

1. Check the hole number and set the par.
2. Choose the club and the lie: tee, fairway, rough, bunker, green, or penalty.
3. Walk to the ball and tap **Record shot at ball**. Allow location when the phone asks. The shot joins the list for that hole, with how far it traveled from the previous one.
4. If the hole needs it, tap **Penalty +1**, **Penalty +2**, **Mulligan**, or **Concede**.
5. Tap **Finish hole** for the next tee. On the 18th, the button reads **Finish round**.

The hole score and the round total stay on this screen.

## Scorecard

The card for the round you are playing, and recent rounds you can open again.

- Read the front nine, the back nine, and the total against par.
- Tap a hole to change par, strokes, penalties, mulligans, or a concede.
- Tap **Start new round** for a fresh card. Older rounds stay in the list.

## Range

Log one club at a time.

1. Choose the club. The putter stays in **My Bag**; range drills are for the other clubs.
2. Tap **Hit** once per ball. If you leave the counter at zero, the save treats the block as ten balls.
3. Enter the shortest, average, and longest shot in yards. If you only know the average, type that and leave the others blank.
4. Add a tempo note if you want **My Bag** to remember it.
5. Tap **Save drill**. That club’s average in **My Bag** updates.

## Run it

From this folder:

```bash
flutter pub get
flutter run
```

Choose a phone or an emulator when Flutter asks. Allow location if you want shot distances.

### Browser / PWA storage

The web build keeps the diary in the browser (SQLite over WASM, persisted in IndexedDB). Data survives a refresh in that browser. A different browser, cleared site data, or the Android APK has its own separate diary.

A published PWA checks `app_build.json` when it opens and while it stays open. When that file names a newer build, Golf Diary asks before it reloads. Saved rounds stay on the device. Use the release script so the compiled build id and `app_build.json` match:

```bash
dart run sqflite_common_ffi_web:setup
flutter run -d chrome
# Release PWA (domain root). GitHub Pages uses --base-href /My-Golf-Diary/
./tool/build_web.sh --base-href /
```

```bash
flutter test
```

That runs the checks for scores, the bag, the on-course screen, the scorecard, and the range screen.
