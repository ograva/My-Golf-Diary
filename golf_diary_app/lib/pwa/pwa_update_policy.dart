/// Whether the running PWA should tell the golfer a published build is waiting.
bool shouldOfferPwaUpdate({
  required String runningBuildId,
  required String? publishedBuildId,
  String? dismissedBuildId,
}) {
  final published = publishedBuildId?.trim();
  if (published == null || published.isEmpty) return false;
  if (published == runningBuildId.trim()) return false;
  if (dismissedBuildId != null && published == dismissedBuildId.trim()) {
    return false;
  }
  return true;
}
