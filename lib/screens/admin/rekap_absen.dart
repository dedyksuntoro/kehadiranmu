import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../models/user_all.dart';
import '../../services/auth_provider.dart';
import '../../widgets/loading_dialog.dart';

class RekapAbsenScreen extends StatefulWidget {
  const RekapAbsenScreen({super.key});

  @override
  _RekapAbsenScreenState createState() => _RekapAbsenScreenState();
}

class _RekapAbsenScreenState extends State<RekapAbsenScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedShift;
  UserAll? _selectedUser;
  String? _selectedStatusTelat;

  @override
  void initState() {
    super.initState();
    _initializeData(); // Panggil fungsi terpisah
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMore();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return; // Cek mounted sebelum akses context
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchUsers();
    if (mounted) await _fetchRekap(); // Hanya lanjutkan jika masih mounted
  }

  Future<void> _fetchRekap({bool isRefresh = false}) async {
    if (!mounted) return; // Cek mounted sebelum akses context
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!isRefresh) showLoadingDialog(context, 'Memproses data...');
    try {
      final success = await authProvider.fetchAllAbsensi(
        page: isRefresh ? 1 : _currentPage,
        tanggalAwal:
            _startDate != null
                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                : null,
        tanggalAkhir:
            _endDate != null
                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                : null,
        shift: _selectedShift,
        userId: _selectedUser != null ? int.parse(_selectedUser!.id) : null,
        statusTelat: _selectedStatusTelat,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat rekap absensi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (!isRefresh && mounted) {
        Navigator.pop(context);
      }
    }
    if (isRefresh) _currentPage = 1;
  }

  Future<void> _loadMore() async {
    if (!mounted) return; // Cek mounted
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_currentPage < authProvider.totalPages && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      _currentPage++;
      await authProvider.fetchAllAbsensi(
        page: _currentPage,
        tanggalAwal:
            _startDate != null
                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                : null,
        tanggalAkhir:
            _endDate != null
                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                : null,
        shift: _selectedShift,
        userId: _selectedUser != null ? int.parse(_selectedUser!.id) : null,
        statusTelat: _selectedStatusTelat,
      );
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
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

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
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
      await _fetchRekap(isRefresh: true);
      if (mounted) Navigator.pop(context);
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    showLoadingDialog(context, 'Memproses data...');
    _fetchRekap(isRefresh: true).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempShift = _selectedShift;
        UserAll? tempUser = _selectedUser;
        String? tempStatusTelat = _selectedStatusTelat;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Filter Rekap Absensi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tempShift,
                      decoration: InputDecoration(labelText: 'Shift'),
                      items:
                          ['pagi', 'siang', 'malam']
                              .map(
                                (shift) => DropdownMenuItem(
                                  value: shift,
                                  child: Text(shift.capitalize()),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setStateDialog(() => tempShift = value),
                    ),
                    SizedBox(height: 10),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return DropdownSearch<UserAll>(
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                labelText: 'Cari Karyawan',
                              ),
                            ),
                          ),
                          items: authProvider.userList,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Karyawan',
                            ),
                          ),
                          onChanged:
                              (value) => setStateDialog(() => tempUser = value),
                          selectedItem: tempUser,
                          itemAsString: (user) => user.nama,
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempStatusTelat,
                      decoration: InputDecoration(labelText: 'Status Telat'),
                      items:
                          ['telat', 'tepat waktu']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.capitalize()),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              setStateDialog(() => tempStatusTelat = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedShift = null;
                      _selectedUser = null;
                      _selectedStatusTelat = null;
                    });
                    Navigator.pop(context);
                    _fetchRekap(isRefresh: true);
                  },
                  child: Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedShift = tempShift;
                      _selectedUser = tempUser;
                      _selectedStatusTelat = tempStatusTelat;
                    });
                    Navigator.pop(context);
                    _fetchRekap(isRefresh: true);
                  },
                  child: Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Absensi'),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearDateRange,
              tooltip: 'Hapus Filter Tanggal',
            ),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter Tanggal',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Lainnya',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchRekap(isRefresh: true),
        child:
            authProvider.absensiList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                    child: Center(child: Text('Belum ada data absensi')),
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
                          absensi.namaKaryawan,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal: ${dateFormat.format(DateTime.parse(absensi.tanggal))}',
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              'Status: ${absensi.statusTelat.capitalize()}',
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
