# TBN Manager — Φάση 0: Audit & πρόταση αρχιτεκτονικής

Βάση: `TBN_Manager_v0_15_1_Web.zip` (pubspec `0.15.1+43`). ~10.900 γραμμές, 33 αρχεία Dart.

---

## 1. Τι υπάρχει (σύνοψη)

**Stack:** Flutter 3 / Dart (όχι React/TS). Ένας κώδικας για iOS και Web. Deploy ως static Flutter web σε Cloudflare Pages (`scripts/deploy_cloudflare.sh`).

| Θέμα | Υλοποίηση σήμερα |
|---|---|
| State | Ένα global static `AppStore` (`lib/data/app_store.dart`) με mutable λίστες + `ValueNotifier`. Κάθε αλλαγή → `dataVersion++` → rebuild όλου του shell. |
| Persistence | Όλα τα δεδομένα σε **ένα JSON blob** στο `SharedPreferences` (στο web = `localStorage` του browser). Μέλη σε `flutter_secure_storage`. |
| Backend / API | **Κανένα.** Μόνο εξωτερικά δωρεάν APIs: OSRM demo server (διαδρομές), Open-Meteo geocoding (πόλεις). |
| Auth | **Ψεύτικο.** Η φόρμα login δεν ελέγχει τίποτα· στο iOS ζητά Face ID, στο web περνάει απευθείας. «Admin» = διακόπτης στα Settings. |
| Ρόλοι | `AppRole` enum (admin, bandMember, bookingManager, merchManager, accountant) — δεν χρησιμοποιείται πουθενά στο UI. `firebase/firestore.rules` = scaffold, δεν είναι συνδεδεμένο. |
| i18n | Καμία. Strings hardcoded, μίγμα ελληνικών/αγγλικών. |
| Routing | `Navigator.push` + `IndexedStack` με 6 tabs· όχι URL routes (δεν γίνεται deep link / share link σε συγκεκριμένο live). |
| Design system | Καλό: `core/theme.dart`, `core/widgets.dart` (PageHeader, StatusPill, IconChip, κάρτες, sheets), Inter, dark/cream, responsive (rail ≥900px / bottom nav). **Αξίζει να κρατηθεί.** |
| Tests | 1 widget test, που κατά πάσα πιθανότητα αποτυγχάνει (ψάχνει `'TBN Manager'`, η οθόνη γράφει `'TBN MANAGER'`). Δεν μπόρεσα να το τρέξω: Flutter SDK δεν υπάρχει στο container. |
| Repo | Όχι git. Λείπουν `web/`, `ios/` (παράγονται στο deploy με `flutter create`). README σταματά στο header «v0.6.0», pubspec description λέει v0.12.0. |

## 2. Κατάσταση ανά οθόνη / module

Υπόμνημα: ✅ λειτουργεί τοπικά · 🟡 μισό · 🔲 placeholder/mock · ❌ λείπει

