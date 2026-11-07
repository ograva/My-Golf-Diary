/// The build currently published at this PWA's origin.
class PwaPublishedBuild {
  const PwaPublishedBuild({required this.buildId, this.version = ''});

  final String buildId;
  final String version;
}
