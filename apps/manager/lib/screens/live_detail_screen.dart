import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/image_utils.dart';
import '../core/models.dart';
import '../core/money.dart';
import '../core/place_widgets.dart';
import '../core/places.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

class LiveDetailScreen extends StatefulWidget {
  const LiveDetailScreen({
    super.key,
    required this.live,
    this.isNew = false,
  });

  final LiveItem live;

  /// A live that does not exist on the server yet: Save creates it.
  final bool isNew;

  @override
  State<LiveDetailScreen> createState() => _LiveDetailScreenState();
}

class _LiveDetailScreenState extends State<LiveDetailScreen> {
  late final TextEditingController venue;
  late PlaceValue place;
  late final TextEditingController mainAct;
  late final TextEditingController support;
  late final TextEditingController contactPerson;
  late final TextEditingController soundEngineer;
  late final TextEditingController doorDeal;
  late final TextEditingController fixAmount;
  late final TextEditingController merchIncome;
  late final TextEditingController soundEngineerFee;
  late final TextEditingController technicianFee;
  late final TextEditingController supportBandFee;
  late final TextEditingController ticketsPresale;
  late final TextEditingController ticketsDoor;
  late final TextEditingController generalInfo;
  late final TextEditingController ticketUrl;

  late DateTime liveDate;
  bool _saving = false;
  Uint8List? _pendingPoster;
  late LiveStatus status;
  String? tourId;

  @override
  void initState() {
    super.initState();
    final live = widget.live;
    venue = TextEditingController(text: live.venue);
    place = Places.valueOf(live);
    Places.ensureLoaded().then((_) {
      if (mounted) setState(() => place = Places.valueOf(live));
    });
    mainAct = TextEditingController(text: live.mainAct);
    support = TextEditingController(text: live.support);
    contactPerson = TextEditingController(text: live.contactPerson);
    soundEngineer = TextEditingController(text: live.soundEngineer);
    doorDeal = TextEditingController(
      text: centsToInput(live.doorDealCents),
    );
    fixAmount = TextEditingController(
      text: centsToInput(live.fixCents),
    );
    merchIncome = TextEditingController(
      text: centsToInput(live.merchIncomeCents),
    );
    soundEngineerFee = TextEditingController(
      text: centsToInput(live.soundEngineerFeeCents),
    );
    technicianFee = TextEditingController(
      text: centsToInput(live.technicianFeeCents),
    );
    supportBandFee = TextEditingController(
      text: centsToInput(live.supportBandFeeCents),
    );
    ticketsPresale = TextEditingController(
      text: '${live.ticketsPresale}',
    );
    ticketsDoor = TextEditingController(
      text: '${live.ticketsDoor}',
    );
    generalInfo = TextEditingController(text: live.generalInfo);
    ticketUrl = TextEditingController(text: live.ticketUrl ?? '');
    liveDate = live.date;
    status = live.status;
    tourId = live.tourId;
  }

