import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/user_all.dart';
import '../../widgets/loading_dialog.dart';

class EmployeeManagementScreen extends StatefulWidget {
  @override
  _EmployeeManagementScreenState createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaFilterController = TextEditingController();
  String? _nama, _email, _password, _nomorTelepon, _role;
  String? _selectedRoleFilter = 'user'; // Default filter role
  UserAll? _editingUser;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchInitialData(); // Panggil fetch dengan loading dialog
    });
  }

  Future<void> _fetchInitialData() async {
    print('Fetching initial data...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showLoadingDialog(
      context,
      'Memuat data karyawan...',
    ); // Tampilkan dialog loading
    final success = await authProvider.fetchUsers(role: _selectedRoleFilter);
    if (mounted) {
      Navigator.pop(context); // Tutup dialog loading
      if (!success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data karyawan')));
      }
    }
  }

  Future<void> _applyFilter({bool isRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!isRefresh) showLoadingDialog(context, 'Memuat data karyawan...');
    final success = await authProvider.fetchUsers(
      nama: _namaFilterController.text,
      role: _selectedRoleFilter,
    );
    if (!isRefresh && mounted) Navigator.pop(context);
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data')));
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempRole = _selectedRoleFilter;
        String tempNama = _namaFilterController.text;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Filter Karyawan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: tempNama),
                      decoration: InputDecoration(labelText: 'Nama'),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempNama = value;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempRole,
                      decoration: InputDecoration(labelText: 'Role'),
                      items: [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'user', child: Text('User')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          tempRole = value;
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
                      _selectedRoleFilter = 'user'; // Reset ke default
                      _namaFilterController.clear();
                    });
                    Navigator.pop(context);
                    _applyFilter(isRefresh: false);
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
                      _selectedRoleFilter = tempRole;
                      _namaFilterController.text = tempNama;
                    });
                    Navigator.pop(context);
                    _applyFilter(isRefresh: false);
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

  void _showEmployeeForm({UserAll? user}) {
    setState(() {
      _editingUser = user;
      _nama = user?.nama;
      _email = user?.email;
      _password = null; // Kosongkan untuk edit
      _nomorTelepon = user?.nomorTelepon; // Bisa null
      _role = user?.role;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'Tambah Karyawan' : 'Edit Karyawan'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _nama,
                    decoration: InputDecoration(labelText: 'Nama'),
                    validator:
                        (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
                    onSaved: (value) => _nama = value,
                  ),
                  TextFormField(
                    initialValue: _email,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator:
                        (value) =>
                            value!.isEmpty || !value.contains('@')
                                ? 'Email tidak valid'
                                : null,
                    onSaved: (value) => _email = value,
                  ),
                  TextFormField(
                    initialValue: null,
                    decoration: InputDecoration(
                      labelText:
                          user == null ? 'Password' : 'Password (opsional)',
                    ),
                    obscureText: true,
                    validator:
                        (value) =>
                            user == null && (value == null || value.isEmpty)
                                ? 'Password wajib diisi'
                                : null,
                    onSaved: (value) => _password = value,
                  ),
                  TextFormField(
                    initialValue: _nomorTelepon,
                    decoration: InputDecoration(labelText: 'Nomor Telepon'),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Nomor telepon wajib diisi' : null,
                    onSaved: (value) => _nomorTelepon = value,
                  ),
                  DropdownButtonFormField<String>(
                    value: _role ?? 'user',
                    decoration: InputDecoration(labelText: 'Role'),
                    items:
                        ['admin', 'user']
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                    validator:
                        (value) => value == null ? 'Role wajib dipilih' : null,
                    onChanged: (value) => _role = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(onPressed: _submitForm, child: Text('Simpan')),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      showLoadingDialog(
        context,
        _editingUser == null
            ? 'Menambahkan karyawan...'
            : 'Memperbarui karyawan...',
      );
      try {
        bool success;
        if (_editingUser == null) {
          success = await authProvider.createUser(
            nama: _nama!,
            email: _email!,
            password: _password!,
            nomorTelepon: _nomorTelepon!,
            role: _role!,
          );
        } else {
          success = await authProvider.updateUser(
            id: _editingUser!.id,
            nama: _nama!,
            email: _email!,
            password: _password,
            nomorTelepon: _nomorTelepon!,
            role: _role!,
          );
        }
        if (mounted) {
          Navigator.of(context).pop(); // Tutup loading
          if (success) {
            Navigator.of(context).pop(); // Tutup form
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _editingUser == null
                      ? 'Karyawan ditambahkan'
                      : 'Karyawan diperbarui',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Gagal menyimpan')));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Tutup loading
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  void _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hapus Karyawan'),
            content: Text('Apakah Anda yakin ingin menghapus karyawan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      showLoadingDialog(context, 'Menghapus karyawan...');
      try {
        final success = await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).deleteUser(id);
        if (mounted) {
          Navigator.of(context).pop(); // Tutup loading
          if (success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Karyawan dihapus')));
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Gagal menghapus')));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Tutup loading
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    print('Building UI, User List Length: ${authProvider.userList.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Karyawan'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showEmployeeForm(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          showLoadingDialog(context, 'Memuat data karyawan...');
          return authProvider
              .fetchUsers(
                nama: _namaFilterController.text,
                role: _selectedRoleFilter,
              )
              .whenComplete(() => Navigator.pop(context));
        },
        child:
            authProvider.userList.isEmpty
                ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        100,
                    child: Center(child: Text('Belum ada karyawan')),
                  ),
                )
                : ListView.builder(
                  itemCount: authProvider.userList.length,
                  itemBuilder: (context, index) {
                    final user = authProvider.userList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(user.nama),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user.email}'),
                            Text(
                              'Nomor Telepon: ${user.nomorTelepon ?? 'Tidak ada'}',
                            ), // Handle null
                            Text('Role: ${user.role}'),
                            Text('Dibuat: ${user.createdAt}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEmployeeForm(user: user),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user.id),
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

  @override
  void dispose() {
    _namaFilterController.dispose();
    super.dispose();
  }
}
