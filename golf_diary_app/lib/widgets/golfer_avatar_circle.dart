import 'package:flutter/material.dart';

import '../models/golfer_avatar.dart';
import '../models/golfer_profile.dart';
import '../services/account_session.dart';
import '../services/golfer_profile_store.dart';

/// What the avatar slot renders, in precedence order.
enum GolferAvatarSource { accountPhoto, illustrated, initials, genericIcon }

/// Signed-in Google photo → illustrated golfer → initials → generic icon.
GolferAvatarSource resolveGolferAvatarSource({
  required AccountSession session,
  required GolferProfile profile,
}) {
  final photo = session.photoUrl;
  if (session.isDurableAccount && photo != null && photo.isNotEmpty) {
    return GolferAvatarSource.accountPhoto;
  }
  if (resolveGolferAvatar(profile) != null) {
    return GolferAvatarSource.illustrated;
  }
  if (session.isDurableAccount) return GolferAvatarSource.initials;
  return GolferAvatarSource.genericIcon;
}

/// The golfer's avatar wherever the app shows "you" (SYNC-005 + MGDV avatars).
class GolferAvatarCircle extends StatelessWidget {
  const GolferAvatarCircle({
    super.key,
    required this.session,
    this.profile,
    this.radius = 20,
  });

  final AccountSession session;

  /// Falls back to [GolferProfileScope] when null.
  final GolferProfile? profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = profile ??
        GolferProfileScope.maybeOf(context)?.profile ??
        const GolferProfile();
    final source =
        resolveGolferAvatarSource(session: session, profile: resolved);
    switch (source) {
      case GolferAvatarSource.accountPhoto:
        return CircleAvatar(
          key: const ValueKey('golfer-avatar-photo'),
          radius: radius,
          backgroundImage: NetworkImage(session.photoUrl!),
        );
      case GolferAvatarSource.illustrated:
        final avatar = resolveGolferAvatar(resolved)!;
        return CircleAvatar(
          key: ValueKey('golfer-avatar-${avatar.id}'),
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage(avatar.assetPath),
        );
      case GolferAvatarSource.initials:
        return CircleAvatar(
          key: const ValueKey('golfer-avatar-initials'),
          radius: radius,
          child: Text(
            session.initials,
            style: TextStyle(fontSize: radius * 0.66),
          ),
        );
      case GolferAvatarSource.genericIcon:
        return CircleAvatar(
          key: const ValueKey('golfer-avatar-generic'),
          radius: radius,
          child: Icon(Icons.person_outline, size: radius),
        );
    }
  }
}
