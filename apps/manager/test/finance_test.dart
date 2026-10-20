import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/core/finance.dart';
import 'package:tbn_manager/core/models.dart';

void main() {
  test('sums only completed lives and orders, in cents', () {
    final product = ProductItem(id: 'p', name: 'Tee', salePriceCents: 2000, unitCostCents: 800);
    OrderItem order(OrderStatus s) => OrderItem(
          id: newId(),
          customerId: 'c',
          productId: 'p',
          quantity: 2,
          shippingCostCents: 550,
          shippingMethod: ShippingMethod.acs,
          status: s,
          source: OrderSource.organic,
          context: OrderContext.outsideLive,
          createdAt: DateTime(2026),
        );
    final summary = FinanceSummary(
      lives: [
        LiveItem(
            id: 'a', date: DateTime(2026), status: LiveStatus.completed, fixCents: 50000, soundEngineerFeeCents: 15000),
        LiveItem(id: 'b', date: DateTime(2026), status: LiveStatus.confirmed, fixCents: 99999),
      ],
      orders: [order(OrderStatus.completed), order(OrderStatus.sent)],
      products: [product],
      streaming: [StreamingIncome(id: 's', platform: 'Spotify', amountCents: 1854, date: DateTime(2026))],
      expenses: [
        GeneralExpense(id: 'e1', category: GeneralExpenseCategory.rentFee, amountCents: 35000, date: DateTime(2026)),
        GeneralExpense(
            id: 'e2', category: GeneralExpenseCategory.recordingFee, amountCents: 10001, date: DateTime(2026)),
      ],
    );
    expect(summary.liveIncome, 50000);
    expect(summary.liveExpenses, 15000);
    expect(summary.orderIncome, 4550);
    expect(summary.totalIncome, 50000 + 4550 + 1854);
    expect(summary.totalExpenses, 15000 + 35000 + 10001);
    expect(summary.net, 56404 - 60001);
  });

  test('an order whose product was deleted counts only shipping (no crash)', () {
    final summary = FinanceSummary(
      lives: const [],
      orders: [
        OrderItem(
          id: 'o',
          customerId: 'c',
          productId: 'gone',
          quantity: 1,
          shippingCostCents: 500,
          shippingMethod: ShippingMethod.elta,
          status: OrderStatus.completed,
          source: OrderSource.organic,
          context: OrderContext.outsideLive,
          createdAt: DateTime(2026),
        ),
      ],
      products: const [],
      streaming: const [],
      expenses: const [],
    );
    expect(summary.orderIncome, 500);
  });
}
