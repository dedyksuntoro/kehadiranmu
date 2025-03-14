import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/user_all.dart';
import '../../services/auth_provider.dart';
import '../../widgets/loading_dialog.dart';

class RekapAbsenScreen extends StatefulWidget {
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
  UserAll? _selectedUser; // Ganti _userId jadi UserAll
  String? _selectedStatusTelat;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.fetchUsers(); // Ambil daftar karyawan saat init
      _fetchRekap();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMore();
      }
    });
  }

  Future<void> _fetchRekap({bool isRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!isRefresh) showLoadingDialog(context, 'Memuat rekap absensi...');
    final success = await authProvider.fetchAllAbsensi(
      page: isRefresh ? 1 : _currentPage,
      tanggalAwal:
          _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
      tanggalAkhir:
          _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      shift: _selectedShift,
      userId: _selectedUser != null ? int.parse(_selectedUser!.id) : null,
      statusTelat: _selectedStatusTelat,
    );
    if (!isRefresh) Navigator.pop(context);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat rekap absensi')));
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
      setState(() {
        _isLoadingMore = false;
      });
    }
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
      showLoadingDialog(context, 'Memuat rekap absensi berdasarkan tanggal...');
      await _fetchRekap(isRefresh: true);
      Navigator.pop(context);
    }
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
                      onChanged: (value) {
                        setStateDialog(() {
                          tempShift = value;
                        });
                      },
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
                          onChanged: (value) {
                            setStateDialog(() {
                              tempUser = value;
                            });
                          },
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
                      onChanged: (value) {
                        setStateDialog(() {
                          tempStatusTelat = value;
                        });
                      },
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
                    _fetchRekap(isRefresh: false);
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
                    _fetchRekap(isRefresh: false);
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
        title: Text('Rekap Absensi (Admin)'),
        actions: [
          IconButton(icon: Icon(Icons.date_range), onPressed: _selectDateRange),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchRekap(isRefresh: false),
        child:
            authProvider.absensiList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
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

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text('${absensi.namaKaryawan}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal: ${dateFormat.format(DateTime.parse(absensi.tanggal))}',
                            ),
                            Text(
                              'Shift: ${absensi.shift} (${dateFormat.format(DateTime.parse(absensi.tanggalShift))})',
                            ),
                            Text(
                              'Masuk: ${absensi.waktuMasuk != null ? timeFormat.format(absensi.waktuMasuk!) : "Belum absen"}',
                            ),
                            Text(
                              'Keluar: ${absensi.waktuKeluar != null ? timeFormat.format(absensi.waktuKeluar!) : "Belum absen"}',
                            ),
                            Text('Lokasi Masuk: ${absensi.lokasiMasuk}'),
                            Text(
                              'Lokasi Keluar: ${absensi.lokasiKeluar ?? "Belum absen"}',
                            ),
                            Text('Status: ${absensi.statusTelat}'),
                          ],
                        ),
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
