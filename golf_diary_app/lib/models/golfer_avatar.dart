import 'golfer_profile.dart';

/// Bundled illustrated golfer portraits (gender × tier, plus amateur alternates).
enum GolferAvatar {
  femaleBeginner('female_beginner', 'Female beginner'),
  maleBeginner('male_beginner', 'Male beginner'),
  femaleAmateur('female_amateur', 'Female amateur'),
  maleAmateur('male_amateur', 'Male amateur'),
  femaleAmateurAlt('female_amateur_alt', 'Female amateur (alt)'),
  maleAmateurAlt('male_amateur_alt', 'Male amateur (alt)'),
  femaleSeasoned('female_seasoned', 'Female seasoned'),
  maleSeasoned('male_seasoned', 'Male seasoned');

  const GolferAvatar(this.id, this.label);

  /// Persisted in [GolferProfile.avatarChoice]; also the asset file stem.
  final String id;
  final String label;

  String get assetPath => 'assets/avatars/$id.png';

  static GolferAvatar? fromId(String id) {
    for (final avatar in values) {
      if (avatar.id == id) return avatar;
    }
    return null;
  }
}

/// Avatar art buckets; legacy/loose tier names collapse onto these.
enum GolferAvatarTier { beginner, amateur, seasoned }

GolferAvatarTier? golferAvatarTier(String skillTier) {
  return switch (skillTier.trim().toLowerCase()) {
    GolferSkillTier.beginner => GolferAvatarTier.beginner,
    GolferSkillTier.amateur => GolferAvatarTier.amateur,
    GolferSkillTier.seasonedPro ||
    'seasoned' ||
    'pro' ||
    'seasoned pro' =>
      GolferAvatarTier.seasoned,
    _ => null,
  };
}

/// Default portrait for female/male + tier; null when either is unset or
/// gender is non-binary / prefer-not-to-say (those golfers pick explicitly).
GolferAvatar? defaultGolferAvatar({
  required String gender,
  required String skillTier,
}) {
  final tier = golferAvatarTier(skillTier);
  if (tier == null) return null;
  return switch ((gender, tier)) {
    (GolferGender.female, GolferAvatarTier.beginner) =>
      GolferAvatar.femaleBeginner,
    (GolferGender.female, GolferAvatarTier.amateur) =>
      GolferAvatar.femaleAmateur,
    (GolferGender.female, GolferAvatarTier.seasoned) =>
      GolferAvatar.femaleSeasoned,
    (GolferGender.male, GolferAvatarTier.beginner) => GolferAvatar.maleBeginner,
    (GolferGender.male, GolferAvatarTier.amateur) => GolferAvatar.maleAmateur,
    (GolferGender.male, GolferAvatarTier.seasoned) => GolferAvatar.maleSeasoned,
    _ => null,
  };
}

/// Explicit picker choice wins; empty / unknown choice falls back to default.
GolferAvatar? resolveGolferAvatar(GolferProfile profile) {
  return GolferAvatar.fromId(profile.avatarChoice) ??
      defaultGolferAvatar(
        gender: profile.gender,
        skillTier: profile.skillTier,
      );
}

/// Picker order: matching gender × tier options first, then the rest.
List<GolferAvatar> golferAvatarPickerOrder({
  required String gender,
  required String skillTier,
}) {
  final preferred = <GolferAvatar>[];
  final primary = defaultGolferAvatar(gender: gender, skillTier: skillTier);
  if (primary != null) {
    preferred.add(primary);
    if (primary == GolferAvatar.femaleAmateur) {
      preferred.add(GolferAvatar.femaleAmateurAlt);
    } else if (primary == GolferAvatar.maleAmateur) {
      preferred.add(GolferAvatar.maleAmateurAlt);
    }
  }
  return [
    ...preferred,
    ...GolferAvatar.values.where((a) => !preferred.contains(a)),
  ];
}
