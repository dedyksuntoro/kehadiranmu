import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../services/auth_provider.dart';
import '../widgets/loading_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchAbsensi();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMore();
      }
    });
  }

  Future<void> _fetchAbsensi({bool isRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!isRefresh) showLoadingDialog(context, 'Memproses data...');
    final success = await authProvider.fetchAbsensi(
      page: isRefresh ? 1 : _currentPage,
      startDate:
          _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
      endDate:
          _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
    if (!isRefresh) Navigator.pop(context);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat absensi')));
    }
    if (isRefresh) _currentPage = 1;
  }

  Future<void> _loadMore() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_currentPage < authProvider.totalPages && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      _currentPage++;
      await authProvider.fetchAbsensi(
        page: _currentPage,
        startDate:
            _startDate != null
                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                : null,
        endDate:
            _endDate != null
                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                : null,
      );
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showMapDialog(
    BuildContext context,
    double latitude,
    double longitude,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: 400,
            width: 300,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latlong.LatLng(latitude, longitude),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latlong.LatLng(latitude, longitude),
                            width: 80.0,
                            height: 80.0,
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi baru untuk menampilkan gambar yang diperbesar
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.9, // 90% dari lebar layar
            height:
                MediaQuery.of(context).size.height *
                0.6, // 60% dari tinggi layar
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true, // Mengizinkan geser
                    scaleEnabled: true, // Mengizinkan zoom
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );
    if (picked != null) {
      final difference = picked.end.difference(picked.start).inDays;
      if (difference > 31) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rentang tanggal maksimal 1 bulan')),
        );
        return;
      }
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      showLoadingDialog(context, 'Memproses data...');
      await _fetchAbsensi(isRefresh: true);
      Navigator.pop(context);
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    showLoadingDialog(context, 'Memproses data...');
    _fetchAbsensi(isRefresh: true).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Absensi'),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearDateRange,
              tooltip: 'Hapus Filter',
            ),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchAbsensi(isRefresh: true),
        child:
            authProvider.absensiList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                    child: Center(child: Text('Belum ada riwayat absensi')),
                  ),
                )
                : ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount:
                      authProvider.absensiList.length +
                      (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == authProvider.absensiList.length &&
                        _isLoadingMore) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final absensi = authProvider.absensiList[index];
                    final dateFormat = DateFormat('dd MMM yyyy');
                    final timeFormat = DateFormat('HH:mm');
                    final imageUrl =
                        'https://mbl.nipstudio.id/api_kehadiranmu${absensi.fotoPath}';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(
                          dateFormat.format(DateTime.parse(absensi.tanggal)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shift: ${absensi.shift.capitalize()}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Masuk: ${absensi.waktuMasuk != null ? timeFormat.format(absensi.waktuMasuk!) : "Belum absen"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Keluar: ${absensi.waktuKeluar != null ? timeFormat.format(absensi.waktuKeluar!) : "Belum absen"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => _showMapDialog(
                                          context,
                                          absensi.latitude,
                                          absensi.longitude,
                                          'Lokasi Masuk',
                                        ),
                                    child: Text(
                                      'Lokasi Masuk: ${absensi.lokasiMasuk}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      absensi.latitudeKeluar != null &&
                                              absensi.longitudeKeluar != null
                                          ? GestureDetector(
                                            onTap:
                                                () => _showMapDialog(
                                                  context,
                                                  absensi.latitudeKeluar!,
                                                  absensi.longitudeKeluar!,
                                                  'Lokasi Keluar',
                                                ),
                                            child: Text(
                                              'Lokasi Keluar: ${absensi.lokasiKeluar}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                          : Text(
                                            'Lokasi Keluar: ${absensi.lokasiKeluar}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                ),
                              ],
                            ),
                            Text(
                              'Status: ${absensi.statusTelat.capitalize() ?? "Tidak diketahui"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing:
                            absensi.fotoPath.isNotEmpty
                                ? GestureDetector(
                                  onTap:
                                      () => _showImageDialog(context, imageUrl),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 50,
                                      maxHeight: 50,
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.broken_image),
                                    ),
                                  ),
                                )
                                : Icon(Icons.photo),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
