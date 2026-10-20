import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../core/models.dart';
import '../core/theme.dart';

/// In-memory cache of the server data, shared by all screens.
///
/// The server is the source of truth: [loadAll] fills the lists from GET /api/v1/bootstrap and every
/// change goes through [create], [update] or [remove], which call the API and then refresh the
/// cached item (or roll it back and show the error). The audit log is written by the server.
class AppStore {
  AppStore._();

  static final ApiClient api = ApiClient.instance;

  /// Shows API errors from anywhere in the app. Set on MaterialApp.scaffoldMessengerKey.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static final ValueNotifier<AppThemeOption> themeOption = ValueNotifier<AppThemeOption>(AppThemeOption.dark);
  static final ValueNotifier<Me?> me = ValueNotifier<Me?>(null);
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('el'));
  static final ValueNotifier<AppSettings> settings = ValueNotifier<AppSettings>(
    AppSettings(
        monthlyRentCents: 35000, dieselPriceCents: 175, fuelConsumption: 9.1, vanId: 'vw_t61', lowStockThreshold: 3),
  );

  /// Trip-cost inputs for the route widgets (estimates, so plain euros are fine here).
  static final ValueListenable<double> dieselPrice = _Derived(settings, (s) => s.dieselPriceCents / 100);
  static final ValueListenable<double> fuelConsumption = _Derived(settings, (s) => s.fuelConsumption);

  /// Increases on every data change so all pages rebuild.
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  static final tours = <TourItem>[];
  static final lives = <LiveItem>[];
  static final products = <ProductItem>[];
  static final customers = <CustomerItem>[];
  static final orders = <OrderItem>[];
  static final calendar = <CalendarItem>[];
  static final members = <MemberProfile>[];
  static final streamingIncomes = <StreamingIncome>[];
  static final generalExpenses = <GeneralExpense>[];
  static final rentPeople = <RentPerson>[];
  static final rentPayments = <RentPayment>[];
  static final audit = <AuditItem>[];
  static final notifications = <AppNotification>[];

  static bool can(String resource, String action) => me.value?.can(resource, action) ?? false;

  // ------------------------------------------------------------------ lookups

  static ProductItem? productById(String id) => _byId(products, id, (p) => p.id);
  static CustomerItem? customerById(String id) => _byId(customers, id, (c) => c.id);

  static T? _byId<T>(List<T> list, String id, String Function(T) idOf) {
    for (final e in list) {
      if (idOf(e) == id) return e;
    }
    return null;
  }

  /// Επόμενο επιβεβαιωμένο live (το πρώτο χρονολογικά), ή null.
  static LiveItem? nextConfirmedLive() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = lives.where((l) => l.status == LiveStatus.confirmed && !l.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static int confirmedUpcomingCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return lives.where((l) => l.status == LiveStatus.confirmed && !l.date.isBefore(today)).length;
  }

  static CalendarItem? nextRehearsal() {
    final now = DateTime.now();
    final rehearsals = calendar.where((e) => e.type == 'Rehearsal' && e.startsAt.isAfter(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return rehearsals.isEmpty ? null : rehearsals.first;
  }

  /// Ημερολόγιο = χειροκίνητα events + τα lives (ίδια καταχώρηση, όχι αντίγραφο).
  static List<CalendarItem> calendarWithLives() => [
        ...calendar,
        for (final l in lives)
          CalendarItem(
            id: 'live:${l.id}',
            startsAt: DateTime(l.date.year, l.date.month, l.date.day, 21),
            title: l.venue,
            type: 'Live',
            location: [l.city, l.country].where((e) => e.isNotEmpty).join(', '),
            visibility: CalendarVisibility.team,
          ),
      ];

  static int get streamingIncomeTotalCents => streamingIncomes.fold(0, (sum, s) => sum + s.amountCents);

  // ------------------------------------------------------------------ loading

  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('tbn_theme');
    themeOption.value = AppThemeOption.values.firstWhere((v) => v.name == theme, orElse: () => AppThemeOption.dark);
  }

  /// Saves the language on the user's account so it follows them to other devices.
  static Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    try {
      final json = await api.patch('/api/v1/me', {'locale': code}) as Map<String, dynamic>;
      me.value = Me.fromJson(json);
    } on ApiException catch (e) {
      _report(e);
    }
  }

  static Future<void> signOut() async {
    try {
      await api.post('/api/auth/sign-out', const <String, dynamic>{});
    } on ApiException {
      // Signing out locally is enough when the server cannot be reached.
    }
    clear();
  }

  static Future<void> setTheme(AppThemeOption option) async {
    themeOption.value = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tbn_theme', option.name);
  }

  /// Who is signed in, or null. Throws ApiException when the server is unreachable.
  static Future<Me?> loadMe() async {
    try {
      final json = await api.get('/api/v1/me') as Map<String, dynamic>;
      final m = me.value = Me.fromJson(json);
      locale.value = Locale(m.locale == 'en' ? 'en' : 'el');
      return m;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) return me.value = null;
      rethrow;
    }
  }

  /// Loads everything the user may read.
  static Future<void> loadAll() async {
    final json = await api.get('/api/v1/bootstrap') as Map<String, dynamic>;
    me.value = Me.fromJson(json['me'] as Map<String, dynamic>);
    if (json['settings'] != null) settings.value = AppSettings.fromJson(json['settings'] as Map<String, dynamic>);
    final data = json['data'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) => ((data[key] as List?) ?? const []).cast<Map<String, dynamic>>();

    _replace(tours, rows('tours').map(TourItem.fromJson));
    _replace(lives, rows('lives').map(LiveItem.fromJson));
    _replace(products, rows('products').map(ProductItem.fromJson));
    _replace(customers, rows('customers').map(CustomerItem.fromJson));
    _replace(orders, rows('orders').map(OrderItem.fromJson));
    _replace(calendar, rows('calendar-events').map(CalendarItem.fromJson));
    _replace(members, rows('members').map((j) => MemberProfile.fromItem(MemberItem.fromJson(j))));
    _replace(streamingIncomes, rows('streaming-incomes').map(StreamingIncome.fromJson));
    _replace(generalExpenses, rows('general-expenses').map(GeneralExpense.fromJson));
    _replace(rentPeople, rows('rent-people').map(RentPerson.fromJson));
    _replace(rentPayments, rows('rent-payments').map(RentPayment.fromJson));
    _changed();
    await loadNotifications();
  }

  static Future<void> loadNotifications() async {
    try {
      final json = await api.get('/api/v1/notifications') as Map<String, dynamic>;
      _replace(notifications, (json['items'] as List).cast<Map<String, dynamic>>().map(AppNotification.fromJson));
      _changed();
    } on ApiException catch (e) {
      _report(e);
    }
  }

  static Future<void> loadAudit() async {
    if (!can('audit', 'read')) return;
    try {
      final json = await api.get('/api/v1/audit?limit=200') as Map<String, dynamic>;
      _replace(audit, (json['items'] as List).cast<Map<String, dynamic>>().map(AuditItem.fromJson));
      _changed();
    } on ApiException catch (e) {
      _report(e);
    }
  }

  static void clear() {
    for (final l in <List<Object>>[
      tours,
      lives,
      products,
      customers,
      orders,
      calendar,
      members,
      streamingIncomes,
      generalExpenses,
      rentPeople,
      rentPayments,
      audit,
      notifications,
    ]) {
      l.clear();
    }
    me.value = null;
    _changed();
  }

  // ------------------------------------------------------------------ changes

  static final Map<Type, _Entity<Object>> _entities = {
    TourItem: _Entity<TourItem>('tours', tours, TourItem.fromJson, (e) => e.toJson(), (e) => e.id),
    LiveItem: _Entity<LiveItem>('lives', lives, LiveItem.fromJson, (e) => e.toJson(), (e) => e.id),
    ProductItem: _Entity<ProductItem>('products', products, ProductItem.fromJson, (e) => e.toJson(), (e) => e.id),
    CustomerItem: _Entity<CustomerItem>('customers', customers, CustomerItem.fromJson, (e) => e.toJson(), (e) => e.id),
    OrderItem: _Entity<OrderItem>('orders', orders, OrderItem.fromJson, (e) => e.toJson(), (e) => e.id),
    CalendarItem:
        _Entity<CalendarItem>('calendar-events', calendar, CalendarItem.fromJson, (e) => e.toJson(), (e) => e.id),
    StreamingIncome: _Entity<StreamingIncome>(
        'streaming-incomes', streamingIncomes, StreamingIncome.fromJson, (e) => e.toJson(), (e) => e.id),
    GeneralExpense: _Entity<GeneralExpense>(
        'general-expenses', generalExpenses, GeneralExpense.fromJson, (e) => e.toJson(), (e) => e.id),
    RentPerson: _Entity<RentPerson>('rent-people', rentPeople, RentPerson.fromJson, (e) => e.toJson(), (e) => e.id),
    RentPayment:
        _Entity<RentPayment>('rent-payments', rentPayments, RentPayment.fromJson, (e) => e.toJson(), (e) => e.id),
  }.cast<Type, _Entity<Object>>();

  static _Entity<Object> _entity(Object item) {
    final e = _entities[item.runtimeType];
    if (e == null) throw ArgumentError('No API mapping for ${item.runtimeType}');
    return e;
  }

  /// Adds [item] right away and saves it. On failure the item is removed again.
  static Future<bool> create(Object item) async {
    final e = _entity(item);
    e.list.add(item);
    _changed();
    try {
      final json = await api.post('/api/v1/${e.path}', e.toJson(item)) as Map<String, dynamic>;
      _put(e, e.fromJson(json));
      return true;
    } on ApiException catch (err) {
      e.list.remove(item);
      _changed();
      _report(err);
      return false;
    }
  }

  /// Saves the (already edited) [item]. On failure the server's version is restored.
  static Future<bool> update(Object item) async {
    final e = _entity(item);
    final id = e.idOf(item);
    _changed();
    try {
      final body = Map<String, dynamic>.from(e.toJson(item))..remove('id');
      final json = await api.patch('/api/v1/${e.path}/$id', body) as Map<String, dynamic>;
      _put(e, e.fromJson(json));
      return true;
    } on ApiException catch (err) {
      _report(err);
      await _refetch(e, id);
      return false;
    }
  }

  static Future<bool> remove(Object item) async {
    final e = _entity(item);
    final index = e.list.indexOf(item);
    e.list.remove(item);
    _changed();
    try {
      await api.delete('/api/v1/${e.path}/${e.idOf(item)}');
      return true;
    } on ApiException catch (err) {
      e.list.insert(index < 0 ? e.list.length : index, item);
      _changed();
      _report(err);
      return false;
    }
  }

  static Future<bool> updateSettings(Map<String, dynamic> changes) async {
    try {
      final json = await api.patch('/api/v1/settings', changes) as Map<String, dynamic>;
      settings.value = AppSettings.fromJson(json);
      _changed();
      return true;
    } on ApiException catch (err) {
      _report(err);
      return false;
    }
  }

  static Future<String?> uploadProductImage(ProductItem product, List<int> bytes, String filename) async {
    try {
      final json = await api.upload('/api/v1/products/${product.id}/image', Uint8List.fromList(bytes), filename)
          as Map<String, dynamic>;
      product.imageUrl = json['imageUrl'] as String;
      _changed();
      return product.imageUrl;
    } on ApiException catch (err) {
      _report(err);
      return null;
    }
  }

  // ------------------------------------------------------------------ members

  static Future<bool> saveMember(MemberProfile m, {required bool isNew}) async {
    try {
      final body = m.toItem().toJson();
      if (isNew) {
        await api.post('/api/v1/members', body);
        members.add(m);
      } else {
        await api.patch('/api/v1/members/${m.id}', Map<String, dynamic>.from(body)..remove('id'));
      }
      if (can('membersSensitive', 'write')) {
        await api.put('/api/v1/members/${m.id}/sensitive', m.toSensitive().toJson());
        m.sensitiveLoaded = true;
      }
      _changed();
      return true;
    } on ApiException catch (err) {
      _report(err);
      return false;
    }
  }

  /// Loads ΑΦΜ/ΑΜΚΑ/IBAN… for admins. Each call is recorded in the server's audit log.
  static Future<bool> loadMemberSensitive(MemberProfile m) async {
    if (!can('membersSensitive', 'read')) return false;
    try {
      final json = await api.get('/api/v1/members/${m.id}/sensitive') as Map<String, dynamic>;
      m.applySensitive(MemberSensitive.fromJson(json));
      _changed();
      return true;
    } on ApiException catch (err) {
      _report(err);
      return false;
    }
  }

  static Future<bool> removeMember(MemberProfile m) async {
    try {
      await api.delete('/api/v1/members/${m.id}');
      members.remove(m);
      _changed();
      return true;
    } on ApiException catch (err) {
      _report(err);
      return false;
    }
  }

  // ------------------------------------------------------------------ helpers

  static void _replace<T>(List<T> target, Iterable<T> value) {
    target
      ..clear()
      ..addAll(value);
  }

  static void _put(_Entity<Object> e, Object fresh) {
    final id = e.idOf(fresh);
    final i = e.list.indexWhere((x) => e.idOf(x) == id);
    if (i >= 0) {
      e.list[i] = fresh;
    } else {
      e.list.add(fresh);
    }
    _changed();
  }

  static Future<void> _refetch(_Entity<Object> e, String id) async {
    try {
      final json = await api.get('/api/v1/${e.path}/$id') as Map<String, dynamic>;
      _put(e, e.fromJson(json));
    } on ApiException {
      // Leave the local copy; the next full load will fix it.
    }
  }

  static void _changed() => dataVersion.value++;

  static void _report(ApiException err) {
    final text = switch (err.code) {
      'forbidden' => 'Δεν έχεις δικαίωμα για αυτή την ενέργεια.',
      'conflict' => err.message == 'Referenced by other records or references a missing record'
          ? 'Δεν γίνεται: χρησιμοποιείται από άλλες εγγραφές.'
          : err.message,
      'validation_failed' => 'Μη έγκυρα στοιχεία.',
      'offline' => 'Δεν υπάρχει σύνδεση με τον server. Η αλλαγή δεν αποθηκεύτηκε.',
      'unauthenticated' => 'Η σύνδεση έληξε. Συνδέσου ξανά.',
      _ => err.message,
    };
    messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
  }

  /// For screens that call the API directly.
  static void reportError(Object err) {
    if (err is ApiException) {
      _report(err);
    } else {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('$err')));
    }
  }
}

class _Entity<T extends Object> {
  _Entity(this.path, this.list, this._fromJson, this._toJson, this._idOf);

  final String path;
  final List<T> list;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final String Function(T) _idOf;

  Object fromJson(Map<String, dynamic> json) => _fromJson(json);
  Map<String, dynamic> toJson(Object item) => _toJson(item as T);
  String idOf(Object item) => _idOf(item as T);
}

/// A read-only view of one value inside another listenable.
class _Derived<S, T> extends ChangeNotifier implements ValueListenable<T> {
  _Derived(this._source, this._select) {
    _source.addListener(notifyListeners);
  }

  final ValueListenable<S> _source;
  final T Function(S) _select;

  @override
  T get value => _select(_source.value);
}
