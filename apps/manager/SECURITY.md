# TBN Manager — Security Foundation

## Τι είναι ενεργό ήδη στη v0.7.0

1. Τα πλήρη στοιχεία των μελών δεν γράφονται πλέον στο
   `SharedPreferences`.
2. Τα στοιχεία μελών αποθηκεύονται με `flutter_secure_storage`.
   Στο iOS αυτό χρησιμοποιεί το Keychain.
3. Πριν ανοίξει η εφαρμογή ζητείται τοπικό authentication
   (Face ID / Touch ID / device passcode, όπου υποστηρίζεται).
4. Υπάρχει migration από παλιότερη τοπική αποθήκευση:
   αν βρεθούν παλιά member records, μεταφέρονται μία φορά
   στο secure storage.
5. Υπάρχει αρχείο `firebase/firestore.rules` με deny-by-default
   λογική και role-based access ως βάση για το cloud στάδιο.

## Τι ΔΕΝ είναι ακόμη production security

Το υπάρχον Log in / Sign up εξακολουθεί να είναι UI prototype.
Δεν επιβεβαιώνει πραγματικό server-side λογαριασμό.

Για πραγματική χρήση από 7 χρήστες χρειάζεται Firebase project
και ενεργοποίηση:

- Firebase Authentication
- Cloud Firestore
- Cloud Storage
- Firestore Security Rules
- server-side roles / custom claims ή role documents
- email verification
- password reset μέσω Firebase

## Firebase setup

Από τον φάκελο του project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Στη συνέχεια:

```bash
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add firebase_storage
```

Στο Firebase Console:

1. Authentication → Sign-in method → Email/Password → Enable
2. Firestore Database → Create database
3. ΜΗΝ αφήσεις production δεδομένα με ανοιχτά test rules
4. Πέρασε/προσάρμοσε το `firebase/firestore.rules`
5. Δημιούργησε user documents με role:
   - admin
   - bandMember
   - bookingManager
   - merchManager
   - accountant

## Πολιτική ευαίσθητων δεδομένων

Τα παρακάτω θεωρούνται sensitive:
- ΑΦΜ
- ΑΜΚΑ
- Αριθμός ταυτότητας
- Διαβατήριο
- IBAN
- Διεύθυνση
- στοιχεία γονέων
- ημερομηνία/τόπος γέννησης

Δεν πρέπει να γράφονται σε debug logs, notifications ή
μη κρυπτογραφημένα exports.
