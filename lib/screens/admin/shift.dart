import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/loading_dialog.dart';
import '../../models/shift.dart';

class ShiftScreen extends StatefulWidget {
  @override
  _ShiftScreenState createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchShifts();
    });
  }

  Future<void> _fetchShifts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showLoadingDialog(context, 'Memuat daftar shift...');
    final success = await authProvider.fetchShifts();
    Navigator.pop(context);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar shift')));
    }
  }

  Future<void> _showShiftDialog({Shift? shift}) async {
    final shiftController = TextEditingController(text: shift?.shift ?? '');
    TimeOfDay? jamMulai =
        shift != null
            ? TimeOfDay(
              hour: int.parse(shift.jamMulai.split(':')[0]),
              minute: int.parse(shift.jamMulai.split(':')[1]),
            )
            : null;
    TimeOfDay? jamSelesai =
        shift != null
            ? TimeOfDay(
              hour: int.parse(shift.jamSelesai.split(':')[0]),
              minute: int.parse(shift.jamSelesai.split(':')[1]),
            )
            : null;

    final jamMulaiController = TextEditingController(
      text: jamMulai != null ? _formatTimeOfDay(jamMulai) : '',
    );
    final jamSelesaiController = TextEditingController(
      text: jamSelesai != null ? _formatTimeOfDay(jamSelesai) : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(shift == null ? 'Tambah Shift' : 'Edit Shift'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: shiftController,
                  decoration: InputDecoration(labelText: 'Nama Shift'),
                ),
                TextField(
                  controller: jamMulaiController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Jam Mulai'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: jamMulai ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        jamMulai = picked;
                        jamMulaiController.text = _formatTimeOfDay(picked);
                      });
                    }
                  },
                ),
                TextField(
                  controller: jamSelesaiController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Jam Selesai'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: jamSelesai ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        jamSelesai = picked;
                        jamSelesaiController.text = _formatTimeOfDay(picked);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final shiftName = shiftController.text.trim();
                if (shiftName.isEmpty ||
                    jamMulai == null ||
                    jamSelesai == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                showLoadingDialog(
                  context,
                  shift == null ? 'Membuat shift...' : 'Memperbarui shift...',
                );
                bool success;
                if (shift == null) {
                  success = await authProvider.createShift(
                    shiftName,
                    _formatTimeOfDay(jamMulai!),
                    _formatTimeOfDay(jamSelesai!),
                  );
                } else {
                  success = await authProvider.updateShift(
                    shift.id,
                    shiftName,
                    _formatTimeOfDay(jamMulai!),
                    _formatTimeOfDay(jamSelesai!),
                  );
                }
                Navigator.pop(context); // Tutup loading

                if (success) {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shift == null
                            ? 'Shift berhasil dibuat'
                            : 'Shift berhasil diperbarui',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shift == null
                            ? 'Gagal membuat shift'
                            : 'Gagal memperbarui shift',
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

  Future<void> _showDeleteDialog(Shift shift) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus shift "${shift.shift}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                showLoadingDialog(context, 'Menghapus shift...');
                final success = await authProvider.deleteShift(shift.id);
                Navigator.pop(context); // Tutup loading

                if (success) {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Shift berhasil dihapus')),
                  );
                } else {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus shift')),
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes:00';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Daftar Shift (Admin)')),
      body: RefreshIndicator(
        onRefresh: _fetchShifts,
        child:
            authProvider.shiftList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                    child: Center(child: Text('Belum ada data shift')),
                  ),
                )
                : ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: authProvider.shiftList.length,
                  itemBuilder: (context, index) {
                    final shift = authProvider.shiftList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text('Shift: ${shift.shift}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jam Mulai: ${shift.jamMulai}'),
                            Text('Jam Selesai: ${shift.jamSelesai}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showShiftDialog(shift: shift),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(shift),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShiftDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
