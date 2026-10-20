# TBN Manager v0.6.0

Πρώτη σταθεροποιημένη έκδοση της εφαρμογής.

## Τι αλλάζει στην v0.6.0

- **Local persistence** με `shared_preferences`.
  - Tours
  - Lives
  - Products
  - Customers
  - Orders
  - Calendar events
  - Members
  - Streaming income
  - General expenses
  - Rent people / payments
  - Audit log
  - Notifications
  - Dark / Cream theme

Οι καταχωρήσεις πλέον δεν χάνονται απλώς επειδή έκλεισε η εφαρμογή.

- Διορθώθηκε το lint warning στο Excel export των Members.
- Το Excel export συνεχίζει να χρησιμοποιεί το iOS Share Sheet.
- Η έκδοση παραμένει local-first. Firebase / multi-user sync δεν είναι ακόμη ενεργό.
- Το Login / Sign Up είναι UI prototype μέχρι να συνδεθεί Firebase Authentication.

## Σημαντικό

Αυτή η έκδοση είναι η βάση για το επόμενο στάδιο:
- Firebase Authentication
- Firestore sync
- Roles / permissions
- Push notifications
- Google Maps / route distances
- Bandcamp sync

## Run

```bash
flutter create .
flutter pub get
flutter analyze
flutter run
```


## v0.6.1 — Rent tracking
- Το μηνιαίο κόστος ενοικίου είναι ρυθμιζόμενο από Settings.
- Default μηνιαίο ενοίκιο: **350 €**.
- Η σελίδα Ενοίκιο δείχνει:
  - πόσοι πλήρωσαν,
  - πόσοι χρωστάνε,
  - συνολικό ποσό που έχει πληρωθεί,
  - υπόλοιπο ποσό που αναμένεται μέχρι να καλυφθεί το ενοίκιο.
- Αν οι καταχωρημένες πληρωμές ξεπερνούν το μηνιαίο κόστος, εμφανίζεται ένδειξη υπέρβασης.


## v0.6.2 — Rent corrections & debt analysis
- Κάθε πληρωμή ενοικίου είναι πλέον επεξεργάσιμη.
- Μπορείς να αλλάξεις:
  - άτομο,
  - ποσό,
  - ημερομηνία πληρωμής,
  - τρόπο πληρωμής,
  - μήνα που αφορά.
- Νέα ετήσια ανάλυση οφειλών ανά άτομο.
- Η ανάλυση δείχνει από Ιανουάριο μέχρι τον τρέχοντα μήνα:
  - πόσο πλήρωσε το άτομο κάθε μήνα,
  - πόσο χρωστάει για κάθε μήνα,
  - συνολική οφειλή από την αρχή του έτους.
- Το μηνιαίο μερίδιο υπολογίζεται αυτόματα ως:
  μηνιαίο ενοίκιο / 11 άτομα.


## v0.6.3
- Settings: καταχώρηση συνολικού ποσού εσόδων από streaming platforms.
- Finance: χρησιμοποιεί το συνολικό streaming ποσό από τα Settings.
- Home: εμφανίζει το υπόλοιπο ενοικίου του τρέχοντος μήνα.
- Live Manager: κάθε Live ανοίγει πλέον σε δική του σελίδα.
- Live Detail editing:
  - Venue / Πόλη / Χώρα
  - Ημερομηνία
  - Status
  - Tour
  - Main Act / Support
  - Contact Person / Ηχολήπτης
  - Door Deal / Fix / Merch
  - Αμοιβή ηχολήπτη / τεχνικού / support bands
  - Presale / Door tickets
  - General Info
- Οι αλλαγές Live αποθηκεύονται τοπικά και καταγράφονται στο Audit Log.


## v0.6.3.1 Fix
- Προστέθηκε η ελλιπής `_editStreamingIncome()` method στα Settings.


## v0.7.0 — Security Foundation
- Sensitive Member data → secure storage / iOS Keychain.
- Local device authentication before entering the app.
- Face ID usage description added to iOS.
- Legacy member data migration from SharedPreferences.
- Firestore rules scaffold with deny-by-default + roles.
- See `SECURITY.md` before putting real personal data in the app.

Important: Firebase Authentication is not active yet because a Firebase
project must first be created/configured for this specific app.


## v0.8.0 — Web build (Cloudflare Pages)
- Χωρίς `dart:io`: οι εικόνες προϊόντων αποθηκεύονται ως data-URI (μικρές, 480px max).
  Παλιές τοπικές διαδρομές εικόνων από iOS v0.7.x δεν εμφανίζονται (fallback εικονίδιο).
- Excel export: download στον browser (web) / share sheet (iOS).
- Face ID lock παραλείπεται στο web (η προστασία θα γίνει με Cloudflare Access).
- Deploy: `./scripts/deploy_cloudflare.sh tbn-manager`
- Τα δεδομένα στο web είναι ακόμη **τοπικά στον browser** (κάθε χρήστης βλέπει τα δικά του).
  Επόμενο βήμα: Workers + D1 για κοινά δεδομένα, Cloudflare Access για login.


