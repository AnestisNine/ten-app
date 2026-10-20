// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'TOURING  ·  MERCH  ·  FINANCE';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get resetSent =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get enterEmailFirst => 'Enter your email first.';

  @override
  String get invalidCredentials => 'Wrong email or password.';

  @override
  String get tooManyAttempts => 'Too many attempts. Try again shortly.';

  @override
  String get inviteOnly => 'Access by invitation from the administrator only.';

  @override
  String get server => 'Server';

  @override
  String get serverHint => 'e.g. https://app.thebonnienettles.com';

  @override
  String get offline => 'Cannot reach the server.';

  @override
  String get retry => 'Retry';

  @override
  String get twoFactor => 'Two-factor authentication (2FA)';

  @override
  String get twoFactorOn => 'Enabled';

  @override
  String get twoFactorOff => 'Disabled';

  @override
  String get twoFactorCodeTitle => 'Verification code';

  @override
  String get twoFactorCodeHelp =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get twoFactorCode => '6-digit code';

  @override
  String get useBackupCode => 'Use a backup code';

  @override
  String get backupCode => 'Backup code';

  @override
  String get trustDevice => 'Don\'t ask again on this device for 30 days';

  @override
  String get verify => 'Verify';

  @override
  String get wrongCode => 'Wrong code.';

  @override
  String get setup2faTitle => 'Enable 2FA';

  @override
  String get setup2faRequired =>
      'Your role requires two-factor authentication. Enable it to continue.';

  @override
  String get setup2faStep1 => '1. Confirm your password.';

  @override
  String get setup2faStep2 =>
      '2. Scan the QR code with Google Authenticator, 1Password, Authy etc. (or type the key).';

  @override
  String get setup2faStep3 => '3. Enter the code it shows.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get backupCodesTitle => 'Backup codes';

  @override
  String get backupCodesHelp =>
      'Keep them somewhere safe. Each works once if you lose your phone.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get done => 'Done';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get navHome => 'Home';

  @override
  String get navLive => 'Live';

  @override
  String get navTours => 'Tours';

  @override
  String get navMerch => 'Merch';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMenu => 'Menu';

  @override
  String get users => 'Users';

  @override
  String get usersSubtitle => 'Invitations, roles, access';

  @override
  String get inviteUser => 'Invite user';

  @override
  String get name => 'Name';

  @override
  String get roles => 'Roles';

  @override
  String get sendInvite => 'Send invitation';

  @override
  String inviteSent(String email) {
    return 'Invitation sent to $email.';
  }

  @override
  String get pendingInvite => 'Invitation pending';

  @override
  String get resendInvite => 'Resend invitation';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get activate => 'Activate';

  @override
  String get inactive => 'Inactive';

  @override
  String get signOutEverywhere => 'Sign out of all devices';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';
}
