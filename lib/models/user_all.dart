class UserAll {
  final String id;
  final String nama;
  final String email;
  final String? nomorTelepon;
  final String role;
  final int? shiftId; // Tambahkan shiftId
  final String? shiftName; // Tambahkan shiftName (opsional)
  final DateTime createdAt;

  UserAll({
    required this.id,
    required this.nama,
    required this.email,
    this.nomorTelepon,
    required this.role,
    this.shiftId,
    this.shiftName,
    required this.createdAt,
  });

  factory UserAll.fromJson(Map<String, dynamic> json) {
    return UserAll(
      id: json['id'].toString(),
      nama: json['nama'],
      email: json['email'],
      nomorTelepon: json['nomor_telepon'],
      role: json['role'],
      shiftId: json['shift_id'], // Parsing shift_id
      shiftName: json['shift_name'], // Parsing shift_name
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
