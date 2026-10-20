/// App data models. The classes themselves are generated from the API's shared schemas
/// (models.g.dart); this file adds helpers, labels and derived values.
library;

import 'dart:math';

part 'models.g.dart';

/// Random UUID v4 for new records, so the app can create items before the server answers.
String newId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Calendar dates travel as YYYY-MM-DD and are local dates in the app.
DateTime parseApiDate(String value) {
  final p = value.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String formatApiDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

extension LiveTotals on LiveItem {
  int get ticketsTotal => ticketsPresale + ticketsDoor;
  int get totalIncomeCents => doorDealCents + fixCents + merchIncomeCents;
  int get totalExpensesCents => soundEngineerFeeCents + technicianFeeCents + supportBandFeeCents;
  int get netCents => totalIncomeCents - totalExpensesCents;
}

extension CustomerName on CustomerItem {
  String get fullName => '$firstName $lastName'.trim();
}

extension MemberName on MemberItem {
  String get fullName => '$name $surname'.trim();
}

extension OrderLabel on OrderItem {
  /// Display label, e.g. "#1042". New orders show "#…" until the server assigns the number.
  String get label => number > 0 ? '#$number' : '#…';
}

String rentPaymentMethodLabel(RentPaymentMethod method) {
  switch (method) {
    case RentPaymentMethod.cash:
      return 'Μετρητά';
    case RentPaymentMethod.bankTransfer:
      return 'Τραπεζική μεταφορά';
    case RentPaymentMethod.iris:
      return 'IRIS';
    case RentPaymentMethod.revolut:
      return 'Revolut';
    case RentPaymentMethod.other:
      return 'Άλλο';
  }
}

String generalExpenseCategoryLabel(GeneralExpenseCategory category) {
  switch (category) {
    case GeneralExpenseCategory.recordingFee:
      return 'Αμοιβή ηχογράφησης';
    case GeneralExpenseCategory.rentFee:
      return 'Ενοίκιο';
  }
}

String memberRoleLabel(MemberRole role) {
  switch (role) {
    case MemberRole.musician:
      return 'Μουσικός';
    case MemberRole.driver:
      return 'Οδηγός';
    case MemberRole.soundEngineer:
      return 'Ηχολήπτης';
    case MemberRole.technician:
      return 'Τεχνικός';
  }
}

String liveStatusLabel(LiveStatus s) {
  switch (s) {
    case LiveStatus.proposal:
      return 'Πρόταση';
    case LiveStatus.negotiation:
      return 'Διαπραγμάτευση';
    case LiveStatus.confirmed:
      return 'Επιβεβαιωμένο';
    case LiveStatus.completed:
      return 'Ολοκληρωμένο';
    case LiveStatus.cancelled:
      return 'Ακυρωμένο';
  }
}

String orderStatusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.waitingContact:
      return 'Σε αναμονή επικοινωνίας';
    case OrderStatus.waitingRestock:
      return 'Αναμονή restock';
    case OrderStatus.sent:
      return 'Απεστάλη';
    case OrderStatus.completed:
      return 'Ολοκληρώθηκε';
    case OrderStatus.cancelled:
      return 'Ακυρώθηκε';
  }
}

String shippingMethodLabel(ShippingMethod s) {
  switch (s) {
    case ShippingMethod.boxNow:
      return 'Box Now';
    case ShippingMethod.elta:
      return 'ΕΛΤΑ';
    case ShippingMethod.acs:
      return 'ACS';
    case ShippingMethod.geniki:
      return 'Γενική Ταχυδρομική';
  }
}

String orderContextLabel(OrderContext c) {
  switch (c) {
    case OrderContext.afterLive:
      return 'Μετά από Live / Πάγκος';
    case OrderContext.outsideLive:
      return 'Εκτός Live';
  }
}

String orderSourceLabel(OrderSource s) {
  switch (s) {
    case OrderSource.organic:
      return 'Organic';
    case OrderSource.bandcamp:
      return 'Bandcamp';
  }
}

String calendarVisibilityLabel(CalendarVisibility v) {
  switch (v) {
    case CalendarVisibility.team:
      return 'Ομάδα';
    case CalendarVisibility.private:
      return 'Ιδιωτικό';
  }
}

