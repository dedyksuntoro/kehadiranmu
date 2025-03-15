class User {
  final String id;
  final String nama;
  final String email;
  final String role;
  final String token;
  final String? refreshToken;

  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'karyawan',
      token: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }
}
