class Absensi {
  final int id;
  final int userId;
  final String tanggal;
  final DateTime? waktuMasuk;
  final DateTime? waktuKeluar;
  final double latitude;
  final double longitude;
  final double? latitudeKeluar;
  final double? longitudeKeluar;
  final String fotoPath;
  final String shift;
  final String tanggalShift;
  final String lokasiMasuk;
  final String? lokasiKeluar;
  final String statusTelat;
  final String namaKaryawan; // Tambah field ini

  Absensi({
    required this.id,
    required this.userId,
    required this.tanggal,
    this.waktuMasuk,
    this.waktuKeluar,
    required this.latitude,
    required this.longitude,
    this.latitudeKeluar,
    this.longitudeKeluar,
    required this.fotoPath,
    required this.shift,
    required this.tanggalShift,
    required this.lokasiMasuk,
    this.lokasiKeluar,
    required this.statusTelat,
    required this.namaKaryawan, // Tambah di konstruktor
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'],
      userId: json['user_id'],
      tanggal: json['tanggal'],
      waktuMasuk: json['waktu_masuk'] != null ? DateTime.parse(json['waktu_masuk']) : null,
      waktuKeluar: json['waktu_keluar'] != null ? DateTime.parse(json['waktu_keluar']) : null,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      latitudeKeluar: json['latitude_keluar'] != null ? double.parse(json['latitude_keluar'].toString()) : null,
      longitudeKeluar: json['longitude_keluar'] != null ? double.parse(json['longitude_keluar'].toString()) : null,
      fotoPath: json['foto_path'],
      shift: json['shift'],
      tanggalShift: json['tanggal_shift'],
      lokasiMasuk: json['lokasi_masuk'],
      lokasiKeluar: json['lokasi_keluar'],
      statusTelat: json['status_telat'],
      namaKaryawan: json['nama_karyawan'] ?? 'Unknown', // Tambah parsing
    );
  }
}