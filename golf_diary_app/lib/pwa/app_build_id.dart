/// Build id compiled into a release web build by `tool/build_web.sh`.
///
/// Debug and test runs leave this as `dev`. A published `app_build.json`
/// carries the same id as the build that produced it.
const String appBuildId = String.fromEnvironment(
  'APP_BUILD_ID',
  defaultValue: 'dev',
);
