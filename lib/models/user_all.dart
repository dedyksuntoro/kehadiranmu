class UserAll {
  final String id;
  final String nama;
  final String email;
  final String? nomorTelepon; // Ubah ke String? untuk nullable
  final String role;
  final String createdAt;

  UserAll({
    required this.id,
    required this.nama,
    required this.email,
    this.nomorTelepon, // Hilangkan required karena nullable
    required this.role,
    required this.createdAt,
  });

  factory UserAll.fromJson(Map<String, dynamic> json) {
    return UserAll(
      id: json['id'].toString(),
      nama: json['nama'],
      email: json['email'],
      nomorTelepon: json['nomor_telepon'], // Biarkan null jika null
      role: json['role'],
      createdAt: json['created_at'],
    );
  }

  @override
  String toString() => nama; // Untuk tampilan di dropdown
}
