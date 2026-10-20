import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'models.dart';
import 'routing.dart';

/// Μικρό στοιχείο: εικονίδιο + τιμή, με περιγραφή (hover / πάτημα).
class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.text, {required this.tip, this.onTap});
  final IconData icon;
  final String text;
  final String tip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
    return Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 4),
      triggerMode:
          onTap == null ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
      child: onTap == null
          ? row
          : InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: row,
              ),
            ),
    );
  }
}

String _fuelTip(double cons, double price) =>
    'Ενδεικτικό κόστος καυσίμου (diesel): χιλιόμετρα × '
    '${cons.toStringAsFixed(1)} L/100km × ${price.toStringAsFixed(2)} €/L';

const _kmTip =
    'Πραγματική απόσταση οδήγησης (όχι ευθεία) από το προηγούμενο live';
const _timeTip = 'Εκτιμώμενος χρόνος οδήγησης, χωρίς στάσεις και κίνηση';
const _tollTip = 'Ενδεικτικά διόδια και βινιέτες για βαν. '
    'Πάτα για να βάλεις το πραγματικό ποσό.';
const _tollManualTip =
    'Διόδια που έβαλες εσύ. Πάτα για αλλαγή ή διαγραφή.';
const _sumTip = 'Καύσιμα + διόδια μαζί';

Future<void> editToll(BuildContext context, String key, double current) async {
  if (key.isEmpty) return;
  final c = TextEditingController(text: current.round().toString());
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Διόδια διαδρομής'),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Ποσό',
          suffixText: '€',
          helperText: 'Ισχύει και για την αντίστροφη διαδρομή',
        ),
      ),
      actions: [
        if (Routing.tollOverride(key) != null)
          TextButton(
            onPressed: () {
              Routing.setTollOverride(key, null);
              Navigator.pop(ctx);
            },
            child: const Text('Αυτόματη εκτίμηση'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Ακύρωση'),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(c.text.replaceAll(',', '.'));
            if (v == null || v < 0) return;
            Routing.setTollOverride(key, v);
            Navigator.pop(ctx);
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    ),
  );
}

String _eur(double v) => '${v.round()}€';

/// "Αθήνα → Τίρανα" + 🛣 km · ⛽ € · 🎫 € για δύο διαδοχικά lives.
class RouteLegRow extends StatefulWidget {
  const RouteLegRow({
    super.key,
    required this.from,
    required this.to,
    this.consumption,
  });
  final LiveItem from;
  final LiveItem to;

  /// L/100km του βαν του tour (null = προεπιλογή Settings).
  final double? consumption;

  @override
  State<RouteLegRow> createState() => _RouteLegRowState();
}

class _RouteLegRowState extends State<RouteLegRow> {
  late Future<RouteInfo?> _future;

  @override
  void initState() {
    super.initState();
    _future = Routing.routeBetween(widget.from, widget.to);
  }

