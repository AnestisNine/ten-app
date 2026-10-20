import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

import '../core/file_export.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final Set<String> selectedMemberIds = <String>{};
  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectionMode
              ? '${selectedMemberIds.length} επιλεγμένα'
              : 'Μέλη',
        ),
        actions: [
          if (selectionMode)
            IconButton(
              tooltip: 'Export επιλεγμένων σε Excel',
              onPressed: selectedMemberIds.isEmpty
                  ? null
                  : _exportSelectedMembers,
              icon: const Icon(Icons.table_view_outlined),
            ),
          if (selectionMode)
            IconButton(
              tooltip: 'Ακύρωση επιλογής',
              onPressed: () {
                setState(() {
                  selectionMode = false;
                  selectedMemberIds.clear();
                });
              },
              icon: const Icon(Icons.close),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Μέλος'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!selectionMode)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: const IconChip(
                  icon: Icons.groups_2_outlined,
                  size: 40,
                ),
                title: const Text('Αποστολή για επόμενο Live'),
                subtitle: const Text(
                  'Επίλεξε μέλη και κάνε export σε Excel '
                  '(ή κράτα πατημένο ένα μέλος).',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      selectionMode = true;
                    });
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                  ),
                  child: const Text('Επιλογή'),
                ),
              ),
            ),
          const SectionLabel('Μέλη'),
          ...AppStore.members.map((member) {
            final selected = selectedMemberIds.contains(member.id);
            final t = Theme.of(context).textTheme;

            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selected
                      ? TbnColors.accent
                      : Theme.of(context).colorScheme.outline,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (selectionMode) {
                    _toggleMember(member.id);
                  } else {
                    _showMember(member);
                  }
                },
                onLongPress: () {
                  setState(() {
                    selectionMode = true;
                    selectedMemberIds.add(member.id);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (selectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? TbnColors.accent
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            TbnColors.accent.withValues(alpha: 0.15),
                        foregroundColor: TbnColors.accent,
                        child: Text(
                          member.name.isEmpty
                              ? '?'
                              : member.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.fullName, style: t.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              member.mobile.isEmpty
                                  ? memberRoleLabel(member.role)
                                  : '${memberRoleLabel(member.role)}'
                                      ' · ${member.mobile}',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (!selectionMode)
                        Icon(
                          Icons.chevron_right_rounded,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _toggleMember(String id) {
    setState(() {
      if (selectedMemberIds.contains(id)) {
        selectedMemberIds.remove(id);
      } else {
        selectedMemberIds.add(id);
      }
    });
  }

  void _addMember() {
    MemberRole role = MemberRole.musician;

    final fields = <String, TextEditingController>{
      'ΕΠΩΝΥΜΟ': TextEditingController(),
      'ΟΝΟΜΑ': TextEditingController(),
      'ΕΠΩΝΥΜΟ ΠΑΤΡΟΣ': TextEditingController(),
      'ΟΝΟΜΑ ΠΑΤΡΟΣ': TextEditingController(),
      'ΟΝΟΜΑ ΜΗΤΡΟΣ': TextEditingController(),
      'ΗΜΕΡΟΜΗΝΙΑ ΓΕΝΝΗΣΗΣ': TextEditingController(),
      'ΤΟΠΟΣ ΓΕΝΝΗΣΗΣ': TextEditingController(),
      'ΥΠΗΚΟΟΤΗΤΑ': TextEditingController(),
      'ΔΙΕΥΘΥΝΣΗ ΚΑΤΟΙΚΙΑΣ': TextEditingController(),
      'ΚΙΝΗΤΟ ΤΗΛΕΦΩΝΟ': TextEditingController(),
      'ΟΙΚΟΓΕΝΕΙΑΚΗ ΚΑΤΑΣΤΑΣΗ': TextEditingController(),
      'ΑΡΙΘΜΟΣ ΠΑΙΔΙΩΝ': TextEditingController(),
      'Α. ΔΕΛΤΙΟΥ ΤΑΥΤΟΤΗΤΑΣ': TextEditingController(),
      'ΔΙΑΒΑΤΗΡΙΟ': TextEditingController(),
      'ΗΜΕΡΟΜΗΝΙΑ ΕΚΔΟΣΗΣ ΚΑΙ ΑΡΧΗ': TextEditingController(),
      'ΑΡΙΘΜΟΣ ΜΗΤΡΩΟΥ ΙΚΑ / ΑΜΑ': TextEditingController(),
      'ΑΦΜ': TextEditingController(),
      'ΔΟΥ': TextEditingController(),
      'ΑΜΚΑ': TextEditingController(),
      'ΤΗΛΕΦΩΝΟ ΕΠΙΚΟΙΝΩΝΙΑΣ': TextEditingController(),
      'email': TextEditingController(),
      'IBAN': TextEditingController(),
      'Τράπεζα (όνομα τραπέζης)': TextEditingController(),
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: .94,
              maxChildSize: .98,
              builder: (context, controller) {
                return ListView(
                  controller: controller,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                            24,
                  ),
                  children: [
                    const Text(
                      'Νέο μέλος',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<MemberRole>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Ρόλος',
                      ),
                      items: MemberRole.values.map((value) {
                        return DropdownMenuItem<MemberRole>(
                          value: value,
                          child: Text(
                            memberRoleLabel(value),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          modalSetState(() {
                            role = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ...fields.entries.map((entry) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: entry.value,
                          keyboardType:
                              _keyboardFor(entry.key),
                          decoration: InputDecoration(
                            labelText: entry.key,
                          ),
                        ),
                      );
                    }),
                    FilledButton(
                      onPressed: () {
                        if (fields['ΟΝΟΜΑ']!.text.trim().isEmpty &&
                            fields['ΕΠΩΝΥΜΟ']!
                                .text
                                .trim()
                                .isEmpty) {
                          return;
                        }

                        final member = MemberProfile(
                          id: DateTime.now()
                              .microsecondsSinceEpoch
                              .toString(),
                          role: role,
                          surname:
                              fields['ΕΠΩΝΥΜΟ']!.text.trim(),
                          name:
                              fields['ΟΝΟΜΑ']!.text.trim(),
                          fatherSurname: fields[
                                  'ΕΠΩΝΥΜΟ ΠΑΤΡΟΣ']!
                              .text
                              .trim(),
                          fatherName:
                              fields['ΟΝΟΜΑ ΠΑΤΡΟΣ']!
                                  .text
                                  .trim(),
                          motherName:
                              fields['ΟΝΟΜΑ ΜΗΤΡΟΣ']!
                                  .text
                                  .trim(),
                          birthDate: fields[
                                  'ΗΜΕΡΟΜΗΝΙΑ ΓΕΝΝΗΣΗΣ']!
                              .text
                              .trim(),
                          birthPlace:
                              fields['ΤΟΠΟΣ ΓΕΝΝΗΣΗΣ']!
                                  .text
                                  .trim(),
                          nationality:
                              fields['ΥΠΗΚΟΟΤΗΤΑ']!
                                  .text
                                  .trim(),
                          address: fields[
                                  'ΔΙΕΥΘΥΝΣΗ ΚΑΤΟΙΚΙΑΣ']!
                              .text
                              .trim(),
                          mobile:
                              fields['ΚΙΝΗΤΟ ΤΗΛΕΦΩΝΟ']!
                                  .text
                                  .trim(),
                          maritalStatus: fields[
                                  'ΟΙΚΟΓΕΝΕΙΑΚΗ ΚΑΤΑΣΤΑΣΗ']!
                              .text
                              .trim(),
                          children:
                              fields['ΑΡΙΘΜΟΣ ΠΑΙΔΙΩΝ']!
                                  .text
                                  .trim(),
                          idNumber: fields[
                                  'Α. ΔΕΛΤΙΟΥ ΤΑΥΤΟΤΗΤΑΣ']!
                              .text
                              .trim(),
                          passport:
                              fields['ΔΙΑΒΑΤΗΡΙΟ']!
                                  .text
                                  .trim(),
                          issueDateAndAuthority: fields[
                                  'ΗΜΕΡΟΜΗΝΙΑ ΕΚΔΟΣΗΣ ΚΑΙ ΑΡΧΗ']!
                              .text
                              .trim(),
                          ama: fields[
                                  'ΑΡΙΘΜΟΣ ΜΗΤΡΩΟΥ ΙΚΑ / ΑΜΑ']!
                              .text
                              .trim(),
                          afm: fields['ΑΦΜ']!
                              .text
                              .trim(),
                          doy: fields['ΔΟΥ']!
                              .text
                              .trim(),
                          amka: fields['ΑΜΚΑ']!
                              .text
                              .trim(),
                          contactPhone: fields[
                                  'ΤΗΛΕΦΩΝΟ ΕΠΙΚΟΙΝΩΝΙΑΣ']!
                              .text
                              .trim(),
                          email: fields['email']!
                              .text
                              .trim(),
                          iban: fields['IBAN']!
                              .text
                              .trim(),
                          bank: fields[
                                  'Τράπεζα (όνομα τραπέζης)']!
                              .text
                              .trim(),
                        );

                        setState(() {
                          AppStore.members.add(member);
                        });
                        AppStore.log(
                          'Members',
                          'Προστέθηκε μέλος: '
                          '${member.fullName}',
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Αποθήκευση μέλους'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  TextInputType _keyboardFor(String field) {
    if (field.contains('ΤΗΛΕΦΩΝΟ') ||
        field == 'ΑΡΙΘΜΟΣ ΠΑΙΔΙΩΝ') {
      return TextInputType.phone;
    }
    if (field == 'email') {
      return TextInputType.emailAddress;
    }
    return TextInputType.text;
  }

  void _showMember(MemberProfile member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final values = <String, String>{
          'ΡΟΛΟΣ': memberRoleLabel(member.role),
          'ΕΠΩΝΥΜΟ': member.surname,
          'ΟΝΟΜΑ': member.name,
          'ΕΠΩΝΥΜΟ ΠΑΤΡΟΣ': member.fatherSurname,
          'ΟΝΟΜΑ ΠΑΤΡΟΣ': member.fatherName,
          'ΟΝΟΜΑ ΜΗΤΡΟΣ': member.motherName,
          'ΗΜΕΡΟΜΗΝΙΑ ΓΕΝΝΗΣΗΣ': member.birthDate,
          'ΤΟΠΟΣ ΓΕΝΝΗΣΗΣ': member.birthPlace,
          'ΥΠΗΚΟΟΤΗΤΑ': member.nationality,
          'ΔΙΕΥΘΥΝΣΗ ΚΑΤΟΙΚΙΑΣ': member.address,
          'ΚΙΝΗΤΟ ΤΗΛΕΦΩΝΟ': member.mobile,
          'ΟΙΚΟΓΕΝΕΙΑΚΗ ΚΑΤΑΣΤΑΣΗ':
              member.maritalStatus,
          'ΑΡΙΘΜΟΣ ΠΑΙΔΙΩΝ': member.children,
          'Α. ΔΕΛΤΙΟΥ ΤΑΥΤΟΤΗΤΑΣ': member.idNumber,
          'ΔΙΑΒΑΤΗΡΙΟ': member.passport,
          'ΗΜΕΡΟΜΗΝΙΑ ΕΚΔΟΣΗΣ ΚΑΙ ΑΡΧΗ':
              member.issueDateAndAuthority,
          'ΑΡΙΘΜΟΣ ΜΗΤΡΩΟΥ ΙΚΑ / ΑΜΑ': member.ama,
          'ΑΦΜ': member.afm,
          'ΔΟΥ': member.doy,
          'ΑΜΚΑ': member.amka,
          'ΤΗΛΕΦΩΝΟ ΕΠΙΚΟΙΝΩΝΙΑΣ':
              member.contactPhone,
          'email': member.email,
          'IBAN': member.iban,
          'Τράπεζα (όνομα τραπέζης)': member.bank,
        };

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .9,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                ...values.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        entry.value.isEmpty ? '—' : entry.value,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportSelectedMembers() async {
    final selectedMembers = AppStore.members
        .where((member) =>
            selectedMemberIds.contains(member.id))
        .toList();

    if (selectedMembers.isEmpty) {
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Αποστολή'];

    sheet.appendRow(
      <CellValue?>[
        TextCellValue('ΡΟΛΟΣ'),
        TextCellValue('ΕΠΩΝΥΜΟ'),
        TextCellValue('ΟΝΟΜΑ'),
        TextCellValue('ΕΠΩΝΥΜΟ ΠΑΤΡΟΣ'),
        TextCellValue('ΟΝΟΜΑ ΠΑΤΡΟΣ'),
        TextCellValue('ΟΝΟΜΑ ΜΗΤΡΟΣ'),
        TextCellValue('ΗΜΕΡΟΜΗΝΙΑ ΓΕΝΝΗΣΗΣ'),
        TextCellValue('ΤΟΠΟΣ ΓΕΝΝΗΣΗΣ'),
        TextCellValue('ΥΠΗΚΟΟΤΗΤΑ'),
        TextCellValue('ΔΙΕΥΘΥΝΣΗ ΚΑΤΟΙΚΙΑΣ'),
        TextCellValue('ΚΙΝΗΤΟ ΤΗΛΕΦΩΝΟ'),
        TextCellValue('ΟΙΚΟΓΕΝΕΙΑΚΗ ΚΑΤΑΣΤΑΣΗ'),
        TextCellValue('ΑΡΙΘΜΟΣ ΠΑΙΔΙΩΝ'),
        TextCellValue('Α. ΔΕΛΤΙΟΥ ΤΑΥΤΟΤΗΤΑΣ'),
        TextCellValue('ΔΙΑΒΑΤΗΡΙΟ'),
        TextCellValue('ΗΜΕΡΟΜΗΝΙΑ ΕΚΔΟΣΗΣ ΚΑΙ ΑΡΧΗ'),
        TextCellValue('ΑΡΙΘΜΟΣ ΜΗΤΡΩΟΥ ΙΚΑ / ΑΜΑ'),
        TextCellValue('ΑΦΜ'),
        TextCellValue('ΔΟΥ'),
        TextCellValue('ΑΜΚΑ'),
        TextCellValue('ΤΗΛΕΦΩΝΟ ΕΠΙΚΟΙΝΩΝΙΑΣ'),
        TextCellValue('email'),
        TextCellValue('IBAN'),
        TextCellValue('Τράπεζα'),
      ],
    );

    for (final member in selectedMembers) {
      sheet.appendRow(
        <CellValue?>[
          TextCellValue(memberRoleLabel(member.role)),
          TextCellValue(member.surname),
          TextCellValue(member.name),
          TextCellValue(member.fatherSurname),
          TextCellValue(member.fatherName),
          TextCellValue(member.motherName),
          TextCellValue(member.birthDate),
          TextCellValue(member.birthPlace),
          TextCellValue(member.nationality),
          TextCellValue(member.address),
          TextCellValue(member.mobile),
          TextCellValue(member.maritalStatus),
          TextCellValue(member.children),
          TextCellValue(member.idNumber),
          TextCellValue(member.passport),
          TextCellValue(member.issueDateAndAuthority),
          TextCellValue(member.ama),
          TextCellValue(member.afm),
          TextCellValue(member.doy),
          TextCellValue(member.amka),
          TextCellValue(member.contactPhone),
          TextCellValue(member.email),
          TextCellValue(member.iban),
          TextCellValue(member.bank),
        ],
      );
    }

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox == null
        ? const Rect.fromLTWH(1, 1, 1, 1)
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;

    await saveAndShareFile(
      bytes: Uint8List.fromList(bytes),
      fileName:
          'TBN_Αποστολή_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'TBN αποστολή',
      text: 'Επιλεγμένα μέλη αποστολής (${selectedMembers.length})',
      shareOrigin: shareOrigin,
    );
  }
}