/// A band member as the Members screen shows it: the basic record everyone may read, plus the
/// sensitive fields that only admins can load (empty until [sensitiveLoaded]).
class MemberProfile {
  MemberProfile({
    required this.id,
    required this.role,
    required this.surname,
    required this.name,
    this.fatherSurname = '',
    this.fatherName = '',
    this.motherName = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.nationality = '',
    this.address = '',
    this.mobile = '',
    this.maritalStatus = '',
    this.children = '',
    this.idNumber = '',
    this.passport = '',
    this.issueDateAndAuthority = '',
    this.ama = '',
    this.afm = '',
    this.doy = '',
    this.amka = '',
    this.contactPhone = '',
    this.email = '',
    this.iban = '',
    this.bank = '',
    this.userId,
    this.sensitiveLoaded = false,
  });

  factory MemberProfile.fromItem(MemberItem m) => MemberProfile(
        id: m.id,
        role: m.role,
        surname: m.surname,
        name: m.name,
        mobile: m.mobile,
        email: m.email,
        userId: m.userId,
      );

  final String id;
  MemberRole role;
  String surname;
  String name;
  String fatherSurname;
  String fatherName;
  String motherName;
  String birthDate;
  String birthPlace;
  String nationality;
  String address;
  String mobile;
  String maritalStatus;
  String children;
  String idNumber;
  String passport;
  String issueDateAndAuthority;
  String ama;
  String afm;
  String doy;
  String amka;
  String contactPhone;
  String email;
  String iban;
  String bank;
  String? userId;
  bool sensitiveLoaded;

  String get fullName => '$name $surname'.trim();

  MemberItem toItem() => MemberItem(
        id: id,
        role: role,
        name: name,
        surname: surname,
        mobile: mobile,
        email: email,
        userId: userId,
      );

  MemberSensitive toSensitive() => MemberSensitive(
        fatherSurname: fatherSurname,
        fatherName: fatherName,
        motherName: motherName,
        birthDate: birthDate,
        birthPlace: birthPlace,
        nationality: nationality,
        address: address,
        maritalStatus: maritalStatus,
        children: children,
        idNumber: idNumber,
        passport: passport,
        issueDateAndAuthority: issueDateAndAuthority,
        ama: ama,
        afm: afm,
        doy: doy,
        amka: amka,
        contactPhone: contactPhone,
        iban: iban,
        bank: bank,
      );

  void applySensitive(MemberSensitive s) {
    fatherSurname = s.fatherSurname;
    fatherName = s.fatherName;
    motherName = s.motherName;
    birthDate = s.birthDate;
    birthPlace = s.birthPlace;
    nationality = s.nationality;
    address = s.address;
    maritalStatus = s.maritalStatus;
    children = s.children;
    idNumber = s.idNumber;
    passport = s.passport;
    issueDateAndAuthority = s.issueDateAndAuthority;
    ama = s.ama;
    afm = s.afm;
    doy = s.doy;
    amka = s.amka;
    contactPhone = s.contactPhone;
    iban = s.iban;
    bank = s.bank;
    sensitiveLoaded = true;
  }
}

/// The signed-in user, as returned by GET /api/v1/me.
class Me {
  Me({
    required this.id,
    required this.name,
    required this.email,
    required this.locale,
    required this.roles,
    required this.twoFactorEnabled,
    required this.twoFactorRequired,
    required this.permissions,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        locale: (j['locale'] as String?) ?? 'el',
        roles: List<String>.from(j['roles'] as List),
        twoFactorEnabled: j['twoFactorEnabled'] as bool,
        twoFactorRequired: j['twoFactorRequired'] as bool,
        permissions: (j['permissions'] as Map).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
      );

  final String id;
  final String name;
  final String email;
  final String locale;
  final List<String> roles;
  final bool twoFactorEnabled;
  final bool twoFactorRequired;
  final Map<String, List<String>> permissions;

  bool get needsTwoFactorSetup => twoFactorRequired && !twoFactorEnabled;

  /// UI hint only; the server enforces permissions on every request.
  bool can(String resource, String action) => permissions[resource]?.contains(action) ?? false;
}
