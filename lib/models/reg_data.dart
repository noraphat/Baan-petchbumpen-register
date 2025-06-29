class RegData {
  final String id;        // บัตร/โทร
  final String first;
  final String last;
  final String dob;       // yyyy-MM-dd
  final String phone;
  final String addr;
  final String gender;

  RegData({
    required this.id,
    required this.first,
    required this.last,
    required this.dob,
    required this.phone,
    required this.addr,
    required this.gender,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'first': first,
        'last': last,
        'dob': dob,
        'phone': phone,
        'addr': addr,
        'gender': gender,
      };

  factory RegData.fromMap(Map<String, dynamic> m) => RegData(
        id: m['id'],
        first: m['first'],
        last: m['last'],
        dob: m['dob'],
        phone: m['phone'] ?? '',
        addr: m['addr'] ?? '',
        gender: m['gender'] ?? 'อื่น ๆ',
      );
}
