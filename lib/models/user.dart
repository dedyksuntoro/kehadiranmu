class User {
  final int id;
  final String email;
  final String role;
  final String token;
  final String refreshToken;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
    required this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // Default 0 kalau tidak ada
      email: json['email'] ?? '',
      role: json['role'] ?? 'karyawan',
      token: json['access_token'], // Sesuai respons server
      refreshToken: json['refresh_token'],
    );
  }
}