| Module (prompt) | Οθόνη(ες) | Κατάσταση | Σχόλιο |
|---|---|---|---|
| **Bookings — lives** | `live_manager_screen`, `live_detail_screen` | ✅ τοπικά | CRUD, αναζήτηση, κατηγορίες, status. Statuses: `proposal, negotiation, confirmed, completed, cancelled` (≠ ζητούμενα `inquiry→hold→offer→confirmed→played→settled/cancelled`). Λείπουν: ώρες (load-in/soundcheck/doors/set), deposit, deal types ως δομή, συμβόλαιο/rider upload, contacts ως οντότητες, day sheets, conflicts, διαθεσιμότητα μελών. |
| **Tours** | `tours_screen`, `core/routing.dart`, `route_widgets`, `vans` | 🟡 | Ομαδοποίηση lives, οδική απόσταση/χρόνος (OSRM), εκτίμηση καυσίμων & διοδίων, βαν ανά tour — **καλή, μοναδική δουλειά, κρατιέται**. Λείπουν: διαμονή, per diems, budget εκτίμηση vs πραγματικό. |
| **Ημερολόγιο** | `calendar_screen` | ✅ τοπικά | List/week/month, events + lives (ίδια εγγραφή). |
| **Merch — προϊόντα/stock** | `merch_screen` (tabs Stock/Orders/Products/Customers) | 🟡 | Προϊόν = ένα `int stock`, χωρίς variants, χωρίς τοποθεσίες, χωρίς ιστορικό κινήσεων. **Η παραγγελία δεν μειώνει το stock.** Low-stock όριο hardcoded (3 στο UI, «10» στα Settings ως κείμενο). Εικόνες ως base64 μέσα στο JSON. |
| **Merch — παραγγελίες** | `order_detail_screen` | 🟡 | Μία παραγγελία = **ένα προϊόν** (χωρίς line items). Statuses: `waitingContact, waitingRestock, sent, completed, cancelled`. Πηγή organic/Bandcamp (Bandcamp μόνο ως ετικέτα, χωρίς sync). Tracking number, μεταφορικός (BoxNow/ΕΛΤΑ/ACS/Γενική), κλήση/email πελάτη από το UI. |
| POS / restock / προμηθευτές / emails πελατών / αναφορές | — | ❌ | |
| **Οικονομικά** | `finance_screen` | 🟡 | Μία σελίδα συνόλων υπολογισμένων on the fly. Μόνο 2 κατηγορίες εξόδων (ηχογράφηση, ενοίκιο). Streaming έσοδα = **ένα χειροκίνητο σύνολο** στα Settings (η λίστα `streamingIncomes` αποθηκεύεται αλλά δεν χρησιμοποιείται). Cashbox = χειροκίνητος αριθμός. Λείπουν: ledger, εκκρεμότητες, budgets, splits, αποδείξεις, export λογιστή. |
| **Ενοίκιο** | `rent_screen` | ✅ τοπικά | Πλήρες για αυτό που κάνει: 11 άτομα, μερίδιο = ενοίκιο / άτομα, ανάλυση οφειλών ανά μήνα. Είναι στην ουσία ειδική περίπτωση «επαναλαμβανόμενου εξόδου με splits» → θα γενικευτεί στο module Οικονομικών χωρίς να χαθεί το UI. |
| **Μέλη** | `members_screen` | ✅ τοπικά | Πλήρη στοιχεία (ΑΦΜ, ΑΜΚΑ, διαβατήριο, IBAN, γονείς…) + export Excel «για επόμενο live». Χρειάζεται ειδική μεταχείριση (βλ. §4). |
| **CRM** | — | ❌ | Μόνο `contactPerson`/`soundEngineer` ως ελεύθερο κείμενο στο live. |
| **Social** | — | ❌ | |
| **Κοινά** | `menu_detail_screens` | 🔲 | Notifications: λίστα χωρίς πηγή (τίποτα δεν τις δημιουργεί). Audit log: τοπικό, ελεύθερο κείμενο, χωρίς χρήστη. Drive: placeholder. Global search: ❌. |
| **Dashboard** | `dashboard_screen` | ✅ τοπικά | Επόμενο live, πρόβα, KPI από πραγματικά (τοπικά) δεδομένα. |
| **Website** | — | ❌ | Δεν υπάρχει τίποτα. |

## 3. Data models που υπονοεί το frontend

Σήμερα (`core/models.dart`): `TourItem`, `LiveItem`, `ProductItem`, `CustomerItem`, `OrderItem`, `CalendarItem`, `MemberProfile`, `StreamingIncome`, `GeneralExpense`, `RentPerson`, `RentPayment`, `AuditItem`, `AppNotification`.

Πώς αντιστοιχούν στο σχήμα-στόχο (σχεσιακό, Postgres):