## v0.9.0 — UI/UX overhaul
- Νέο design system: Inter font (υποστηρίζει ελληνικά), νέα παλέτα dark/cream,
  ενιαία components (κάρτες, κουμπιά, πεδία, chips, sheets, navigation).
- Responsive: κινητό = κάτω μπάρα, desktop = πλαϊνό μενού, κεντραρισμένο περιεχόμενο.
- Home: χαιρετισμός, κάρτα «Επόμενο live» με αντίστροφη μέτρηση, KPI με πραγματικά
  δεδομένα (οφειλές ενοικίου, εκκρεμείς παραγγελίες κλπ — δεν είναι πια σταθερές τιμές).
- Menu: ομαδοποιημένο σε ενότητες. Live: αναζήτηση, date badges, status pills.
- Native-like μεταβάσεις σελίδων, mouse drag-scroll, ασφαλείς περιοχές (notch) στο κινητό.
- Web: `scripts/patch_web.py` (viewport-fit, theme-color, PWA manifest, εικονίδια TBN).

## v0.10.0 — Redesign όλων των οθονών
- Inter ενσωματωμένο στην εφαρμογή (assets/fonts, λατινικά + ελληνικά, βάρη 400-700). Χωρίς google_fonts.
- Tours, Merch, Ημερολόγιο, Οικονομικά, Ενοίκιο, Μέλη, Notifications: ενιαίο στυλ
  (κάρτες, status pills, date badges, empty states, κουμπιά δράσης στην κεφαλίδα).

## v0.11.0 — Branding
- Λογότυπο The Bonnie Nettles (assets/images/tbn_logo.png) στην οθόνη login, στο Home και στο πλαϊνό μενού.
- Νέα, πιο σοβαρή οθόνη login: μεγάλο logo, λιτά tabs, διακριτική έκδοση κάτω (lib/core/app_info.dart).
- Εικονίδια web/PWA από το νέο logo.
- Σε κάθε νέα έκδοση: ενημέρωσε lib/core/app_info.dart μαζί με το pubspec.yaml.

## v0.12.0 — Home & Live
- Home: πλαίσιο «Νέα» (επόμενο επιβεβαιωμένο live + επόμενη πρόβα) και κάρτα «Υπόλοιπο ταμείου».
- Live: κάθετη λίστα κατηγοριών αριστερά (σε στενή οθόνη γίνεται chips), banner ενότητας στη σελίδα live.
- Διαγραφή live και ενημέρωση ταμείου μόνο για admin (προσωρινά: διακόπτης στα Settings — η πραγματική επιβολή θα γίνει server-side).

## v0.13.0 — Χώρα/Πόλη & διαδρομές
- Νέο Live (Live, Tours, λεπτομέρειες): dropdown πρώτα Χώρα, μετά Πόλη (Ευρώπη + UK), αναζήτηση ελληνικά/αγγλικά, online fallback (Open-Meteo) για πόλεις που λείπουν.
- Απόσταση = πραγματική οδική διαδρομή από το προηγούμενο live στο επόμενο (OSRM), όχι από την αφετηρία. Cache στη συσκευή· χωρίς δίκτυο δείχνει «~» προσέγγιση.
- Ενδεικτικό κόστος: καύσιμο (diesel, L/100km από Settings) και διόδια (εκτίμηση ανά χώρα + βινιέτες). Εικονίδια: route / πρατήριο / διόδια / χρόνος. Σύνολο ανά tour.
- Preview link (Messenger κ.λπ.): 1200×630 og-image, νέο logo 2000×1000.
- Νέο dependency: http. Dataset: assets/data/places.json (scripts/tools/build_places.js).

## v0.14.0 — Tooltips, βαν, διόδια
- Hover/πάτημα σε km, καύσιμο, διόδια, χρόνο: σύντομη περιγραφή.
- Settings → «Βαν & καύσιμο»: λίστα 9θέσιων diesel βαν (ενσωματωμένη, WLTP + 15% για φορτίο) που ορίζει την κατανάλωση.
- Διόδια: ρεαλιστικότερο €/km για Ελλάδα και δυνατότητα χειροκίνητου ποσού ανά διαδρομή (πάτημα στα διόδια).

## v0.14.1 — Βαν ανά tour
- Κάθε tour έχει δικό του βαν/κατανάλωση (κάρτα tour → γραμμή βαν). Τα νέα tours παίρνουν την προεπιλογή από Settings. Η τιμή diesel παραμένει κοινή.

## v0.15.0 — Ένα live, παντού
- Τα lives εμφανίζονται και στο Ημερολόγιο (ίδια καταχώρηση — πάτημα ανοίγει τη σελίδα του live). Κάθε αλλαγή/διαγραφή ανανεώνει όλες τις σελίδες (AppStore.dataVersion).
- Live: πρώτα τα επερχόμενα (το πιο κοντινό πρώτο), μετά τα περασμένα.
- Πιο ευδιάκριτη αλλαγή ημερομηνίας στη σελίδα live.