  @override
  void dispose() {
    for (final controller in [
      venue,
      mainAct,
      support,
      contactPerson,
      soundEngineer,
      doorDeal,
      fixAmount,
      merchIncome,
      soundEngineerFee,
      technicianFee,
      supportBandFee,
      ticketsPresale,
      ticketsDoor,
      generalInfo,
      ticketUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.live;
    final canEdit = AppStore.can('bookings', 'write');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Νέο live' : live.venue),
        actions: [
          if (!widget.isNew && AppStore.can('bookings', 'delete'))
            IconButton(
              tooltip: 'Διαγραφή live',
              onPressed: _confirmDelete,
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canEdit) const ReadOnlyBanner(),
          _contextBanner(),
          _section(
            'Βασικά στοιχεία',
            [
              _field(venue, 'Venue'),
              PlaceFields(
                value: place,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 10),
              _field(mainAct, 'Main Act'),
              _field(support, 'Support'),
              _field(contactPerson, 'Contact Person'),
              _field(soundEngineer, 'Ηχολήπτης'),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ημερομηνία',
                    prefixIcon: Icon(Icons.event_rounded),
                    suffixIcon: Icon(Icons.edit_calendar_rounded),
                  ),
                  child: Text(_date(liveDate)),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<LiveStatus>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: LiveStatus.values
                    .map(
                      (value) => DropdownMenuItem<LiveStatus>(
                        value: value,
                        child: Text(
                          liveStatusLabel(value),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: tourId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Tour',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Δεν ανήκει σε Tour'),
                  ),
                  ...AppStore.tours.map(
                    (tour) => DropdownMenuItem<String>(
                      value: tour.id,
                      child: Text(tour.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    tourId = value == null || value.isEmpty ? null : value;
                  });
                },
              ),
            ],
          ),
          _section(
            'Έσοδα',
            [
              _field(
                doorDeal,
                'Door Deal Amount',
                numeric: true,
              ),
              _field(
                fixAmount,
                'Fix Amount',
                numeric: true,
              ),
              _field(
                merchIncome,
                'Merch Income',
                numeric: true,
              ),
              _calculationRow(
                'Total Income',
                live.totalIncomeCents,
                TbnColors.success,
              ),
            ],
          ),
          _section(
            'Έξοδα',
            [
              _field(
                soundEngineerFee,
                'Αμοιβή ηχολήπτη',
                numeric: true,
              ),
              _field(
                technicianFee,
                'Αμοιβή τεχνικού',
                numeric: true,
              ),
              _field(
                supportBandFee,
                'Αμοιβή Support Bands',
                numeric: true,
              ),
              _calculationRow(
                'Total Expenses',
                live.totalExpensesCents,
                TbnColors.danger,
              ),
            ],
          ),
          _section(
            'Εισιτήρια',
            [
              _field(
                ticketsPresale,
                'Tickets Presale Amount',
                integer: true,
              ),
              _field(
                ticketsDoor,
                'Tickets Door Amount',
                integer: true,
              ),
              ListTile(
                title: const Text('Tickets Total Amount'),
                trailing: Text(
                  '${_int(ticketsPresale.text) + _int(ticketsDoor.text)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          _section(
            'Site',
            [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _posterPreview(live) == null
                          ? const ColoredBox(
                              color: Colors.black26,
                              child: Icon(Icons.image_outlined),
                            )
                          : Image(image: _posterPreview(live)!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canEdit ? _pickPoster : null,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(_posterPreview(live) == null ? 'Ανέβασμα αφίσας' : 'Αλλαγή αφίσας'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ticketUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link εισιτηρίων (https://…)',
                  helperText: 'Τα επιβεβαιωμένα lives εμφανίζονται αυτόματα στο thebonnienettles.com',
                ),
              ),
            ],
          ),
          _section(
            'General Info',
            [
              TextField(
                controller: generalInfo,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Σημειώσεις / General Info',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Αποθήκευση αλλαγών'),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    bool integer = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: integer
            ? TextInputType.number
            : numeric
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                  )
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
        ),
        onChanged: (_) {
          if (numeric || integer) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _calculationRow(
    String label,
    int value,
    Color color,
  ) {
    final preview = label == 'Total Income'
        ? _money(doorDeal.text) + _money(fixAmount.text) + _money(merchIncome.text)
        : _money(soundEngineerFee.text) + _money(technicianFee.text) + _money(supportBandFee.text);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        formatCents(preview),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: liveDate,
    );
    if (picked != null) {
      setState(() {
        liveDate = picked;
      });
    }
  }

  Widget _contextBanner() {
    final t = Theme.of(context).textTheme;
    final color = liveStatusColor(status);
    final placeText = [place.city.trim(), place.countryName.trim()].where((e) => e.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          IconChip(icon: Icons.mic_none_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveStatusSectionTitle(status).toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  venue.text.trim().isEmpty ? 'Live' : venue.text.trim(),
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${placeText.isEmpty ? '' : '$placeText · '}${_date(liveDate)}',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final live = widget.live;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Διαγραφή live;'),
          content: Text(
            'Το live «${live.venue}» θα διαγραφεί οριστικά, μαζί με '
            'τα οικονομικά του στοιχεία. Η ενέργεια δεν αναιρείται.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: TbnColors.danger,
              ),
              child: const Text('Διαγραφή'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) {
      return;
    }

    Navigator.of(context).pop();
    await AppStore.remove(live);
  }

  Future<void> _save() async {
    final live = widget.live;
    if (venue.text.trim().isEmpty || place.city.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Συμπλήρωσε venue και πόλη.')),
      );
      return;
    }
    final invalid = [doorDeal, fixAmount, merchIncome, soundEngineerFee, technicianFee, supportBandFee]
        .where((c) => c.text.trim().isNotEmpty && parseCents(c.text) == null);
    final link = ticketUrl.text.trim();
    if (link.isNotEmpty && !(Uri.tryParse(link)?.isAbsolute == true && link.startsWith('http'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Το link εισιτηρίων πρέπει να ξεκινά με https://')),
      );
      return;
    }
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Μη έγκυρο ποσό. Π.χ. 120 ή 120,50')),
      );
      return;
    }

    setState(() {
      live.venue = venue.text.trim();
      live.city = place.city.trim();
      live.country = place.countryName.trim();
      live.countryCode = place.countryCode;
      live.lat = place.lat;
      live.lon = place.lon;
      live.mainAct = mainAct.text.trim();
      live.support = support.text.trim();
      live.contactPerson = contactPerson.text.trim();
      live.soundEngineer = soundEngineer.text.trim();
      live.date = liveDate;
      live.status = status;
      live.tourId = tourId;
      live.doorDealCents = _money(doorDeal.text);
      live.fixCents = _money(fixAmount.text);
      live.merchIncomeCents = _money(merchIncome.text);
      live.soundEngineerFeeCents = _money(soundEngineerFee.text);
      live.technicianFeeCents = _money(technicianFee.text);
      live.supportBandFeeCents = _money(supportBandFee.text);
      live.ticketsPresale = _int(ticketsPresale.text);
      live.ticketsDoor = _int(ticketsDoor.text);
      live.generalInfo = generalInfo.text.trim();
      live.ticketUrl = ticketUrl.text.trim().isEmpty ? null : ticketUrl.text.trim();
    });

    if (widget.isNew) {
      setState(() => _saving = true);
      final created = await AppStore.create(live);
      if (created && _pendingPoster != null) {
        await AppStore.uploadLivePoster(live, _pendingPoster!, 'poster.jpg');
      }
      if (!mounted) return;
      setState(() => _saving = false);
      if (!created) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Το live δημιουργήθηκε.')),
      );
      Navigator.of(context).pop();
      return;
    }

    final saved = await AppStore.update(live);
    if (!saved || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Οι αλλαγές αποθηκεύτηκαν.'),
      ),
    );
  }

  int _money(String value) => parseCents(value) ?? 0;

  ImageProvider? _posterPreview(LiveItem live) =>
      _pendingPoster != null ? MemoryImage(_pendingPoster!) : imageProviderFromRef(live.posterUrl);

  Future<void> _pickPoster() async {
    final XFile? image;
    final Uint8List bytes;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;
      bytes = await image.readAsBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Δεν ήταν δυνατή η επιλογή εικόνας: $e')),
        );
      }
      return;
    }
    if (widget.isNew) {
      // Uploaded right after the live is created (Save).
      setState(() => _pendingPoster = bytes);
      return;
    }
    final url = await AppStore.uploadLivePoster(widget.live, bytes, 'poster.jpg');
    if (!mounted) return;
    setState(() {});
    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Η αφίσα ανέβηκε.')));
    }
  }

  int _int(String value) {
    return int.tryParse(value) ?? 0;
  }

  String _date(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }
}