- **Identity:** `users` (login) ≠ `members` (μέλη μπάντας/crew με προσωπικά στοιχεία) ≠ `contacts` (CRM). `user_roles`.
- **Bookings:** `venues`, `tours`, `lives` (+ `live_schedule` ώρες, `live_deal` τύπος/ποσά, `live_contacts`, `live_attachments`), `calendar_events`, `member_availability`, `tour_items` (διαμονή, μετακίνηση, per diem), `route_legs` (cache OSRM).
- **Merch:** `products` → `product_variants` (SKU, μέγεθος, χρώμα, τιμή, κόστος, low-stock όριο) · `stock_locations` · **`stock_movements` (append-only ledger: receive / sale / transfer / damage / count / reserve / release)** — το stock είναι άθροισμα κινήσεων, όχι πεδίο · `suppliers`, `purchase_orders` + lines.
- **Πωλήσεις:** `customers` (+ consent/newsletter), `orders` (κανάλι: web / pos / manual / bandcamp, status, live_id) + `order_lines` + `shipments` + `refunds` + `payments` · `stock_reservations` (TTL κατά το checkout) · `email_templates`, `messages` (ιστορικό επικοινωνίας).
- **Οικονομικά:** `transactions` (έσοδο/έξοδο, κατηγορία, ποσό σε cents, ΦΠΑ, σύνδεση με live/tour/order/project) · `recurring_expenses` + `scheduled_payments` (ενοίκιο) · `splits` (κανόνας μοιρασιάς ανά μέλος/άτομο) · `budgets` + lines · `receivables/payables` (ή view πάνω στα transactions) · `attachments` (αποδείξεις) · πεδία έτοιμα για myDATA (ΑΦΜ αντισυμβαλλόμενου, τύπος παραστατικού, ΜΑΡΚ) — κενά προς το παρόν.
- **CRM:** `contacts`, `organizations`, `contact_relations`, `interactions` (timeline), `reminders`.
- **Social:** `social_accounts`, `posts` (+ per-platform targets), `media_assets`.
- **Κοινά:** `audit_log` (ποιος, πότε, οντότητα, diff), `notifications`.

## 4. Τεχνικό χρέος / ζητήματα που πρέπει να λυθούν πρώτα

**Κρίσιμα (ασφάλεια / δεδομένα):**
1. **Ευαίσθητα προσωπικά δεδομένα στον browser.** Στο web, το `flutter_secure_storage` γράφει στο `localStorage` με κλειδί που επίσης βρίσκεται στο `localStorage` — ουσιαστικά μη κρυπτογραφημένο. ΑΜΚΑ/ΑΦΜ/IBAN/διαβατήρια μελών δεν πρέπει να μπουν εκεί. Η σελίδα login το λέει ήδη ως προειδοποίηση.
2. **Κανένα πραγματικό auth/authorization.** Όλα τα «admin only» είναι UI-only.
3. **Τα δεδομένα δεν μοιράζονται.** Κάθε κινητό/browser έχει δική του αντιγραφή· τίποτα δεν συγχρονίζεται. Αν υπάρχουν ήδη πραγματικά δεδομένα σε συσκευές, χρειάζεται εργαλείο export/import πριν τη μετάβαση.

**Data model:**
4. Χρήματα ως `double` παντού → μετάβαση σε ακέραια cents.
5. Δεν υπάρχει ΦΠΑ πουθενά.
6. Παραγγελία με ένα μόνο προϊόν· stock δεν επηρεάζεται από παραγγελίες· όχι variants.
7. `LiveItem.cashIncome / soundExpenses / extraExpenses` γράφονται από τη φόρμα του Tours αλλά δεν μετράνε σε κανένα σύνολο — διπλά/νεκρά πεδία.
8. `streamingIncomes` αποθηκεύεται αλλά τα Οικονομικά διαβάζουν χειροκίνητο σύνολο.
9. Order ID = `1000 + πλήθος + 1` → συγκρούσεις μετά από διαγραφή. Άλλα IDs = `microsecondsSinceEpoch` (ΟΚ τοπικά, όχι για multi-user → UUID).
10. `productById`/`customerById` κάνουν `firstWhere` χωρίς fallback → crash στα Οικονομικά αν διαγραφεί προϊόν με παραγγελίες.
11. Εικόνες base64 μέσα στο ίδιο JSON → το όριο ~5MB του `localStorage` θα χτυπήσει.

