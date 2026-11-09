/// Seeded range drills from `docs/context/Range_Drills.md`.
class PracticeDrillSeed {
  const PracticeDrillSeed({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.steps,
    required this.recommendedClubs,
  });

  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final List<String> steps;
  final String recommendedClubs;
}

const practiceDrillSeeds = <PracticeDrillSeed>[
  PracticeDrillSeed(
    id: 'rng-drl-tempo-3to1',
    title: '3:1 Tour Tempo Rhythm',
    category: 'Full Swing & Tempo',
    shortDescription:
        'Build a smooth, repeatable transition by matching a 3-count backswing to a 1-count downswing through impact.',
    recommendedClubs: '7-Iron, Driver',
    steps: [
      'Select a mid-iron (7-iron) and tee the ball slightly or place it on a clean turf mat lie.',
      'Take two rehearsal swings while counting "One-Two-Three" from takeaway to the top of the backswing, and "Four" at impact.',
      'Address the ball, release tension in your grip (aim for 4 out of 10 pressure), and execute the swing counting "1-2-3" back and "4" through.',
      'Hold a balanced finish for 3 full seconds with your belt buckle facing the target and 90% of your weight on your lead foot.',
      'Log the 10-ball block carry distances and note whether your rhythm felt rushed at the transition.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-feet-together',
    title: 'Feet-Together Balance & Center Contact',
    category: 'Full Swing & Tempo',
    shortDescription:
        'Eliminate lateral swaying and improve centered clubface contact by swinging with your feet touching.',
    recommendedClubs: '8-Iron, 7-Iron',
    steps: [
      'Set up to the ball with a 7-iron or 8-iron, then bring your trail foot in until your shoes are touching side by side.',
      'Grip downhalf an inch on the handle to account for standing slightly taller.',
      'Make a controlled three-quarter backswing focusing on rotating your shoulders around your spine without losing balance.',
      'Swing through the ball at 75% speed and hold your finish without stepping out of position.',
      'After 5 consecutive solid strikes with feet together, widen to your normal stance for the remaining 5 balls while keeping the same centered rotation feel.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-pause-at-top',
    title: 'Pause-at-the-Top Transition',
    category: 'Full Swing & Tempo',
    shortDescription:
        'Cure an over-the-top rush from the top by pausing for a full one-second count before starting the downswing.',
    recommendedClubs: '6-Iron, 7-Iron, Hybrid',
    steps: [
      'Address the ball with a mid-iron and pick a specific downrange target.',
      'Turn to the top of your backswing and come to a complete, deliberate stop for a "One-one-thousand" count.',
      'Initiate the downswing from the ground up by shifting pressure into your lead heel while your back stays momentarily turned to the target.',
      'Brush the turf just after the ball and finish in full balance.',
      'Repeat for 10 balls, recording min/max/avg carry to see how clean sequencing preserves distance even with a pause.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-towel-behind',
    title: 'Towel Behind the Ball (Chunk Eradicator)',
    category: 'Ball Striking & Low Point',
    shortDescription:
        'Train ball-first, turf-second iron compression by placing a folded towel behind the ball to penalize early ground contact.',
    recommendedClubs: '9-Iron, 8-Iron, 7-Iron',
    steps: [
      'Lay a flat folded golf towel on the mat or grass approximately 4 to 5 inches (one clubhead width) directly behind the golf ball.',
      'Set your sternum and weight slightly favoring your lead side at address (55% lead / 45% trail).',
      'Make your normal iron swing with the goal of striking the ball cleanly without clipping or moving the towel.',
      'As contact improves, slide the towel closer (2 to 3 inches behind the ball) for the second half of your 10-ball block.',
      'Record your carry dispersion and note your low-point cue in Swing Notes.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-gate-strike',
    title: 'Two-Tee Clubface Gate (Sweet-Spot Strike)',
    category: 'Ball Striking & Low Point',
    shortDescription:
        'Center your strike location on the clubface by swinging through a narrow gate of two tees or foam objects just outside the toe and heel.',
    recommendedClubs: '7-Iron, 5-Iron, Driver',
    steps: [
      'Place a ball down and position two rubber tees (or headcovers/range balls) outside the toe and heel of your clubhead, leaving about half an inch of clearance on each side.',
      'Take a half-speed practice rehearsal ensuring the clubhead passes cleanly through the gate without touching either marker.',
      'Hit 10 balls at 85% cruise speed, focusing on maintaining posture and wrist angles through impact.',
      'After each shot, check where the ball contacted the face (heel, center, or toe) and reset the gate if clipped.',
      'Save your 10-ball carry numbers to establish a true centered-strike yardage baseline.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-split-hand',
    title: 'Split-Hand Release & Shaft Lean',
    category: 'Ball Striking & Low Point',
    shortDescription:
        'Feel proper forearm rotation and forward shaft lean through impact by separating your hands on the grip during rehearsals.',
    recommendedClubs: '8-Iron, 7-Iron',
    steps: [
      'Grip an 8-iron with your lead hand in its normal position and slide your trail hand down the shaft 3 to 4 inches (near the bottom of the grip).',
      'Make two slow waist-high to waist-high rehearsal swings, feeling the clubhead stay outside your hands on the takeaway and the handle lead the clubhead at impact.',
      'Return your hands together into your normal grip and immediately hit a golf ball while replicating that forward-handle sensation.',
      'Alternate 1 split-hand rehearsal with 1 live shot for a 10-ball block.',
      'Note whether ball flight launched lower and more penetrating than usual.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-wedge-clock',
    title: 'Clock-System Distance Wedge Matrix (9:00 / 10:30)',
    category: 'Distance Wedges',
    shortDescription:
        'Dial in exact carry yardages for partial wedge swings using lead-arm clock positions (9:00 and 10:30) at a consistent tempo.',
    recommendedClubs: 'Pitching Wedge, Gap Wedge, Sand Wedge, Lob Wedge',
    steps: [
      'Narrow your stance slightly, set 60% of your weight on your lead foot, and grip down to a consistent marker on your wedge handle.',
      'Hit 5 balls swinging your lead arm back to 9:00 (parallel to the ground) and accelerating smoothly through to a matching chest-high finish.',
      'Hit 5 balls swinging your lead arm back to 10:30 (three-quarter shoulder turn) with the same rhythm.',
      'Watch where each ball lands (carry, not total roll) or read the launch monitor carry number.',
      'Save the drill session and record your 9:00 and 10:30 carry yardages in the club\'s Swing Notes for on-course reference.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-random-target-ladder',
    title: '10-Yard Distance Ladder',
    category: 'Distance Wedges',
    shortDescription:
        'Train feel and distance control by hitting consecutive shots that must each carry 10 yards farther than the previous ball.',
    recommendedClubs: 'Sand Wedge, Gap Wedge, Pitching Wedge',
    steps: [
      'Pick a starting carry distance (for example, 50 yards) with your wedge.',
      'Hit Ball 1 to carry 50 yards, Ball 2 to 60 yards, Ball 3 to 70 yards, Ball 4 to 80 yards, and Ball 5 to 90 yards.',
      'For Balls 6 through 10, work back down the ladder from 90 yards to 50 yards in 10-yard increments.',
      'Control the distance by adjusting backswing length and grip position while keeping acceleration constant.',
      'Log the session min/max/avg and note which yardage rung was hardest to hit on the number.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-alignment-stick-startline',
    title: 'Start-Line Window Drill',
    category: 'Shot Shaping & Start Line',
    shortDescription:
        'Train clubface control at impact by starting the ball consistently through a narrow visual window downrange.',
    recommendedClubs: '7-Iron, 6-Iron, Hybrid, Driver',
    steps: [
      'Place an alignment stick on the ground pointing at your target line, or pick two tight intermediate markers 10 feet in front of your tee/mat creating a narrow window.',
      'Aim your clubface squarely through the center of the window before setting your feet parallel to the target line.',
      'Hit 10 balls with one primary focus: the ball must launch inside the start-line window during the first 30 yards of flight.',
      'Count how many out of 10 balls started on your intended line (aim for at least 7/10).',
      'Record the count in your session notes alongside your distance numbers.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-nine-flight-windows',
    title: 'Draw / Straight / Fade Trajectory Control',
    category: 'Shot Shaping & Start Line',
    shortDescription:
        'Develop face-to-path awareness and wind control by intentionally shaping draws, straight shots, and fades.',
    recommendedClubs: '7-Iron, 6-Iron',
    steps: [
      'Pick a clear flag or target downrange as your center line.',
      'Balls 1–3 (Draw): Aim your clubface slightly right of the target (for a right-handed golfer), align your stance slightly right of the face, and swing along your foot line so the ball curves back to the flag.',
      'Balls 4–6 (Straight): Square both your clubface and stance to the target and hit three neutral, stock shots.',
      'Balls 7–9 (Fade): Aim your clubface slightly left of the target, align your stance open (left of the face), and hold the face stable through impact so the ball fades gently to the flag.',
      'Ball 10 (Pressure Stock Shot): Pick your go-to on-course shape and execute one committed swing with full pre-shot routine.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-driver-fairway-corridor',
    title: 'Simulated Fairway Corridor (10-Ball Challenge)',
    category: 'Driver & Tee Box',
    shortDescription:
        'Simulate real on-course tee pressure by stepping back behind the ball before every drive and aiming into a defined 30-yard fairway corridor.',
    recommendedClubs: 'Driver, 3-Wood',
    steps: [
      'Define a left boundary and a right boundary on the range (two flags, trees, or simulator fairway edges) representing a 30-yard-wide fairway.',
      'Before every single ball, step completely behind the tee, visualize your shot shape, and pick a specific intermediate spot 3 feet in front of the ball.',
      'Step in, set the ball opposite your lead heel, tilt your spine slightly away from the target, and make a committed, balanced swing.',
      'Score yourself out of 10 fairways hit in regulation.',
      'Log the 10-ball min/max/avg driver distance and record your fairways-hit score (e.g., "8/10 fairways") in Swing Notes.',
    ],
  ),
  PracticeDrillSeed(
    id: 'rng-drl-simulated-3hole-loop',
    title: 'Simulated 3-Hole Range Loop (Club-Switch Routine)',
    category: 'Pressure & Course Simulation',
    shortDescription:
        'Break out of block-practice comfort by switching clubs on every swing to play three imaginary holes (Par 4, Par 3, Par 5).',
    recommendedClubs: 'Driver, Fairway Wood/Hybrid, Mid-Iron, Wedge',
    steps: [
      'Lay out a Driver, a Hybrid or 5-Wood, a 7-Iron, and a Pitching or Sand Wedge next to your bay.',
      '**Hole 1 (Par 4):** Hit 1 Driver tee shot, then switch immediately to 7-Iron for your approach shot (Balls 1–2).',
      '**Hole 2 (Par 3):** Switch to your mid-iron or hybrid and hit 1 tee shot to a specific flag; follow with a partial wedge pitch as if scrambling (Balls 3–4).',
      '**Hole 3 (Par 5):** Hit 1 Driver, 1 Fairway Wood/Hybrid layup, and 1 Scoring Wedge approach (Balls 5–7).',
      'Finish the block with 3 stock swings using the primary club you are logging for the session (Balls 8–10) and save its distance aggregates.',
    ],
  ),
];
