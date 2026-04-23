import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DetailSiswaPage extends StatefulWidget {
  final dynamic siswa;
  const DetailSiswaPage({super.key, required this.siswa});

  @override
  State<DetailSiswaPage> createState() => _DetailSiswaPageState();
}

class _DetailSiswaPageState extends State<DetailSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUpdated = false;

  late TextEditingController _namaController;
  late TextEditingController _nisnController;
  late TextEditingController _waController;
  late TextEditingController _alamatController;
  late TextEditingController _namaAyahController;
  late TextEditingController _pekerjaanAyahController;
  late TextEditingController _waAyahController;
  late TextEditingController _namaIbuController;
  late TextEditingController _pekerjaanIbuController;
  late TextEditingController _waIbuController;

  String? _selectedKelas;
  String? _selectedStatus;
  DateTime? _tglMasuk;
  DateTime? _tglKeluar;
  String? _existingFotoUrl;

  final List<String> _listKelas = ['X-1', 'X-2', 'XI-1', 'XI-2', 'XII-1', 'XII-2'];
  final List<String> _listStatus = ['Aktif', 'Lulus', 'Pindah', 'Keluar'];

  @override
  void initState() {
    super.initState();
    final s = widget.siswa;
    _namaController = TextEditingController(text: s['nama_lengkap']);
    _nisnController = TextEditingController(text: s['nisn']);
    _waController = TextEditingController(text: s['no_wa'] ?? '');
    _alamatController = TextEditingController(text: s['alamat']);
    _namaAyahController = TextEditingController(text: s['nama_ayah']);
    _pekerjaanAyahController = TextEditingController(text: s['pekerjaan_ayah']);
    _waAyahController = TextEditingController(text: s['no_wa_ayah']);
    _namaIbuController = TextEditingController(text: s['nama_ibu']);
    _pekerjaanIbuController = TextEditingController(text: s['pekerjaan_ibu']);
    _waIbuController = TextEditingController(text: s['no_wa_ibu']);

    _selectedKelas = s['kelas'];
    _selectedStatus = s['status'];
    _existingFotoUrl = s['foto_url'];
    
    if (s['tanggal_masuk'] != null) {
      _tglMasuk = DateTime.parse(s['tanggal_masuk']);
    }
    if (s['tanggal_keluar'] != null) {
      _tglKeluar = DateTime.parse(s['tanggal_keluar']);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isMasuk) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isMasuk ? _tglMasuk : _tglKeluar) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isMasuk) _tglMasuk = picked;
        else _tglKeluar = picked;
      });
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? fotoUrl = _existingFotoUrl;
      if (_imageFile != null) {
        final fileName = 'siswa_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('profil_images').upload(fileName, _imageFile!);
        fotoUrl = fileName;
      }

      final oldNisn = widget.siswa['nisn'];
      final newNisn = _nisnController.text;

      // 1. Update tabel siswa
      await Supabase.instance.client.from('siswa').update({
        'nama_lengkap': _namaController.text,
        'nisn': newNisn,
        'kelas': _selectedKelas ?? '-',
        'alamat': _alamatController.text,
        'nama_ayah': _namaAyahController.text,
        'pekerjaan_ayah': _pekerjaanAyahController.text,
        'no_wa_ayah': _waAyahController.text,
        'nama_ibu': _namaIbuController.text,
        'pekerjaan_ibu': _pekerjaanIbuController.text,
        'no_wa_ibu': _waIbuController.text,
        'status': _selectedStatus ?? 'Aktif',
        'tanggal_masuk': _tglMasuk?.toIso8601String(),
        'tanggal_keluar': _tglKeluar?.toIso8601String(),
        'foto_url': fotoUrl,
      }).eq('id', widget.siswa['id']);

      // 2. Jika NISN berubah, update juga di tabel relasi (pelanggaran & prestasi)
      if (oldNisn != newNisn) {
        try {
          await Supabase.instance.client
              .from('pelanggaran')
              .update({'nisn': newNisn})
              .eq('nisn', oldNisn);
          
          await Supabase.instance.client
              .from('prestasi_siswa')
              .update({'nisn': newNisn})
              .eq('nisn', oldNisn);
        } catch (eRelasi) {
          debugPrint("Gagal update relasi: $eRelasi");
          // Kita lanjutkan saja karena data utama sudah tersimpan
        }
      }

      if (mounted) {
        setState(() {
          _isUpdated = true;
          _existingFotoUrl = fotoUrl;
          _imageFile = null; // Clear local file to show uploaded image
          // Update widget.siswa as well for future references in this session
          widget.siswa['nama_lengkap'] = _namaController.text;
          widget.siswa['nisn'] = newNisn;
          widget.siswa['kelas'] = _selectedKelas;
          widget.siswa['alamat'] = _alamatController.text;
          widget.siswa['nama_ayah'] = _namaAyahController.text;
          widget.siswa['pekerjaan_ayah'] = _pekerjaanAyahController.text;
          widget.siswa['no_wa_ayah'] = _waAyahController.text;
          widget.siswa['nama_ibu'] = _namaIbuController.text;
          widget.siswa['pekerjaan_ibu'] = _pekerjaanIbuController.text;
          widget.siswa['no_wa_ibu'] = _waIbuController.text;
          widget.siswa['status'] = _selectedStatus;
          widget.siswa['tanggal_masuk'] = _tglMasuk?.toIso8601String();
          widget.siswa['tanggal_keluar'] = _tglKeluar?.toIso8601String();
          widget.siswa['foto_url'] = fotoUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diperbarui!")));
        // Opsi: Tetap di halaman agar user bisa lihat perubahan
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusData() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data"),
        content: const Text("Apakah Anda yakin ingin menghapus data siswa ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('siswa').delete().eq('id', widget.siswa['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil dihapus!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, _isUpdated),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 50, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 50)),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detail Siswa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                Text("Tahun Pelajaran 2026", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_as, color: Colors.blueAccent),
            onPressed: _updateData,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _hapusData,
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6FD8EF), Color(0xFF163C5F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade400,
                            backgroundImage: _imageFile != null 
                              ? FileImage(_imageFile!) 
                              : (_existingFotoUrl != null ? NetworkImage("${Supabase.instance.client.storage.from('profil_images').getPublicUrl(_existingFotoUrl!)}") as ImageProvider : null),
                            child: (_imageFile == null && _existingFotoUrl == null)
                                ? const Icon(Icons.person, size: 80, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () => _showImageSourceOptions(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.purple, width: 2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text("Ubah Foto", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: _buildField("Nama Lengkap", _namaController, "Nama")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField("NISN", _nisnController, "NISN")),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(child: _buildDropdownField("Kelas", _selectedKelas, _listKelas, (v) => setState(() => _selectedKelas = v))),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField("No. WA", _waController, "WA")),
                      ],
                    ),

                    _buildField("Alamat", _alamatController, "Alamat"),
                    _buildField("Nama Ayah", _namaAyahController, "Nama Ayah"),
                    _buildField("Pekerjaan Ayah", _pekerjaanAyahController, "Pekerjaan Ayah"),
                    _buildField("No. WA Ayah", _waAyahController, "WA Ayah"),
                    _buildField("Nama Ibu", _namaIbuController, "Nama Ibu"),
                    _buildField("Pekerjaan Ibu", _pekerjaanIbuController, "Pekerjaan Ibu"),
                    _buildField("No. WA Ibu", _waIbuController, "WA Ibu"),

                    Row(
                      children: [
                        Expanded(child: _buildDropdownField("Status", _selectedStatus, _listStatus, (v) => setState(() => _selectedStatus = v))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDateField("Masuk", _tglMasuk, () => _selectDate(context, true))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDateField("Keluar", _tglKeluar, () => _selectDate(context, false))),
                      ],
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Simpan Data", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Kamera"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text("Galeri"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: *", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
            ),
            validator: (v) => v!.isEmpty ? "Wajib" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: *", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: *", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date == null ? "Value" : DateFormat('dd/MM/yyyy').format(date!), style: TextStyle(fontSize: 13, color: date == null ? Colors.grey : Colors.black)),
                  const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
