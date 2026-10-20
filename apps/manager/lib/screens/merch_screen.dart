import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../core/image_utils.dart';
import '../core/models.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import 'order_detail_screen.dart';

class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key});

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  int tab = 1;
  final ImagePicker _imagePicker = ImagePicker();

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
                  onPressed: tab == 1 ? _addOrganicOrder : _addProduct,
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
    return Column(
      children: AppStore.products.map((product) {
        final soldOut = product.stock == 0;
        final low = !soldOut && product.stock <= 3;
        final color = soldOut
            ? TbnColors.danger
            : low
                ? TbnColors.warning
                : TbnColors.success;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _thumbnail(product),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: t.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  label: soldOut ? 'Sold out' : '${product.stock} τεμ.',
                  color: color,
                ),
              ],
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
                          '${product?.name ?? '—'} × ${order.quantity}',
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
        return Card(
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
                    ],
                  ),
                ),
                Text(formatEuro(product.salePriceCents), style: t.titleMedium),
              ],
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
                        });
                      }
                    },
                  ),
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

  void _addProduct() {
    final name = TextEditingController();
    final unitCost = TextEditingController();
    final salePrice = TextEditingController();
    final initialStock = TextEditingController(text: '0');
    String? imagePath;
    List<int>? imageBytes;

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
                    'Νέο προϊόν',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 480,
                          maxHeight: 480,
                          imageQuality: 75,
                        );

                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          modalSetState(() {
                            imageBytes = bytes;
                            imagePath = 'data:image/jpeg;base64,'
                                '${base64Encode(bytes)}';
                          });
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: imageProviderFromRef(imagePath) == null
                            ? const Icon(
                                Icons.add_a_photo_outlined,
                                size: 34,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image(
                                  image: imageProviderFromRef(imagePath)!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Όνομα προϊόντος',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unitCost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Κόστος / τεμάχιο',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: salePrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Τιμή πώλησης',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: initialStock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Αρχικό stock',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      final cost = parseCents(unitCost.text);
                      final price = parseCents(salePrice.text);
                      final stock = int.tryParse(initialStock.text);

                      if (name.text.trim().isEmpty || cost == null || price == null || stock == null || stock < 0) {
                        return;
                      }

                      final product = ProductItem(
                        id: newId(),
                        name: name.text.trim(),
                        stock: stock,
                        unitCostCents: cost,
                        salePriceCents: price,
                      );
                      final bytes = imageBytes;
                      AppStore.create(product).then((ok) {
                        if (ok && bytes != null) {
                          AppStore.uploadProductImage(product, bytes, 'product.jpg');
                        }
                      });

                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Δημιουργία προϊόντος',
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
}
