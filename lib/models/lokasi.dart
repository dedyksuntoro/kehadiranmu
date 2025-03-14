class Lokasi {
  final int id;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final int radius;

  Lokasi({
    required this.id,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory Lokasi.fromJson(Map<String, dynamic> json) {
    return Lokasi(
      id: json['id'],
      namaLokasi: json['nama_lokasi'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: int.parse(json['radius'].toString()),
    );
  }
}
