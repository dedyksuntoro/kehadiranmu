
class Absensi {
  final int id;
  final int userId;
  final String tanggal;
  final DateTime? waktuMasuk;
  final DateTime? waktuKeluar;
  final double latitude;
  final double longitude;
  final String fotoPath;
  final DateTime createdAt;
  final String shift;
  final String tanggalShift;
  final double? latitudeKeluar;
  final double? longitudeKeluar;
  final String statusTelat;
  final String lokasiMasuk;
  final String lokasiKeluar;

  Absensi({
    required this.id,
    required this.userId,
    required this.tanggal,
    this.waktuMasuk,
    this.waktuKeluar,
    required this.latitude,
    required this.longitude,
    required this.fotoPath,
    required this.createdAt,
    required this.shift,
    required this.tanggalShift,
    this.latitudeKeluar,
    this.longitudeKeluar,
    required this.statusTelat,
    required this.lokasiMasuk,
    required this.lokasiKeluar,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug
    return Absensi(
      id: json['id'],
      userId: json['user_id'],
      tanggal: json['tanggal'],
      waktuMasuk:
          json['waktu_masuk'] != null
              ? DateTime.parse(json['waktu_masuk'])
              : null,
      waktuKeluar:
          json['waktu_keluar'] != null
              ? DateTime.parse(json['waktu_keluar'])
              : null,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      fotoPath: json['foto_path'] ?? '', // Default kosong kalau null
      createdAt: DateTime.parse(json['created_at']),
      shift: json['shift'],
      tanggalShift: json['tanggal_shift'],
      latitudeKeluar:
          json['latitude_keluar'] != null
              ? double.parse(json['latitude_keluar'].toString())
              : null,
      longitudeKeluar:
          json['longitude_keluar'] != null
              ? double.parse(json['longitude_keluar'].toString())
              : null,
      statusTelat:
          json['status_telat'] ?? 'tidak diketahui', // Dari catatan tambahan
      lokasiMasuk: json['lokasi_masuk'] ?? 'Tidak diketahui',
      lokasiKeluar: json['lokasi_keluar'] ?? 'Tidak diketahui',
    );
  }
}
