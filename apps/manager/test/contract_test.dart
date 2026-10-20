// Writes the JSON bodies the app sends to the API (contract/app-payloads.json). The API test suite
// (services/api/src/test/contract.test.ts) posts each one to the real endpoints, so a model change
// that the server would reject fails CI. Run `flutter test test/contract_test.dart` and commit the file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/core/models.dart';

void main() {
  test('app payloads match the committed contract fixture', () {
    final tourId = '11111111-1111-4111-8111-111111111111';
    final payloads = <String, Map<String, dynamic>>{
      'tours': TourItem(
        id: tourId,
        name: 'Spring Tour',
        startDate: DateTime(2027, 3, 1),
        endDate: DateTime(2027, 3, 20),
        vanId: 'vw_t61',
        consumption: 9.1,
      ).toJson(),
      'lives': LiveItem(
        id: '22222222-2222-4222-8222-222222222222',
        venue: 'Temple',
        city: 'Athens',
        country: 'Greece',
        countryCode: 'GR',
        lat: 37.98,
        lon: 23.72,
        date: DateTime(2027, 3, 5),
        status: LiveStatus.confirmed,
        tourId: tourId,
        doorDealCents: 120050,
        ticketsPresale: 10,
        generalInfo: 'Soundcheck 18:00',
      ).toJson(),
      'calendar-events': CalendarItem(
        id: '33333333-3333-4333-8333-333333333333',
        startsAt: DateTime.utc(2027, 3, 4, 18),
        title: 'Πρόβα',
        type: 'Rehearsal',
        location: 'Studio',
        visibility: CalendarVisibility.team,
      ).toJson(),
      'products': ProductItem(
        id: '44444444-4444-4444-8444-444444444444',
        name: 'Poster',
        stock: 30,
        unitCostCents: 150,
        salePriceCents: 1000,
      ).toJson(),
      'customers': CustomerItem(
        id: '55555555-5555-4555-8555-555555555555',
        firstName: 'Μαρία',
        lastName: 'Κ.',
        email: 'maria@example.com',
        country: 'Greece',
      ).toJson(),
      'orders': OrderItem(
        id: '66666666-6666-4666-8666-666666666666',
        customerId: '55555555-5555-4555-8555-555555555555',
        productId: '44444444-4444-4444-8444-444444444444',
        quantity: 2,
        shippingCostCents: 350,
        shippingMethod: ShippingMethod.boxNow,
        status: OrderStatus.waitingContact,
        source: OrderSource.organic,
        context: OrderContext.afterLive,
        createdAt: DateTime.utc(2027),
      ).toJson(),
      'members': MemberProfile(
        id: '77777777-7777-4777-8777-777777777777',
        role: MemberRole.musician,
        surname: 'Νέο',
        name: 'Μέλος',
        email: '',
      ).toItem().toJson(),
      'streaming-incomes': StreamingIncome(
        id: '88888888-8888-4888-8888-888888888888',
        platform: 'Bandcamp',
        amountCents: 4210,
        date: DateTime(2027, 2, 1),
      ).toJson(),
      'general-expenses': GeneralExpense(
        id: '99999999-9999-4999-8999-999999999999',
        category: GeneralExpenseCategory.recordingFee,
        amountCents: 20000,
        date: DateTime(2027, 2, 2),
      ).toJson(),
      'rent-people': RentPerson(id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', name: 'Άτομο 12').toJson(),
      'rent-payments': RentPayment(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        personId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        amountCents: 3182,
        paymentDate: DateTime(2027, 2, 3),
        method: RentPaymentMethod.revolut,
        month: DateTime(2027, 2),
      ).toJson(),
    };
    final json = '${const JsonEncoder.withIndent('  ').convert(payloads)}\n';
    final file = File('../../contract/app-payloads.json');
    if (Platform.environment['UPDATE_CONTRACT'] == '1' || !file.existsSync()) file.writeAsStringSync(json);
    expect(file.readAsStringSync(), json, reason: 'Run UPDATE_CONTRACT=1 flutter test test/contract_test.dart');
  });
}