**Κώδικας:**
12. Business logic μέσα σε widgets (π.χ. οφειλές ενοικίου υπολογίζονται και στο dashboard και στο rent screen). Χρειάζεται repository/service layer ανά module ώστε να γίνει η σύνδεση με API χωρίς να ξαναγραφτούν οι οθόνες.
13. Οθόνες 600–900 γραμμών με inline bottom sheets — refactor μόνο όπου τις αγγίζουμε.
14. Όχι URL routing → απαραίτητο για share links (day sheets, tracking).
15. OSRM demo server: η πολιτική χρήσης του δεν είναι για production· για τον όγκο μιας μπάντας μάλλον αρκεί, αλλά θα μπει πίσω από το δικό μας API με cache.
16. Δύο αντικρουόμενες κατευθύνσεις backend στα docs (Firebase στο SECURITY.md, Cloudflare Workers + D1 στο README) — πρέπει να αποφασιστεί μία.

## 5. Η μεγάλη ασυμφωνία: Flutter vs «TypeScript παντού»

Το prompt ζητά TypeScript παντού και κοινούς τύπους frontend/backend, αλλά το υπάρχον frontend είναι Dart. Επιλογές:

- **A (προτείνω): Κρατάμε το Flutter app για το εσωτερικό εργαλείο.** Backend και website σε TypeScript. Κοινοί τύποι μέσω **ενός** συμβολαίου: zod schemas στο TS → OpenAPI → παραγόμενος Dart client. Ό,τι αλλάζει στο API αλλάζει αυτόματα και στους δύο clients. Κρατάμε όλη τη δουλειά UI/UX (v0.9–v0.15) και το iOS app.
- **B: Rewrite του app σε React/TS.** Πλήρως TS, ένα stack. Αλλά πετάμε ~10k γραμμές που δουλεύουν και το native iOS (Face ID, share sheet). Αντίκειται στο «επαναχρησιμοποίησε το υπάρχον frontend».

Το website **δεν** πρέπει να γίνει σε Flutter web (κακό SEO, βαρύ πρώτο φόρτωμα, κακή προσβασιμότητα) — άρα σε κάθε περίπτωση είναι TS.

## 6. Προτεινόμενη αρχιτεκτονική

```
tbn/ (monorepo, pnpm workspaces + Flutter)
├─ apps/manager/        Flutter app (ο υπάρχων κώδικας, μετακινημένος)
├─ apps/web/            Δημόσιο site — Astro (SSR/SSG, TS) ή Next.js
├─ services/api/        TS API (Hono) σε Cloudflare Workers
├─ packages/shared/     zod schemas, τύποι, domain logic (stock, money, splits, VAT)
├─ packages/db/         Drizzle schema, SQL migrations, seed
└─ packages/api_client_dart/  παραγόμενος από OpenAPI
```

