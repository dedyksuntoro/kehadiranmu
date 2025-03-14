class Shift {
  final int id;
  final String shift;
  final String jamMulai; // Format "HH:mm:ss" dari time
  final String jamSelesai;

  Shift({
    required this.id,
    required this.shift,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      shift: json['shift'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
    );
  }
}