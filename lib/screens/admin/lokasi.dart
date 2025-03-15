import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/loading_dialog.dart';
import '../../models/lokasi.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LokasiScreen extends StatefulWidget {
  const LokasiScreen({super.key});

  @override
  _LokasiScreenState createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchLokasi();
    });
  }

  Future<void> _fetchLokasi() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showLoadingDialog(context, 'Memproses data...');
    final success = await authProvider.fetchLokasi();
    Navigator.pop(context);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar lokasi')));
    }
  }

  Future<void> _showLokasiDialog({Lokasi? lokasi}) async {
    final namaController = TextEditingController(
      text: lokasi?.namaLokasi ?? '',
    );
    final latitudeController = TextEditingController(
      text: lokasi?.latitude.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: lokasi?.longitude.toString() ?? '',
    );
    final radiusController = TextEditingController(
      text: lokasi?.radius.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lokasi == null ? 'Tambah Lokasi' : 'Edit Lokasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Lokasi'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: latitudeController,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Latitude'),
                onTap: () async {
                  final selectedCoords = await _showMapDialog(
                    initialPosition: latlng.LatLng(
                      double.tryParse(latitudeController.text) ?? -6.2088,
                      double.tryParse(longitudeController.text) ?? 106.8456,
                    ),
                  );
                  if (selectedCoords != null) {
                    latitudeController.text =
                        selectedCoords.latitude.toString();
                    longitudeController.text =
                        selectedCoords.longitude.toString();
                  }
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: longitudeController,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Longitude'),
                onTap: () async {
                  final selectedCoords = await _showMapDialog(
                    initialPosition: latlng.LatLng(
                      double.tryParse(latitudeController.text) ?? -6.2088,
                      double.tryParse(longitudeController.text) ?? 106.8456,
                    ),
                  );
                  if (selectedCoords != null) {
                    latitudeController.text =
                        selectedCoords.latitude.toString();
                    longitudeController.text =
                        selectedCoords.longitude.toString();
                  }
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: radiusController,
                decoration: InputDecoration(labelText: 'Radius (meter)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final namaLokasi = namaController.text.trim();
                final latitudeStr = latitudeController.text.trim();
                final longitudeStr = longitudeController.text.trim();
                final radiusStr = radiusController.text.trim();

                if (namaLokasi.isEmpty ||
                    latitudeStr.isEmpty ||
                    longitudeStr.isEmpty ||
                    radiusStr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                final latitude = double.tryParse(latitudeStr);
                final longitude = double.tryParse(longitudeStr);
                final radius = int.tryParse(radiusStr);

                if (latitude == null || longitude == null || radius == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Latitude, Longitude, dan Radius harus berupa angka',
                      ),
                    ),
                  );
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                showLoadingDialog(
                  context,
                  lokasi == null
                      ? 'Menambahkan lokasi...'
                      : 'Memperbarui lokasi...',
                );
                bool success;
                if (lokasi == null) {
                  success = await authProvider.createLokasi(
                    namaLokasi,
                    latitude,
                    longitude,
                    radius,
                  );
                } else {
                  success = await authProvider.updateLokasi(
                    lokasi.id,
                    namaLokasi,
                    latitude,
                    longitude,
                    radius,
                  );
                }
                Navigator.pop(context); // Tutup loading

                if (success) {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lokasi == null
                            ? 'Lokasi berhasil dibuat'
                            : 'Lokasi berhasil diperbarui',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lokasi == null
                            ? 'Gagal membuat lokasi'
                            : 'Gagal memperbarui lokasi',
                      ),
                    ),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<latlng.LatLng?> _showMapDialog({
    required latlng.LatLng initialPosition,
  }) async {
    final searchController = TextEditingController();
    MapController mapController = MapController();
    latlng.LatLng? selectedPosition = initialPosition;

    return await showDialog<latlng.LatLng>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Pilih Lokasi di Peta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari Lokasi',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () async {
                          final query = searchController.text.trim();
                          if (query.isNotEmpty) {
                            try {
                              final url = Uri.parse(
                                'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
                              );
                              final response = await http.get(
                                url,
                                headers: {'User-Agent': 'Kehadiranmu-App'},
                              );
                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                if (data.isNotEmpty) {
                                  final newLat = double.parse(data[0]['lat']);
                                  final newLon = double.parse(data[0]['lon']);
                                  final newPosition = latlng.LatLng(
                                    newLat,
                                    newLon,
                                  );
                                  setStateDialog(() {
                                    selectedPosition = newPosition;
                                  });
                                  mapController.move(newPosition, 15);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lokasi tidak ditemukan'),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal mencari lokasi'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error pencarian: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: selectedPosition!,
                        initialZoom: 15,
                        onTap: (tapPosition, point) {
                          setStateDialog(() {
                            selectedPosition = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: selectedPosition!,
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedPosition),
                  child: Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Lokasi lokasi) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.lokasiList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa menghapus lokasi terakhir')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus lokasi "${lokasi.namaLokasi}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                showLoadingDialog(context, 'Menghapus lokasi...');
                final success = await authProvider.deleteLokasi(lokasi.id);
                Navigator.pop(context); // Tutup loading

                if (success) {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lokasi berhasil dihapus')),
                  );
                } else {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus lokasi')),
                  );
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Lokasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showLokasiDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLokasi,
        child:
            authProvider.lokasiList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                    child: Center(child: Text('Belum ada data lokasi')),
                  ),
                )
                : ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: authProvider.lokasiList.length,
                  itemBuilder: (context, index) {
                    final lokasi = authProvider.lokasiList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text('Lokasi: ${lokasi.namaLokasi}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latitude: ${lokasi.latitude}'),
                            Text('Longitude: ${lokasi.longitude}'),
                            Text('Radius: ${lokasi.radius} m'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed:
                                  () => _showLokasiDialog(lokasi: lokasi),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(lokasi),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
