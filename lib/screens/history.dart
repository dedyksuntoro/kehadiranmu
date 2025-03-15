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
      Navigator.pop(context); // Tutup loading setelah selesai
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
              onPressed:
                  (_startDate != null || _endDate != null)
                      ? _clearDateRange
                      : null, // Disable jika tidak ada filter
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

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(
                          dateFormat.format(DateTime.parse(absensi.tanggal)),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shift: ${absensi.shift.capitalize()}'),
                            Text(
                              'Masuk: ${absensi.waktuMasuk != null ? timeFormat.format(absensi.waktuMasuk!) : "Belum absen"}',
                            ),
                            Text(
                              'Keluar: ${absensi.waktuKeluar != null ? timeFormat.format(absensi.waktuKeluar!) : "Belum absen"}',
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  child: Text(
                                    'Lokasi Masuk: ${absensi.lokasiMasuk} ',
                                  ),
                                  onTap:
                                      () => _showMapDialog(
                                        context,
                                        absensi.latitude,
                                        absensi.longitude,
                                        'Lokasi Masuk',
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (absensi.latitudeKeluar == null &&
                                    absensi.longitudeKeluar == null)
                                  Text(
                                    'Lokasi Keluar: ${absensi.lokasiKeluar} ',
                                  ),
                                if (absensi.latitudeKeluar != null &&
                                    absensi.longitudeKeluar != null)
                                  GestureDetector(
                                    child: Text(
                                      'Lokasi Keluar: ${absensi.lokasiKeluar} ',
                                    ),
                                    onTap:
                                        () => _showMapDialog(
                                          context,
                                          absensi.latitudeKeluar!,
                                          absensi.longitudeKeluar!,
                                          'Lokasi Keluar',
                                        ),
                                  ),
                              ],
                            ),
                            Text(
                              'Status: ${absensi.statusTelat.capitalize() ?? "Tidak diketahui"}',
                            ),
                          ],
                        ),
                        trailing:
                            absensi.fotoPath.isNotEmpty
                                ? Image.network(
                                  'http://10.0.2.2/api_kehadiranmu${absensi.fotoPath}',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Icon(Icons.broken_image),
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
