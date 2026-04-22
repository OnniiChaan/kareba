import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _namaController = TextEditingController();
  String? _username;
  String? _role;
  String? _fotoUrl;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    setState(() {
      _namaController.text = data['nama_lengkap'] ?? "";
      _username = data['username'];
      _role = data['role'];
      _fotoUrl = data['foto_url'];
    });
  }

  // 🔥 FUNGSI UPLOAD YANG SUDAH DIPERBAIKI UNTUK WEB
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    // Menggunakan imageQuality untuk kompresi ringan
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      final fileExt = image.name.split('.').last;
      final fileName =
          '${user!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Baca gambar sebagai Bytes (Ini kunci agar tidak error di Web)
      final imageBytes = await image.readAsBytes();

      // 2. Upload ke Bucket menggunakan uploadBinary
      await _supabase.storage
          .from('profil_images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 3. Dapatkan URL Publik
      final String publicUrl = _supabase.storage
          .from('profil_images')
          .getPublicUrl(fileName);

      // 4. Update tabel profiles dengan link foto baru
      await _supabase
          .from('profiles')
          .update({'foto_url': fileName})
          .eq('id', user.id);

      setState(() {
        _fotoUrl = fileName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal unggah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      await _supabase
          .from('profiles')
          .update({'nama_lengkap': _namaController.text.trim()})
          .eq('id', user!.id);

      if (mounted) {
        Navigator.pop(context, true); // Sinyal untuk refresh dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fullFotoUrl = _fotoUrl != null
        ? _supabase.storage.from('profil_images').getPublicUrl(_fotoUrl!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // AREA FOTO
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: fullFotoUrl != null
                              ? NetworkImage(fullFotoUrl)
                              : null,
                          child: fullFotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Color(0xFF0D47A1),
                            radius: 18,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildReadOnlyField("Username / Email", _username ?? "-"),
                  const SizedBox(height: 15),
                  _buildReadOnlyField("Role", _role ?? "-"),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001942),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
    );
  }
}
