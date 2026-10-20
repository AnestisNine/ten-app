import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/image_utils.dart';
import '../core/models.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

/// Create or edit a product: name, prices, photo and its sizes, each with its own stock.
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key, this.product});

  /// null = new product.
  final ProductItem? product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _SizeRow {
  _SizeRow({this.id, String label = '', int stock = 0})
      : label = TextEditingController(text: label),
        stock = TextEditingController(text: '$stock');

  /// Existing variant id, or null for a size added on this screen.
  final String? id;
  final TextEditingController label;
  final TextEditingController stock;

  void dispose() {
    label.dispose();
    stock.dispose();
  }
}

const _presets = <String, List<String>>{
  'Χωρίς μέγεθος': ['One size'],
  'S – XL': ['S', 'M', 'L', 'XL'],
  'XS – XXL': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
};

class _ProductEditScreenState extends State<ProductEditScreen> {
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController cost;
  final rows = <_SizeRow>[];
  Uint8List? _newImage;
  bool _saving = false;

  bool get isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    price = TextEditingController(text: p == null ? '' : centsToInput(p.salePriceCents));
    cost = TextEditingController(text: p == null ? '' : centsToInput(p.unitCostCents));
    if (p != null) {
      for (final v in AppStore.variantsOf(p.id)) {
        rows.add(_SizeRow(id: v.id, label: v.label, stock: v.stock));
      }
    }
    if (rows.isEmpty) rows.add(_SizeRow(label: 'One size'));
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _applyPreset(List<String> labels) {
    setState(() {
      // Keep the stock already typed for sizes that stay.
      final old = {for (final r in rows) r.label.text.trim(): r};
      final next = <_SizeRow>[];
      for (final l in labels) {
        next.add(old.remove(l) ?? _SizeRow(label: l));
      }
      // Sizes that already exist on the server are kept (remove them one by one if needed).
      next.addAll(old.values.where((r) => r.id != null));
      for (final r in old.values.where((r) => r.id == null)) {
        r.dispose();
      }
      rows
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() => _newImage = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Δεν ήταν δυνατή η επιλογή εικόνας: $e')));
      }
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    final salePrice = parseCents(price.text);
    final unitCost = cost.text.trim().isEmpty ? 0 : parseCents(cost.text);
    if (name.text.trim().isEmpty) return _toast('Γράψε όνομα προϊόντος.');
    if (salePrice == null || salePrice < 0) return _toast('Μη έγκυρη τιμή πώλησης. Π.χ. 20 ή 19,50');
    if (unitCost == null || unitCost < 0) return _toast('Μη έγκυρο κόστος.');
    final sizes = <(String?, String, int)>[];
    final seen = <String>{};
    for (final r in rows) {
      final label = r.label.text.trim();
      final stock = int.tryParse(r.stock.text.trim());
      if (label.isEmpty) return _toast('Κάθε μέγεθος χρειάζεται όνομα (π.χ. M).');
      if (stock == null || stock < 0) return _toast('Μη έγκυρο stock για το μέγεθος $label.');
      if (!seen.add(label.toLowerCase())) return _toast('Το μέγεθος $label υπάρχει δύο φορές.');
      sizes.add((r.id, label, stock));
    }
    if (sizes.isEmpty) return _toast('Πρόσθεσε τουλάχιστον ένα μέγεθος (ή «One size»).');

    setState(() => _saving = true);
    final product = widget.product ?? ProductItem(id: newId(), name: '');
    product
      ..name = name.text.trim()
      ..salePriceCents = salePrice
      ..unitCostCents = unitCost;

    var ok = isNew ? await AppStore.create(product) : await AppStore.update(product);
    if (ok) {
      final keep = sizes.map((s) => s.$1).whereType<String>().toSet();
      for (final v in AppStore.variantsOf(product.id).where((v) => !keep.contains(v.id))) {
        ok &= await AppStore.remove(v);
      }
      for (var i = 0; i < sizes.length; i++) {
        final (id, label, stock) = sizes[i];
        final existing = AppStore.variantById(id);
        if (existing == null) {
          ok &= await AppStore.create(
            ProductVariant(id: newId(), productId: product.id, label: label, stock: stock, sortOrder: i),
          );
        } else if (existing.label != label || existing.stock != stock || existing.sortOrder != i) {
          existing
            ..label = label
            ..stock = stock
            ..sortOrder = i;
          ok &= await AppStore.update(existing);
        }
      }
      if (_newImage != null) {
        ok &= await AppStore.uploadProductImage(product, _newImage!, 'product.jpg') != null;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _toast(isNew ? 'Το προϊόν δημιουργήθηκε.' : 'Οι αλλαγές αποθηκεύτηκαν.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final product = widget.product!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Διαγραφή προϊόντος;'),
        content: Text('Το «${product.name}» και τα μεγέθη του θα διαγραφούν. '
            'Δεν γίνεται αν υπάρχουν παραγγελίες για αυτό.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: TbnColors.danger),
            child: const Text('Διαγραφή'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await AppStore.remove(product)) {
      AppStore.productVariants.removeWhere((v) => v.productId == product.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AppStore.can('merch', 'write');
    final t = Theme.of(context).textTheme;
    final image = _newImage != null ? MemoryImage(_newImage!) : imageProviderFromRef(widget.product?.imageUrl);
    final total = rows.fold<int>(0, (sum, r) => sum + (int.tryParse(r.stock.text.trim()) ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Νέο προϊόν' : widget.product!.name),
        actions: [
          if (!isNew && AppStore.can('merch', 'delete'))
            IconButton(
              tooltip: 'Διαγραφή',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: TbnColors.danger,
            ),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Αποθήκευση'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canEdit) const ReadOnlyBanner(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: canEdit ? _pickImage : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: image == null
                                ? ColoredBox(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.add_a_photo_outlined, size: 30),
                                  )
                                : Image(image: image, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: name,
                          enabled: canEdit,
                          decoration: const InputDecoration(labelText: 'Όνομα προϊόντος'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: price,
                          enabled: canEdit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Τιμή πώλησης', suffixText: '€'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cost,
                          enabled: canEdit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Κόστος / τεμ.', suffixText: '€'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Μεγέθη & stock', style: t.titleMedium)),
                      Text('Σύνολο: $total τεμ.', style: t.bodySmall),
                    ],
                  ),
                  if (canEdit) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in _presets.entries)
                          ActionChip(label: Text(e.key), onPressed: () => _applyPreset(e.value)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: r.label,
                              enabled: canEdit,
                              decoration: const InputDecoration(labelText: 'Μέγεθος'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: r.stock,
                              enabled: canEdit,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(labelText: 'Stock'),
                            ),
                          ),
                          if (canEdit)
                            IconButton(
                              tooltip: 'Αφαίρεση μεγέθους',
                              onPressed: rows.length == 1
                                  ? null
                                  : () => setState(() {
                                        rows.remove(r);
                                        r.dispose();
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                        ],
                      ),
                    ),
                  if (canEdit)
                    TextButton.icon(
                      onPressed: () => setState(() => rows.add(_SizeRow())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Μέγεθος'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