- **Βάση:** PostgreSQL σε EU region (Supabase Frankfurt ή Neon EU). Postgres αντί D1/SQLite γιατί χρειαζόμαστε πραγματικές transactions & row locks για κρατήσεις stock, constraints, και reporting queries.
- **Auth:** Supabase Auth (email/password, magic link, reset, MFA) — ίδιος πάροχος για μέλη και (προαιρετικά) πελάτες. Ρόλοι σε πίνακα `user_roles`, έλεγχος σε **κάθε** endpoint του API (και RLS ως δεύτερη γραμμή άμυνας). Εναλλακτική χωρίς Supabase: Better Auth μέσα στο Worker.
- **Αρχεία:** Supabase Storage ή Cloudflare R2 (συμβόλαια, riders, αποδείξεις, εικόνες προϊόντων), private buckets + signed URLs.
- **Πληρωμές:** checkout session του παρόχου, webhook → API (επαλήθευση υπογραφής) → order `paid` + μετατροπή κράτησης stock σε πώληση, idempotent.
- **Emails:** transactional πάροχος (π.χ. Resend/Postmark) με templates στη βάση, editable από το app.
- **POS offline:** τοπική ουρά πωλήσεων στο Flutter με client UUIDs, idempotent sync· ο server δέχεται πώληση ακόμη κι αν βγάλει αρνητικό stock (η πώληση έγινε ήδη φυσικά) και τη σημαδεύει για έλεγχο.
- **Ευαίσθητα στοιχεία μελών:** ξεχωριστός πίνακας, κρυπτογράφηση πεδίων (pgcrypto/KMS), πρόσβαση μόνο admin, κάθε ανάγνωση στο audit log.
- **i18n:** Flutter `gen-l10n` (ARB el/en)· site με routes `/el`, `/en`.
- **Hosting:** όλα σε Cloudflare (Pages για site + app, Workers για API) — συνέχεια με το υπάρχον deploy.

## 7. Πλάνο σε φάσεις

Προτεινόμενη αλλαγή στη σειρά: πριν τα «βαθιά» modules, ένα **lift-and-shift** των υπαρχόντων οντοτήτων στη βάση, ώστε η μπάντα να έχει αμέσως κοινά δεδομένα και πραγματικό login.

| Φάση | Περιεχόμενο |
|---|---|
| **1. Θεμέλια** | git + monorepo + CI · Postgres schema για τις υπάρχουσες οντότητες (cents, UUID) · API skeleton · Auth & ρόλοι · Dart client · repository layer στο Flutter (οι οθόνες μένουν ίδιες) · URL routing · i18n υποδομή · εργαλείο import από το τοπικό JSON · διόρθωση test. |
| **2. Merch & stock** | Variants, τοποθεσίες, ledger κινήσεων, απογραφή, restock/όρια, προμηθευτές & PO, POS mode (offline), line items παραγγελιών. |
| **3. Website & checkout** | Site (Home, Shop, Tour dates, Music, About, Contact→CRM inquiry, Newsletter), καλάθι, κράτηση stock, πληρωμές + webhooks, guest checkout, tracking page, legal σελίδες, cookie consent. |
| **4. Παραγγελίες & ενημερώσεις πελατών** | Νέα statuses, αποστολές, επιστροφές/refunds, αυτόματα emails, templates, ιστορικό επικοινωνίας, GDPR consent. |
| **5. Bookings / Tours** | Νέα statuses, ώρες, deals, συμβόλαια/riders, day sheets (PDF + share link), συγκρούσεις, διαθεσιμότητα, tour budget εκτίμηση vs πραγματικό. |
| **6. Οικονομικά** | Ledger, κατηγορίες, επαναλαμβανόμενα (μεταφορά ενοικίου), εκκρεμότητες, budgets, splits/υπόλοιπα μελών, αποδείξεις, export CSV/XLSX, dashboard. |
| **7. CRM** | Επαφές, venues, σχέσεις, timeline, templates & αποστολή, υπενθυμίσεις, πρόταση για Gmail. |
| **8. Social** | Content calendar, media library, προτάσεις από events· auto-posting μόνο μετά από επιβεβαίωση περιορισμών κάθε API. |
| Cross-cutting | Notifications (in-app + email), audit log με χρήστη, global search — χτίζονται σταδιακά από τη Φάση 1. |

## 8. Ανοιχτές ερωτήσεις

