enum LiveStatus { proposal, negotiation, confirmed, completed, cancelled }

enum OrderStatus {
  waitingContact,
  waitingRestock,
  sent,
  completed,
  cancelled,
}

enum ShippingMethod { boxNow, elta, acs, geniki }
enum OrderSource { organic, bandcamp }
enum RentPaymentMethod { cash, bankTransfer, iris, revolut, other }
enum GeneralExpenseCategory { recordingFee, rentFee }
enum MemberRole { musician, driver, soundEngineer, technician }
enum OrderContext { afterLive, outsideLive }


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

class TourItem {
  TourItem({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.vanId,
    this.consumption,
  });

  final String id;
  String name;
  DateTime startDate;
  DateTime endDate;

  /// Βαν και κατανάλωση (L/100km) αυτού του tour. null = προεπιλογή Settings.
  String? vanId;
  double? consumption;
}

class LiveItem {
  LiveItem({
    required this.id,
    required this.venue,
    required this.city,
    required this.country,
    required this.date,
    required this.status,
    this.tourId,
    this.cashIncome = 0,
    this.merchIncome = 0,
    this.soundExpenses = 0,
    this.extraExpenses = 0,
    this.doorDealAmount = 0,
    this.fixAmount = 0,
    this.soundEngineerFee = 0,
    this.technicianFee = 0,
    this.supportBandFee = 0,
    this.mainAct = '',
    this.support = '',
    this.contactPerson = '',
    this.soundEngineer = '',
    this.ticketsPresaleAmount = 0,
    this.ticketsDoorAmount = 0,
    this.generalInfo = '',
    this.countryCode,
    this.lat,
    this.lon,
  });

  final String id;
  String venue;
  String city;
  String country;
  String? countryCode;
  double? lat;
  double? lon;
  DateTime date;
  LiveStatus status;
  String? tourId;
  double cashIncome;
  double merchIncome;
  double soundExpenses;
  double extraExpenses;
  double doorDealAmount;
  double fixAmount;
  double soundEngineerFee;
  double technicianFee;
  double supportBandFee;
  String mainAct;
  String support;
  String contactPerson;
  String soundEngineer;
  int ticketsPresaleAmount;
  int ticketsDoorAmount;
  String generalInfo;

  int get ticketsTotalAmount =>
      ticketsPresaleAmount + ticketsDoorAmount;

  double get totalIncome => doorDealAmount + fixAmount + merchIncome;
  double get totalExpenses =>
      soundEngineerFee + technicianFee + supportBandFee;
  double get net => totalIncome - totalExpenses;
}

class ProductItem {
  ProductItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.unitCost,
    required this.salePrice,
    this.imagePath,
  });

  final String id;
  String name;
  int stock;
  double unitCost;
  double salePrice;
  String? imagePath;
}

class CustomerItem {
  CustomerItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  final String id;
  String firstName;
  String lastName;
  String email;
  String phone;
  String address;
  String city;
  String postalCode;
  String country;

  String get fullName => '$firstName $lastName'.trim();
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.quantity,
    required this.shippingCost,
    required this.shippingMethod,
    required this.status,
    required this.source,
    required this.createdAt,
    this.context = OrderContext.outsideLive,
    this.trackingNumber = '',
    this.notes = '',
  });

  final String id;
  String customerId;
  String productId;
  int quantity;
  double shippingCost;
  ShippingMethod shippingMethod;
  OrderStatus status;
  OrderSource source;
  DateTime createdAt;
  OrderContext context;
  String trackingNumber;
  String notes;
}

class CalendarItem {
  CalendarItem({
    required this.id,
    required this.dateTime,
    required this.title,
    required this.type,
    this.location = '',
    this.notes = '',
  });

  final String id;
  DateTime dateTime;
  String title;
  String type;
  String location;
  String notes;
}


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
  });

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

  String get fullName => '$name $surname'.trim();
}


class StreamingIncome {
  StreamingIncome({
    required this.id,
    required this.platform,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  final String id;
  String platform;
  double amount;
  DateTime date;
  String notes;
}

class GeneralExpense {
  GeneralExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  final String id;
  GeneralExpenseCategory category;
  double amount;
  DateTime date;
  String notes;
}

class RentPerson {
  RentPerson({
    required this.id,
    required this.name,
  });

  final String id;
  String name;
}

class RentPayment {
  RentPayment({
    required this.id,
    required this.personId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    required this.month,
  });

  final String id;
  String personId;
  double amount;
  DateTime paymentDate;
  RentPaymentMethod method;
  DateTime month;
}

class AuditItem {
  AuditItem({
    required this.at,
    required this.area,
    required this.action,
  });

  final DateTime at;
  final String area;
  final String action;
}

class AppNotification {
  AppNotification({
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });

  final String title;
  final String body;
  final DateTime at;
  bool read;
}
