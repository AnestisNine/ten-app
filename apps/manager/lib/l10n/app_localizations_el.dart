// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTagline => 'TOURING  ·  MERCH  ·  FINANCE';

  @override
  String get email => 'Email';

  @override
  String get password => 'Κωδικός';

  @override
  String get signIn => 'Σύνδεση';

  @override
  String get signOut => 'Αποσύνδεση';

  @override
  String get forgotPassword => 'Ξέχασα τον κωδικό';

  @override
  String get resetSent =>
      'Αν υπάρχει λογαριασμός με αυτό το email, στάλθηκε σύνδεσμος επαναφοράς.';

  @override
  String get enterEmailFirst => 'Γράψε πρώτα το email σου.';

  @override
  String get invalidCredentials => 'Λάθος email ή κωδικός.';

  @override
  String get tooManyAttempts => 'Πολλές προσπάθειες. Δοκίμασε ξανά σε λίγο.';

  @override
  String get inviteOnly => 'Πρόσβαση μόνο με πρόσκληση από τον διαχειριστή.';

  @override
  String get server => 'Server';

  @override
  String get serverHint => 'π.χ. https://app.thebonnienettles.com';

  @override
  String get offline => 'Δεν υπάρχει σύνδεση με τον server.';

  @override
  String get retry => 'Ξανά';

  @override
  String get twoFactor => 'Έλεγχος δύο βημάτων (2FA)';

  @override
  String get twoFactorOn => 'Ενεργός';

  @override
  String get twoFactorOff => 'Ανενεργός';

  @override
  String get twoFactorCodeTitle => 'Κωδικός επαλήθευσης';

  @override
  String get twoFactorCodeHelp =>
      'Γράψε τον 6ψήφιο κωδικό από την εφαρμογή authenticator.';

  @override
  String get twoFactorCode => 'Κωδικός 6 ψηφίων';

  @override
  String get useBackupCode => 'Χρήση εφεδρικού κωδικού';

  @override
  String get backupCode => 'Εφεδρικός κωδικός';

  @override
  String get trustDevice =>
      'Να μη ζητηθεί ξανά σε αυτή τη συσκευή για 30 μέρες';

  @override
  String get verify => 'Επαλήθευση';

  @override
  String get wrongCode => 'Λάθος κωδικός.';

  @override
  String get setup2faTitle => 'Ενεργοποίηση 2FA';

  @override
  String get setup2faRequired =>
      'Ο ρόλος σου απαιτεί έλεγχο δύο βημάτων. Ενεργοποίησέ τον για να συνεχίσεις.';

  @override
  String get setup2faStep1 => '1. Επιβεβαίωσε τον κωδικό σου.';

  @override
  String get setup2faStep2 =>
      '2. Σκάναρε το QR με Google Authenticator, 1Password, Authy κ.λπ. (ή γράψε το κλειδί).';

  @override
  String get setup2faStep3 => '3. Γράψε τον κωδικό που εμφανίζεται.';

  @override
  String get continueLabel => 'Συνέχεια';

  @override
  String get backupCodesTitle => 'Εφεδρικοί κωδικοί';

  @override
  String get backupCodesHelp =>
      'Φύλαξέ τους κάπου ασφαλές. Ο καθένας δουλεύει μία φορά αν χάσεις το κινητό σου.';

  @override
  String get copy => 'Αντιγραφή';

  @override
  String get copied => 'Αντιγράφηκε';

  @override
  String get done => 'Τέλος';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get language => 'Γλώσσα';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get navHome => 'Αρχική';

  @override
  String get navLive => 'Live';

  @override
  String get navTours => 'Tours';

  @override
  String get navMerch => 'Merch';

  @override
  String get navCalendar => 'Ημερολόγιο';

  @override
  String get navMenu => 'Menu';

  @override
  String get users => 'Χρήστες';

  @override
  String get usersSubtitle => 'Προσκλήσεις, ρόλοι, πρόσβαση';

  @override
  String get inviteUser => 'Πρόσκληση χρήστη';

  @override
  String get name => 'Όνομα';

  @override
  String get roles => 'Ρόλοι';

  @override
  String get sendInvite => 'Αποστολή πρόσκλησης';

  @override
  String inviteSent(String email) {
    return 'Η πρόσκληση στάλθηκε στο $email.';
  }

  @override
  String get pendingInvite => 'Εκκρεμεί αποδοχή';

  @override
  String get resendInvite => 'Νέα αποστολή πρόσκλησης';

  @override
  String get deactivate => 'Απενεργοποίηση';

  @override
  String get activate => 'Ενεργοποίηση';

  @override
  String get inactive => 'Ανενεργός';

  @override
  String get signOutEverywhere => 'Αποσύνδεση από όλες τις συσκευές';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get cancel => 'Ακύρωση';
}
