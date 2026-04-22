import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fungsi untuk keluar dari aplikasi dan menghapus session
  static Future<void> logout(BuildContext context) async {
    try {
      // 1. Proses Sign Out dari Supabase
      await _supabase.auth.signOut();

      // 2. Pastikan context masih valid (mencegah error async gap)
      if (!context.mounted) return;

      // 3. Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda telah berhasil keluar'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Navigasi ke Halaman Login dan HAPUS semua tumpukan halaman sebelumnya
      // 'login' adalah nama route yang harus didaftarkan di main.dart
      Navigator.pushNamedAndRemoveUntil(
        context, 
        'login', 
        (route) => false
      );
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}