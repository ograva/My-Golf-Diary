import 'practice_drill_seed.dart';

const kBeginnerFriendlyDrillIds = <String>{
  'rng-drl-feet-together',
  'rng-drl-tempo-3to1',
  'rng-drl-putt-gate-startline',
  'rng-drl-putt-lead-arm',
  'rng-drl-approach-wedge-nine',
};

bool isBeginnerFriendlyDrill(String drillId) =>
    kBeginnerFriendlyDrillIds.contains(drillId);

String practiceAreaForDrill(String drillId) {
  for (final seed in kPracticeDrillSeed) {
    if (seed.id == drillId) return seed.practiceArea;
  }
  return 'range_bay';
}

String practiceAreaLabel(String practiceArea) => switch (practiceArea) {
      'practice_green' => 'Practice green',
      _ => 'Range bay',
    };