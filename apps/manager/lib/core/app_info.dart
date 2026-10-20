/// Single source of truth for the version shown in the app.
/// Keep in sync with `version:` in pubspec.yaml.
const String kAppVersion = '0.15.1';
const String kAppBuild = '43';
String get appVersionLabel => 'v$kAppVersion ($kAppBuild)';