  @override
  void didUpdateWidget(covariant RouteLegRow old) {
    super.didUpdateWidget(old);
    if (old.from.id != widget.from.id ||
        old.to.id != widget.to.id ||
        old.from.city != widget.from.city ||
        old.to.city != widget.to.city ||
        old.from.lat != widget.from.lat ||
        old.to.lat != widget.to.lat) {
      _future = Routing.routeBetween(widget.from, widget.to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.from.city} → ${widget.to.city}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<RouteInfo?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Text(
                  'Υπολογισμός διαδρομής…',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                );
              }
              final r = snap.data;
              if (r == null) {
                return Text(
                  'Επίλεξε πόλη από τη λίστα για υπολογισμό',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                );
              }
              return ValueListenableBuilder<int>(
                valueListenable: Routing.overridesVersion,
                builder: (context, _, __) =>
                    ValueListenableBuilder<double>(
                valueListenable: AppStore.dieselPrice,
                builder: (context, price, _) =>
                    ValueListenableBuilder<double>(
                  valueListenable: AppStore.fuelConsumption,
                  builder: (context, consGlobal, _) {
                    final cons = widget.consumption ?? consGlobal;
                    final c = Routing.cost(r, price, cons);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            _Metric(
                              Icons.route_rounded,
                              '${r.estimate ? '~' : ''}${r.km.round()} km',
                              tip: _kmTip,
                            ),
                            _Metric(
                              Icons.local_gas_station_rounded,
                              '${r.estimate ? '~' : ''}${_eur(c.fuel)}',
                              tip: _fuelTip(cons, price),
                            ),
                            _Metric(
                              Icons.toll_rounded,
                              (r.estimate && !c.manualTolls)
                                  ? '—'
                                  : '${c.manualTolls ? '' : '~'}${_eur(c.tolls)}',
                              tip: c.manualTolls ? _tollManualTip : _tollTip,
                              onTap: () => editToll(context, r.key, c.tolls),
                            ),
                            _Metric(
                              Icons.schedule_rounded,
                              Routing.formatDuration(r.minutes),
                              tip: _timeTip,
                            ),
                          ],
                        ),
                        if (r.estimate || r.ferry)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              r.estimate
                                  ? 'Προσέγγιση (χωρίς σύνδεση με υπηρεσία χαρτών)'
                                  : 'Περιλαμβάνει πλοίο — το εισιτήριο δεν υπολογίζεται',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Σύνολο διαδρομών ενός tour (διαδοχικά lives με ημερομηνία).
class RouteTotals extends StatefulWidget {
  const RouteTotals({super.key, required this.lives, this.consumption});
  final List<LiveItem> lives;
  final double? consumption;

  @override
  State<RouteTotals> createState() => _RouteTotalsState();
}

class _RouteTotalsState extends State<RouteTotals> {
  late Future<List<RouteInfo?>> _future;
  String _sig = '';

  String _signature() => widget.lives
      .map((l) => '${l.id}:${l.city}:${l.lat}:${l.lon}')
      .join('|');

  Future<List<RouteInfo?>> _load() {
    final l = widget.lives;
    return Future.wait([
      for (var i = 0; i < l.length - 1; i++)
        Routing.routeBetween(l[i], l[i + 1]),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _sig = _signature();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant RouteTotals old) {
    super.didUpdateWidget(old);
    final s = _signature();
    if (s != _sig) {
      _sig = s;
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lives.length < 2) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<RouteInfo?>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final routes = snap.data!.whereType<RouteInfo>().toList();
        if (routes.isEmpty) return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: Routing.overridesVersion,
          builder: (context, _, __) => ValueListenableBuilder<double>(
          valueListenable: AppStore.dieselPrice,
          builder: (context, price, _) => ValueListenableBuilder<double>(
            valueListenable: AppStore.fuelConsumption,
            builder: (context, consGlobal, _) {
                    final cons = widget.consumption ?? consGlobal;
              var km = 0.0, fuel = 0.0, tolls = 0.0, min = 0.0;
              for (final r in routes) {
                final c = Routing.cost(r, price, cons);
                km += r.km;
                fuel += c.fuel;
                tolls += c.tolls;
                min += r.minutes;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Διαδρομές tour · καύσιμα + διόδια',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _Metric(
                          Icons.route_rounded,
                          '${km.round()} km',
                          tip: 'Σύνολο χιλιομέτρων οδήγησης όλου του tour '
                              '(από live σε live)',
                        ),
                        _Metric(
                          Icons.local_gas_station_rounded,
                          _eur(fuel),
                          tip: 'Σύνολο ενδεικτικού κόστους καυσίμου tour. '
                              '${_fuelTip(cons, price)}',
                        ),
                        _Metric(
                          Icons.toll_rounded,
                          _eur(tolls),
                          tip: 'Σύνολο ενδεικτικών διοδίων tour. '
                              'Αλλάζεις το ποσό ανά διαδρομή πατώντας στα διόδια της.',
                        ),
                        _Metric(
                          Icons.payments_outlined,
                          'Σύνολο ${_eur(fuel + tolls)}',
                          tip: _sumTip,
                        ),
                        _Metric(
                          Icons.schedule_rounded,
                          Routing.formatDuration(min),
                          tip: _timeTip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ενδεικτικά · diesel ${price.toStringAsFixed(2)} €/L, '
                      '${cons.toStringAsFixed(1)} L/100km',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ),
        );
      },
    );
  }
}
