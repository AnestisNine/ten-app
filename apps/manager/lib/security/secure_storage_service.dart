import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _membersKey = 'secure_members_v1';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static Future<void> saveMembers(
    List<MemberProfile> members,
  ) async {
    final payload = members.map(_memberToMap).toList();

    await _storage.write(
      key: _membersKey,
      value: jsonEncode(payload),
    );
  }

  static Future<List<MemberProfile>?> loadMembers() async {
    final raw = await _storage.read(key: _membersKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => _memberFromMap(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteMembers() async {
    await _storage.delete(key: _membersKey);
  }

  static Map<String, dynamic> _memberToMap(
    MemberProfile member,
  ) {
    return <String, dynamic>{
      'id': member.id,
      'role': member.role.name,
      'surname': member.surname,
      'name': member.name,
      'fatherSurname': member.fatherSurname,
      'fatherName': member.fatherName,
      'motherName': member.motherName,
      'birthDate': member.birthDate,
      'birthPlace': member.birthPlace,
      'nationality': member.nationality,
      'address': member.address,
      'mobile': member.mobile,
      'maritalStatus': member.maritalStatus,
      'children': member.children,
      'idNumber': member.idNumber,
      'passport': member.passport,
      'issueDateAndAuthority':
          member.issueDateAndAuthority,
      'ama': member.ama,
      'afm': member.afm,
      'doy': member.doy,
      'amka': member.amka,
      'contactPhone': member.contactPhone,
      'email': member.email,
      'iban': member.iban,
      'bank': member.bank,
    };
  }

  static MemberProfile _memberFromMap(
    Map<String, dynamic> map,
  ) {
    final roleName = map['role'] as String?;
    final role = MemberRole.values.firstWhere(
      (value) => value.name == roleName,
      orElse: () => MemberRole.musician,
    );

    return MemberProfile(
      id: (map['id'] as String?) ?? '',
      role: role,
      surname: (map['surname'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      fatherSurname:
          (map['fatherSurname'] as String?) ?? '',
      fatherName:
          (map['fatherName'] as String?) ?? '',
      motherName:
          (map['motherName'] as String?) ?? '',
      birthDate: (map['birthDate'] as String?) ?? '',
      birthPlace: (map['birthPlace'] as String?) ?? '',
      nationality:
          (map['nationality'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      mobile: (map['mobile'] as String?) ?? '',
      maritalStatus:
          (map['maritalStatus'] as String?) ?? '',
      children: (map['children'] as String?) ?? '',
      idNumber: (map['idNumber'] as String?) ?? '',
      passport: (map['passport'] as String?) ?? '',
      issueDateAndAuthority:
          (map['issueDateAndAuthority'] as String?) ??
              '',
      ama: (map['ama'] as String?) ?? '',
      afm: (map['afm'] as String?) ?? '',
      doy: (map['doy'] as String?) ?? '',
      amka: (map['amka'] as String?) ?? '',
      contactPhone:
          (map['contactPhone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      iban: (map['iban'] as String?) ?? '',
      bank: (map['bank'] as String?) ?? '',
    );
  }
}