1. **Flutter (A) ή rewrite σε React/TS (B);** (§5)
2. **Backend/βάση/auth:** Supabase (Postgres + Auth + Storage, EU) + TS API σε Cloudflare Workers — ή προτιμάς κάτι άλλο (Firebase, όπως στο SECURITY.md; αποκλειστικά Cloudflare D1;)
3. **Πάροχος πληρωμών:** Stripe ή Viva Wallet;
4. **Hosting:** μένουμε σε Cloudflare; Domain για site και app;
5. **Social πλατφόρμες** που μας ενδιαφέρουν.
6. **Νομική οντότητα / ΦΠΑ:** Η μπάντα κόβει παραστατικά (ΑΦΜ, ατομική, ΑΜΚΕ, μέσω τρίτου); Αυτό καθορίζει τι απόδειξη δίνει το e-shop και πώς χειριζόμαστε ΦΠΑ.
7. **Υπάρχοντα δεδομένα:** Υπάρχουν πραγματικά δεδομένα σε κινητά/browsers που πρέπει να μεταφερθούν;
8. **Ενοίκιο:** Τα 11 «άτομα ενοικίου» είναι διαφορετικά από τα μέλη (π.χ. κοινόχρηστο studio με άλλες μπάντες); Πρέπει να έχουν login;
9. **Bandcamp:** Θέλουμε συγχρονισμό παραγγελιών Bandcamp ή αρκεί χειροκίνητη καταχώρηση; (Χρειάζεται να ελέγξω τι πρόσβαση API δίνει το Bandcamp στον λογαριασμό σας.)
10. **Μεταφορικές:** χειροκίνητο tracking number αρκεί, ή integration με BoxNow/ACS κ.λπ.;
11. **Website:** υπάρχει σημερινό site/domain/branding; Από πού έρχεται το περιεχόμενο Music/About (το app ή ένα απλό CMS);
12. **Χρήστες:** πόσοι και ποιοι ρόλοι (το SECURITY.md αναφέρει 7);

---

## 9. Αποφάσεις (απαντήσεις χρήστη, 2026-10-20)

| # | Απόφαση |
|---|---|
| Frontend app | **Κρατάμε Flutter.** |
| Backend | **Self-hostable**: θα μπορεί να τρέξει σε local server του χρήστη. → Αντί για Supabase: PostgreSQL + TS API (Node/Hono) + auth library μέσα στο API, όλα σε Docker Compose. Καμία εξάρτηση από managed υπηρεσία. |
| Πληρωμές | **Εκτός production v1.** Το data model/adapter θα τις υποστηρίζει. Το shop στην αρχή: κατάλογος + link στο Bandcamp. Επιλογή παρόχου αργότερα, με κριτήριο το συνολικό κόστος και την ευκολία για τον πελάτη. |
| Υπάρχοντα δεδομένα | Excel αρχεία στο Google Drive → εργαλείο import (χρειάζονται δείγματα αρχείων). |
| Χρήστες | Μόνο εγκεκριμένοι χρήστες (~11) με ρόλους, μόνο με πρόσκληση. Οι πελάτες έχουν πρόσβαση μόνο στο site. |

### Προτεινόμενο τελικό stack (προς επιβεβαίωση)
- `services/api`: Node 22 + Hono + Drizzle ORM + zod → OpenAPI. Auth: Better Auth (email/password, TOTP 2FA, passkeys, invite-only, admin revoke).
- `PostgreSQL 16` σε container, με volume + κρυπτογραφημένα off-site backups.
- Αρχεία: δίσκος του server μέσω storage adapter (μπορεί να αλλάξει αργότερα σε S3-compatible).
- Email: SMTP adapter.
- Έκθεση στο internet: Cloudflare Tunnel (χωρίς ανοιχτά ports) + Cloudflare Access μπροστά από app/API ως δεύτερο επίπεδο.
- Site: Astro, static build σε Cloudflare Pages. Ξαναχτίζεται όταν αλλάζουν προϊόντα ή lives. Βλέπει μόνο ένα μικρό public API (κατάλογος, tour dates, contact form) και ποτέ τη βάση.
