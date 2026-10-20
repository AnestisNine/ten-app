import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appTagline.
  ///
  /// In el, this message translates to:
  /// **'TOURING  ·  MERCH  ·  FINANCE'**
  String get appTagline;

  /// No description provided for @email.
  ///
  /// In el, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In el, this message translates to:
  /// **'Κωδικός'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In el, this message translates to:
  /// **'Σύνδεση'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In el, this message translates to:
  /// **'Αποσύνδεση'**
  String get signOut;

  /// No description provided for @forgotPassword.
  ///
  /// In el, this message translates to:
  /// **'Ξέχασα τον κωδικό'**
  String get forgotPassword;

  /// No description provided for @resetSent.
  ///
  /// In el, this message translates to:
  /// **'Αν υπάρχει λογαριασμός με αυτό το email, στάλθηκε σύνδεσμος επαναφοράς.'**
  String get resetSent;

  /// No description provided for @enterEmailFirst.
  ///
  /// In el, this message translates to:
  /// **'Γράψε πρώτα το email σου.'**
  String get enterEmailFirst;

  /// No description provided for @invalidCredentials.
  ///
  /// In el, this message translates to:
  /// **'Λάθος email ή κωδικός.'**
  String get invalidCredentials;

  /// No description provided for @tooManyAttempts.
  ///
  /// In el, this message translates to:
  /// **'Πολλές προσπάθειες. Δοκίμασε ξανά σε λίγο.'**
  String get tooManyAttempts;

  /// No description provided for @inviteOnly.
  ///
  /// In el, this message translates to:
  /// **'Πρόσβαση μόνο με πρόσκληση από τον διαχειριστή.'**
  String get inviteOnly;

  /// No description provided for @server.
  ///
  /// In el, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @serverHint.
  ///
  /// In el, this message translates to:
  /// **'π.χ. https://app.thebonnienettles.com'**
  String get serverHint;

  /// No description provided for @offline.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχει σύνδεση με τον server.'**
  String get offline;

  /// No description provided for @retry.
  ///
  /// In el, this message translates to:
  /// **'Ξανά'**
  String get retry;

  /// No description provided for @twoFactor.
  ///
  /// In el, this message translates to:
  /// **'Έλεγχος δύο βημάτων (2FA)'**
  String get twoFactor;

  /// No description provided for @twoFactorOn.
  ///
  /// In el, this message translates to:
  /// **'Ενεργός'**
  String get twoFactorOn;

  /// No description provided for @twoFactorOff.
  ///
  /// In el, this message translates to:
  /// **'Ανενεργός'**
  String get twoFactorOff;

  /// No description provided for @twoFactorCodeTitle.
  ///
  /// In el, this message translates to:
  /// **'Κωδικός επαλήθευσης'**
  String get twoFactorCodeTitle;

  /// No description provided for @twoFactorCodeHelp.
  ///
  /// In el, this message translates to:
  /// **'Γράψε τον 6ψήφιο κωδικό από την εφαρμογή authenticator.'**
  String get twoFactorCodeHelp;

  /// No description provided for @twoFactorCode.
  ///
  /// In el, this message translates to:
  /// **'Κωδικός 6 ψηφίων'**
  String get twoFactorCode;

  /// No description provided for @useBackupCode.
  ///
  /// In el, this message translates to:
  /// **'Χρήση εφεδρικού κωδικού'**
  String get useBackupCode;

  /// No description provided for @backupCode.
  ///
  /// In el, this message translates to:
  /// **'Εφεδρικός κωδικός'**
  String get backupCode;

  /// No description provided for @trustDevice.
  ///
  /// In el, this message translates to:
  /// **'Να μη ζητηθεί ξανά σε αυτή τη συσκευή για 30 μέρες'**
  String get trustDevice;

  /// No description provided for @verify.
  ///
  /// In el, this message translates to:
  /// **'Επαλήθευση'**
  String get verify;

  /// No description provided for @wrongCode.
  ///
  /// In el, this message translates to:
  /// **'Λάθος κωδικός.'**
  String get wrongCode;

  /// No description provided for @setup2faTitle.
  ///
  /// In el, this message translates to:
  /// **'Ενεργοποίηση 2FA'**
  String get setup2faTitle;

  /// No description provided for @setup2faRequired.
  ///
  /// In el, this message translates to:
  /// **'Ο ρόλος σου απαιτεί έλεγχο δύο βημάτων. Ενεργοποίησέ τον για να συνεχίσεις.'**
  String get setup2faRequired;

  /// No description provided for @setup2faStep1.
  ///
  /// In el, this message translates to:
  /// **'1. Επιβεβαίωσε τον κωδικό σου.'**
  String get setup2faStep1;

  /// No description provided for @setup2faStep2.
  ///
  /// In el, this message translates to:
  /// **'2. Σκάναρε το QR με Google Authenticator, 1Password, Authy κ.λπ. (ή γράψε το κλειδί).'**
  String get setup2faStep2;

  /// No description provided for @setup2faStep3.
  ///
  /// In el, this message translates to:
  /// **'3. Γράψε τον κωδικό που εμφανίζεται.'**
  String get setup2faStep3;

  /// No description provided for @continueLabel.
  ///
  /// In el, this message translates to:
  /// **'Συνέχεια'**
  String get continueLabel;

  /// No description provided for @backupCodesTitle.
  ///
  /// In el, this message translates to:
  /// **'Εφεδρικοί κωδικοί'**
  String get backupCodesTitle;

  /// No description provided for @backupCodesHelp.
  ///
  /// In el, this message translates to:
  /// **'Φύλαξέ τους κάπου ασφαλές. Ο καθένας δουλεύει μία φορά αν χάσεις το κινητό σου.'**
  String get backupCodesHelp;

  /// No description provided for @copy.
  ///
  /// In el, this message translates to:
  /// **'Αντιγραφή'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In el, this message translates to:
  /// **'Αντιγράφηκε'**
  String get copied;

  /// No description provided for @done.
  ///
  /// In el, this message translates to:
  /// **'Τέλος'**
  String get done;

  /// No description provided for @settings.
  ///
  /// In el, this message translates to:
  /// **'Ρυθμίσεις'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In el, this message translates to:
  /// **'Γλώσσα'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In el, this message translates to:
  /// **'Εμφάνιση'**
  String get appearance;

  /// No description provided for @navHome.
  ///
  /// In el, this message translates to:
  /// **'Αρχική'**
  String get navHome;

  /// No description provided for @navLive.
  ///
  /// In el, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navTours.
  ///
  /// In el, this message translates to:
  /// **'Tours'**
  String get navTours;

  /// No description provided for @navMerch.
  ///
  /// In el, this message translates to:
  /// **'Merch'**
  String get navMerch;

  /// No description provided for @navCalendar.
  ///
  /// In el, this message translates to:
  /// **'Ημερολόγιο'**
  String get navCalendar;

  /// No description provided for @navMenu.
  ///
  /// In el, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @users.
  ///
  /// In el, this message translates to:
  /// **'Χρήστες'**
  String get users;

  /// No description provided for @usersSubtitle.
  ///
  /// In el, this message translates to:
  /// **'Προσκλήσεις, ρόλοι, πρόσβαση'**
  String get usersSubtitle;

  /// No description provided for @inviteUser.
  ///
  /// In el, this message translates to:
  /// **'Πρόσκληση χρήστη'**
  String get inviteUser;

  /// No description provided for @name.
  ///
  /// In el, this message translates to:
  /// **'Όνομα'**
  String get name;

  /// No description provided for @roles.
  ///
  /// In el, this message translates to:
  /// **'Ρόλοι'**
  String get roles;

  /// No description provided for @sendInvite.
  ///
  /// In el, this message translates to:
  /// **'Αποστολή πρόσκλησης'**
  String get sendInvite;

  /// No description provided for @inviteSent.
  ///
  /// In el, this message translates to:
  /// **'Η πρόσκληση στάλθηκε στο {email}.'**
  String inviteSent(String email);

  /// No description provided for @pendingInvite.
  ///
  /// In el, this message translates to:
  /// **'Εκκρεμεί αποδοχή'**
  String get pendingInvite;

  /// No description provided for @resendInvite.
  ///
  /// In el, this message translates to:
  /// **'Νέα αποστολή πρόσκλησης'**
  String get resendInvite;

  /// No description provided for @deactivate.
  ///
  /// In el, this message translates to:
  /// **'Απενεργοποίηση'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In el, this message translates to:
  /// **'Ενεργοποίηση'**
  String get activate;

  /// No description provided for @inactive.
  ///
  /// In el, this message translates to:
  /// **'Ανενεργός'**
  String get inactive;

  /// No description provided for @signOutEverywhere.
  ///
  /// In el, this message translates to:
  /// **'Αποσύνδεση από όλες τις συσκευές'**
  String get signOutEverywhere;

  /// No description provided for @save.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In el, this message translates to:
  /// **'Ακύρωση'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
