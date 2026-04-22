import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahSiswaPage extends StatefulWidget {
  const TambahSiswaPage({super.key});

  @override
  State<TambahSiswaPage> createState() => _TambahSiswaPageState();
}

class _TambahSiswaPageState extends State<TambahSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Controllers
  final _namaController = TextEditingController();
  final _nisnController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaAyahController = TextEditingController();
  final _pekerjaanAyahController = TextEditingController();
  final _waAyahController = TextEditingController();
  final _namaIbuController = TextEditingController();
  final _pekerjaanIbuController = TextEditingController();
  final _waIbuController = TextEditingController();

  String? _selectedKelas;
  String? _selectedStatus;
  DateTime? _tglMasuk;
  DateTime? _tglKeluar;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? fotoUrl;
      // 1. Upload Gambar jika ada
      if (_imageFile != null) {
        final fileName = 'siswa_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('profil_images') // Pastikan bucket ini ada di Supabase
            .upload(fileName, _imageFile!);
        fotoUrl = fileName;
      }

      // 2. Insert ke Tabel Siswa
      await Supabase.instance.client.from('siswa').insert({
        'nama_lengkap': _namaController.text,
        'nisn': _nisnController.text,
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil disimpan!")),
        );
        Navigator.pop(context, true); // Kembali dan beri sinyal refresh
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tambah Siswa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Tahun Pelajaran 2026", style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Kamera"),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text("Galeri"),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.black54,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Center(
                      child: Text(
                        "Upload Foto",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInput("Nama Lengkap", _namaController),
                    _buildInput("NISN", _nisnController),
                    _buildInput("Alamat", _alamatController),
                    _buildInput("Nama Ayah", _namaAyahController),
                    _buildInput("Pekerjaan Ayah", _pekerjaanAyahController),
                    _buildInput("No. WA Ayah", _waAyahController),
                    _buildInput("Nama Ibu", _namaIbuController),
                    _buildInput("Pekerjaan Ibu", _pekerjaanIbuController),
                    _buildInput("No. WA Ibu", _waIbuController),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _simpanData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Simpan Data Siswa",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: *",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
          ),
        ],
      ),
    );
  }
}
