import 'package:flutter/material.dart';

import 'vans.dart';

class VanChoice {
  const VanChoice(this.vanId, this.consumption, this.price);
  final String vanId;
  final double consumption;
  final double? price;
}

/// Διάλογος επιλογής βαν (+ κατανάλωση, + προαιρετικά τιμή diesel).
/// Επιστρέφει null αν ακυρωθεί.
Future<VanChoice?> showVanDialog(
  BuildContext context, {
  required String title,
  required String vanId,
  required double consumption,
  double? price,
}) {
  final cons = TextEditingController(text: consumption.toStringAsFixed(1));
  final priceCtl = TextEditingController(
    text: price == null ? '' : price.toStringAsFixed(2),
  );
  var selected = vanId;
  if (selected != Vans.customId && Vans.byId(selected) == null) {
    selected = Vans.customId;
  }

  return showDialog<VanChoice>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, dialogSetState) {
          final spec = Vans.byId(selected);
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Βαν (9 θέσεων, diesel)',
                    ),
                    items: [
                      for (final v in Vans.all)
                        DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            v.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem(
                        value: Vans.customId,
                        child: Text('Άλλο / χειροκίνητα'),
                      ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      dialogSetState(() {
                        selected = id;
                        final v = Vans.byId(id);
                        if (v != null) {
                          cons.text = Vans.loaded(v).toStringAsFixed(1);
                        }
                      });
                    },
                  ),
                  if (spec != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'WLTP ${spec.wltp.toStringAsFixed(1)} L/100km · '
                        'με φορτίο και 8 άτομα '
                        '≈ ${Vans.loaded(spec).toStringAsFixed(1)} L/100km '
                        '(+15%). Ενδεικτικές τιμές.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cons,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Κατανάλωση',
                      suffixText: 'L/100km',
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Τιμή diesel',
                        suffixText: '€/L',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Ακύρωση'),
              ),
              FilledButton(
                onPressed: () {
                  final c = double.tryParse(cons.text.replaceAll(',', '.'));
                  final p = price == null
                      ? null
                      : double.tryParse(priceCtl.text.replaceAll(',', '.'));
                  if (c == null || c <= 0) return;
                  if (price != null && (p == null || p <= 0)) return;
                  Navigator.pop(dialogContext, VanChoice(selected, c, p));
                },
                child: const Text('Αποθήκευση'),
              ),
            ],
          );
        },
      );
    },
  );
}
