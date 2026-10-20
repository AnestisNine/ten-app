import 'models.dart';

/// Totals for the Finance page, in cents. Counts completed lives, completed orders,
/// streaming income and general expenses (same rules as before the move to the server).
class FinanceSummary {
  FinanceSummary({
    required List<LiveItem> lives,
    required List<OrderItem> orders,
    required List<ProductItem> products,
    required List<StreamingIncome> streaming,
    required List<GeneralExpense> expenses,
  }) {
    final completed = lives.where((l) => l.status == LiveStatus.completed);
    liveIncome = completed.fold(0, (sum, l) => sum + l.totalIncomeCents);
    liveExpenses = completed.fold(0, (sum, l) => sum + l.totalExpensesCents);

    final prices = {for (final p in products) p.id: p.salePriceCents};
    orderIncome = orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0, (sum, o) => sum + (prices[o.productId] ?? 0) * o.quantity + o.shippingCostCents);

    streamingIncome = streaming.fold(0, (sum, s) => sum + s.amountCents);
    recordingExpenses = expenses
        .where((e) => e.category == GeneralExpenseCategory.recordingFee)
        .fold(0, (sum, e) => sum + e.amountCents);
    rentExpenses =
        expenses.where((e) => e.category == GeneralExpenseCategory.rentFee).fold(0, (sum, e) => sum + e.amountCents);
  }

  late final int liveIncome;
  late final int liveExpenses;
  late final int orderIncome;
  late final int streamingIncome;
  late final int recordingExpenses;
  late final int rentExpenses;

  int get totalIncome => liveIncome + orderIncome + streamingIncome;
  int get totalExpenses => liveExpenses + recordingExpenses + rentExpenses;
  int get net => totalIncome - totalExpenses;
}
