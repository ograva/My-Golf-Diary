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

A cloud copy is optional. The diary already works on the phone. If you connect Firebase later, **On Course** can upload what you have logged. Until you sign in, that copy is stored under the name `local_user`.

To run the app’s checks:

```bash
cd golf_diary_app
flutter test
```
