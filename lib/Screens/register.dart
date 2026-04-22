import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔥 IMPORT TAMBAHAN

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Variabel untuk menyimpan pilihan role
  String? _selectedRole;
  // List role untuk dropdown
  final List<String> _roles = ['Guru', 'Siswa', 'Admin'];

  // Controller untuk mengambil data dari TextField
  final _namaLengkapController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🔥 FUNGSI LOGIKA REGISTER (KONEKSI KE SUPABASE)
  // Di dalam file register.dart, update fungsi _registerUser:

Future<void> _registerUser() async {
  // 1. Validasi
  if (_namaLengkapController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty || _selectedRole == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange),
    );
    return;
  }

  // 2. Loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 3. Auth SignUp
    final AuthResponse res = await Supabase.instance.client.auth.signUp(
      email: _usernameController.text.trim(), // Input email asli
      password: _passwordController.text.trim(),
    );

    if (res.user != null) {
      // 4. Simpan ke tabel profiles
      await Supabase.instance.client.from('profiles').insert({
        'id': res.user!.id,
        'nama_lengkap': _namaLengkapController.text.trim(),
        'username': _usernameController.text.trim(),
        'role': _selectedRole,
      });

      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        
        // 5. PESAN BERHASIL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.green),
        );

        // 6. REDIRECT KE LOGIN
        Navigator.pop(context); 
      }
    }
  } catch (e) {
    if (mounted) Navigator.pop(context); // Tutup loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
    );
  }
}

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF80CBC4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // --- BAGIAN ATAS (FOTO & TOMBOL) ---
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBDBDBD),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implementasi image picker
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001942),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Upload Foto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.black45, thickness: 1),
                ],
              ),
            ),

            // --- BAGIAN BAWAH (FORM INPUT) ---
            Expanded(
              flex: 7,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    _buildLabel("Role:"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: _buildInputDecoration(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          hint: Text("Dropdown: Guru, Siswa, Admin", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                          isExpanded: true,
                          items: _roles.map((String role) {
                            return DropdownMenuItem<String>(value: role, child: Text(role));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() { _selectedRole = newValue; });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildLabel("Nama Lengkap:"),
                    _buildTextField(
                      controller: _namaLengkapController,
                      hintText: "Harus diisi untuk regist akun baru\nyang tidak melalui Google",
                      maxLines: 2,
                    ),
                    const SizedBox(height: 15),
                    _buildLabel("Username:"),
                    _buildTextField(controller: _usernameController, hintText: "harus diisi"),
                    const SizedBox(height: 15),
                    _buildLabel("Password:"),
                    _buildTextField(controller: _passwordController, hintText: "harus diisi", obscureText: true),
                    const SizedBox(height: 30),

                    // --- TOMBOL BUAT AKUN (SUDAH DIHUBUNGKAN) ---
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _registerUser, // 🔥 MENGARAH KE FUNGSI BARU
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001942),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text("Buat Akun Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  BoxDecoration _buildInputDecoration() {
    return BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5));
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, int maxLines = 1}) {
    return Container(
      decoration: _buildInputDecoration(),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}