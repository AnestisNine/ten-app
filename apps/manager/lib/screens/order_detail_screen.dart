import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models.dart';
import '../core/money.dart';
import '../data/app_store.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  final OrderItem order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final product = AppStore.productById(order.productId);
    final customer = AppStore.customerById(order.customerId);
    final canEdit = AppStore.can('orders', 'write');
    final subtotal = (product?.salePriceCents ?? 0) * order.quantity;
    final total = subtotal + order.shippingCostCents;

    return Scaffold(
      appBar: AppBar(title: Text('Παραγγελία ${order.label}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            'Κατάσταση',
            [
              DropdownButtonFormField<OrderStatus>(
                initialValue: order.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: OrderStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(orderStatusLabel(s)),
                  );
                }).toList(),
                onChanged: !canEdit
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => order.status = value);
                        AppStore.update(order);
                      },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ShippingMethod>(
                initialValue: order.shippingMethod,
                decoration: const InputDecoration(
                  labelText: 'Shipping Method',
                ),
                items: ShippingMethod.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(shippingMethodLabel(s)),
                  );
                }).toList(),
                onChanged: !canEdit
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => order.shippingMethod = value);
                        AppStore.update(order);
                      },
              ),
            ],
          ),
          _card(
            'Πελάτης',
            customer == null
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Δεν έχεις πρόσβαση στα στοιχεία πελατών.'),
                    ),
                  ]
                : [
                    _tapRow('Όνομα', customer.fullName, null),
                    _tapRow('Τηλέφωνο', customer.phone, () => _openPhone(customer.phone)),
                    _tapRow('Email', customer.email, () => _openEmail(customer.email)),
                    _tapRow(
                      'Διεύθυνση',
                      '${customer.address}, ${customer.city} ${customer.postalCode}, ${customer.country}',
                      null,
                    ),
                  ],
          ),
          _card(
            'Παραγγελία',
            [
              _row('Source', orderSourceLabel(order.source)),
              _row('Τύπος', orderContextLabel(order.context)),
              _row('Προϊόν', product?.name ?? '—'),
              _row('Ποσότητα', '${order.quantity}'),
              _row('Τιμή / τεμ.', product == null ? '—' : formatCents(product.salePriceCents)),
              _row('Υποσύνολο', formatCents(subtotal)),
              _row('Μεταφορικά', formatCents(order.shippingCostCents)),
              _row('Σύνολο', formatCents(total), bold: true),
            ],
          ),
          _card(
            'Αποστολή',
            [
              _row('Method', shippingMethodLabel(order.shippingMethod)),
              _row(
                'Tracking',
                order.trackingNumber.isEmpty ? '—' : order.trackingNumber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _openEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launchUrl(uri);
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return _tapRow(label, value, null, bold: bold);
  }

  Widget _tapRow(
    String label,
    String value,
    VoidCallback? onTap, {
    bool bold = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  decoration: onTap == null ? null : TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
