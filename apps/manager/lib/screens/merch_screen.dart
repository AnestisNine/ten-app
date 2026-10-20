
import 'package:flutter/material.dart';

import '../core/widgets.dart';

import '../core/image_utils.dart';
import '../core/models.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import 'order_detail_screen.dart';
import 'product_edit_screen.dart';

class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key});

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  int tab = 1;

  static const _tabs = <String>['Stock', 'Orders', 'Products', 'Customers'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PageHeader(
            title: 'Merch',
            subtitle: '${AppStore.products.length} προϊόντα · '
                '${AppStore.orders.length} παραγγελίες',
            actions: [
              if ((tab == 1 && AppStore.can('orders', 'write') && AppStore.can('customers', 'read')) ||
                  (tab == 2 && AppStore.can('merch', 'write')))
                FilledButton.icon(
                  onPressed: tab == 1 ? _addOrganicOrder : () => _openProduct(null),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(tab == 1 ? 'Παραγγελία' : 'Προϊόν'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < (AppStore.can('customers', 'read') ? _tabs.length : 3); i++)
                  Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                    child: ChoiceChip(
                      label: Text(_tabs[i]),
                      selected: tab == i,
                      onSelected: (_) => setState(() => tab = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (tab == 0) _stock(),
          if (tab == 1) _orders(),
          if (tab == 2) _products(),
          if (tab == 3) _customers(),
        ],
      ),
    );
  }

  Widget _stock() {
    final t = Theme.of(context).textTheme;
    if (AppStore.products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Δεν υπάρχουν προϊόντα',
      );
    }
    final low = AppStore.settings.value.lowStockThreshold;
    Color colorFor(int n) => n == 0
        ? TbnColors.danger
        : n <= low
            ? TbnColors.warning
            : TbnColors.success;
    return Column(
      children: AppStore.products.map((product) {
        final variants = AppStore.variantsOf(product.id);
        final total = AppStore.stockOf(product.id);
        final single = variants.length == 1 && variants.first.label.toLowerCase() == 'one size';
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openProduct(product),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _thumbnail(product),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (!single && variants.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final v in variants)
                                StatusPill(label: '${v.label} · ${v.stock}', color: colorFor(v.stock)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: total == 0 ? 'Sold out' : '$total τεμ.',
                    color: colorFor(total),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _orders() {
    final t = Theme.of(context).textTheme;
    if (AppStore.orders.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Δεν υπάρχουν παραγγελίες',
      );
    }
    final sorted = [...AppStore.orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: sorted.map((order) {
        final product = AppStore.productById(order.productId);
        final total = ((product?.salePriceCents ?? 0) * order.quantity) + order.shippingCostCents;
        final color = orderStatusColor(order.status);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(
                TbnPageRoute<void>(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              )
                  .then((_) {
                setState(() {});
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconChip(
                    icon: order.source == OrderSource.bandcamp ? Icons.album_outlined : Icons.shopping_bag_outlined,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product?.name ?? '—'}'
                          '${_sizeSuffix(order)} × ${order.quantity}',
                          style: t.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.label} · '
                          '${orderSourceLabel(order.source)}',
                          style: t.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatEuro(total), style: t.titleSmall),
                      const SizedBox(height: 4),
                      StatusPill(
                        label: orderStatusLabel(order.status),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _products() {
    final t = Theme.of(context).textTheme;
    if (AppStore.products.isEmpty) {
      return const EmptyState(
        icon: Icons.checkroom_outlined,
        title: 'Δεν υπάρχουν προϊόντα',
      );
    }
    return Column(
      children: AppStore.products.map((product) {
        final margin = product.salePriceCents - product.unitCostCents;
        final sizes = AppStore.variantsOf(product.id).map((v) => v.label).join(' · ');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
          onTap: () => _openProduct(product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _thumbnail(product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: t.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Κόστος ${formatEuro(product.unitCostCents)}'
                        ' · κέρδος ${formatEuro(margin)}',
                        style: t.bodySmall,
                      ),
                      if (sizes.isNotEmpty) Text(sizes, style: t.bodySmall),
                    ],
                  ),
                ),
                Text(formatEuro(product.salePriceCents), style: t.titleMedium),
              ],
            ),
          ),
          ),
        );
      }).toList(),
    );
  }

  Widget _customers() {
    final t = Theme.of(context).textTheme;
    if (AppStore.customers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Δεν υπάρχουν πελάτες',
      );
    }
    return Column(
      children: AppStore.customers.map((customer) {
        final name = customer.fullName.trim();
        final initial = name.isEmpty ? '?' : name[0].toUpperCase();
        final contact = [customer.email, customer.phone].where((e) => e.isNotEmpty).join(' · ');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TbnColors.accent.withValues(alpha: 0.15),
                  foregroundColor: TbnColors.accent,
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: t.titleSmall),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          contact,
                          style: t.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (customer.city.isNotEmpty)
                        Text(
                          '${customer.city}, ${customer.country}',
                          style: t.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _sizeSuffix(OrderItem order) {
    final v = AppStore.variantById(order.variantId);
    return v == null || v.label.toLowerCase() == 'one size' ? '' : ' (${v.label})';
  }

  Widget _thumbnail(ProductItem product) {
    final provider = imageProviderFromRef(product.imageUrl);

    if (provider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image(
          image: provider,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return const IconChip(icon: Icons.checkroom, size: 48);
  }

  void _addOrganicOrder() {
    if (AppStore.customers.isEmpty || AppStore.products.isEmpty) {
      return;
    }

    CustomerItem customer = AppStore.customers.first;
    ProductItem product = AppStore.products.first;
    ProductVariant? variant = AppStore.variantsOf(product.id).firstOrNull;
    ShippingMethod shippingMethod = ShippingMethod.boxNow;
    OrderContext orderContext = OrderContext.outsideLive;
    final quantity = TextEditingController(text: '1');
    final shippingCost = TextEditingController(text: '0');
    final notes = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Νέα Organic Παραγγελία',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<CustomerItem>(
                    initialValue: customer,
                    decoration: const InputDecoration(
                      labelText: 'Πελάτης',
                    ),
                    items: AppStore.customers
                        .map(
                          (item) => DropdownMenuItem<CustomerItem>(
                            value: item,
                            child: Text(item.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          customer = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ProductItem>(
                    initialValue: product,
                    decoration: const InputDecoration(
                      labelText: 'Προϊόν',
                    ),
                    items: AppStore.products
                        .map(
                          (item) => DropdownMenuItem<ProductItem>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          product = value;
                          variant = AppStore.variantsOf(value.id).firstOrNull;
                        });
                      }
                    },
                  ),
                  if (AppStore.variantsOf(product.id).length > 1) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ProductVariant>(
                      key: ValueKey(product.id),
                      initialValue: variant,
                      decoration: const InputDecoration(labelText: 'Μέγεθος'),
                      items: AppStore.variantsOf(product.id)
                          .map((v) => DropdownMenuItem(value: v, child: Text('${v.label} (stock ${v.stock})')))
                          .toList(),
                      onChanged: (v) => modalSetState(() => variant = v),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ποσότητα',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: shippingCost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Μεταφορικά',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ShippingMethod>(
                    initialValue: shippingMethod,
                    decoration: const InputDecoration(
                      labelText: 'Τρόπος αποστολής',
                    ),
                    items: ShippingMethod.values
                        .map(
                          (method) => DropdownMenuItem<ShippingMethod>(
                            value: method,
                            child: Text(
                              shippingMethodLabel(method),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          shippingMethod = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<OrderContext>(
                    initialValue: orderContext,
                    decoration: const InputDecoration(
                      labelText: 'Τύπος παραγγελίας',
                    ),
                    items: OrderContext.values
                        .map(
                          (value) => DropdownMenuItem<OrderContext>(
                            value: value,
                            child: Text(
                              orderContextLabel(value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          orderContext = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Σημειώσεις',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      final qty = int.tryParse(quantity.text);
                      final shipping = parseCents(shippingCost.text);

                      if (qty == null || qty <= 0 || shipping == null) {
                        return;
                      }

                      final order = OrderItem(
                        id: newId(),
                        customerId: customer.id,
                        productId: product.id,
                        variantId: variant?.id,
                        quantity: qty,
                        shippingCostCents: shipping,
                        shippingMethod: shippingMethod,
                        status: OrderStatus.waitingContact,
                        source: OrderSource.organic,
                        createdAt: DateTime.now(),
                        context: orderContext,
                        notes: notes.text.trim(),
                      );

                      AppStore.create(order);

                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Καταχώρηση παραγγελίας',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openProduct(ProductItem? product) async {
    await Navigator.of(context).push(
      TbnPageRoute<void>(builder: (_) => ProductEditScreen(product: product)),
    );
    if (mounted) setState(() {});
  }
}
