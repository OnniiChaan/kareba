import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';
import 'package:kareba/Screens/logout.dart'; // Sesuaikan dengan letak file logout.dart Bapak

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _namaLengkap = "Memuat...";
  String? _fotoProfilUrl;

  int countPelanggaran = 0;
  int countPrestasi = 0;
  int countPerluPerbaikan = 0;
  int countDiproses = 0;
  int countSelesai = 0;
  bool _isLoadingCounts = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchUserData();
    _fetchDashboardCounts(_focusedDay);
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('nama_lengkap, foto_url')
          .eq('id', user.id)
          .single();
      setState(() {
        _namaLengkap = response['nama_lengkap'] ?? "Administrator";
        if (response['foto_url'] != null &&
            response['foto_url'].toString().isNotEmpty) {
          _fotoProfilUrl = Supabase.instance.client.storage
              .from('profil_images')
              .getPublicUrl(response['foto_url']);
        }
      });
    } catch (e) {
      debugPrint("Error User Data: $e");
    }
  }

  Future<void> _fetchDashboardCounts(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoadingCounts = true);

    // Format tanggal harus YYYY-MM-DD agar cocok dengan tipe 'date' di Supabase
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      // 1. Query Pelanggaran (Pastikan nama kolom di tabel ini juga benar)
      final resPelanggaran = await Supabase.instance.client
          .from('pelanggaran')
          .select()
          .eq('tanggal_input', dateStr)
          .count(CountOption.exact);

      // 2. PERBAIKAN: Ganti 'tanggal_input' menjadi 'tanggal'
      final resPrestasi = await Supabase.instance.client
          .from('prestasi_siswa')
          .select()
          .eq(
            'tanggal',
            dateStr,
          ) // <--- Diubah dari 'tanggal_input' ke 'tanggal'
          .count(CountOption.exact);

      // 3. Query Sarpras
      final resPerbaikan = await Supabase.instance.client
          .from('sarpras')
          .select()
          .eq('tanggal_lapor', dateStr)
          .eq('status', 'Perlu Perbaikan')
          .count(CountOption.exact);
      final resDiproses = await Supabase.instance.client
          .from('sarpras')
          .select()
          .eq('tanggal_lapor', dateStr)
          .eq('status', 'Diproses')
          .count(CountOption.exact);
      final resSelesai = await Supabase.instance.client
          .from('sarpras')
          .select()
          .eq('tanggal_lapor', dateStr)
          .eq('status', 'Selesai')
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          countPelanggaran = resPelanggaran.count;
          countPrestasi = resPrestasi.count; // Data dari tabel prestasi_siswa
          countPerluPerbaikan = resPerbaikan.count;
          countDiproses = resDiproses.count;
          countSelesai = resSelesai.count;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint("Error Counts: $e");
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF163C5F), Color(0xFF6FD8EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildCalendar(),
                          const SizedBox(height: 25),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Aktivitas Siswa",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDashboardCard(
                                      number: _isLoadingCounts
                                          ? "..."
                                          : countPelanggaran.toString(),
                                      title: "Pelanggaran",
                                      color: const Color(0xFFFF6B6B),
                                      icon: Icons.campaign_outlined,
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDashboardCard(
                                      number: _isLoadingCounts
                                          ? "..."
                                          : countPrestasi.toString(),
                                      title: "Prestasi",
                                      color: const Color(0xFFFFD93D),
                                      icon: Icons.workspace_premium_outlined,
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Pelaporan Sarpras",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDashboardCard(
                                      number: _isLoadingCounts
                                          ? "..."
                                          : countPerluPerbaikan.toString(),
                                      title: "Perlu Perbaikan",
                                      color: const Color(0xFFFF4C4C),
                                      icon: Icons.home_repair_service_outlined,
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDashboardCard(
                                      number: _isLoadingCounts
                                          ? "..."
                                          : countDiproses.toString(),
                                      title: "Diproses",
                                      color: const Color(0xFFFF9F1C),
                                      icon: Icons.construction,
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDashboardCard(
                                      number: _isLoadingCounts
                                          ? "..."
                                          : countSelesai.toString(),
                                      title: "Selesai",
                                      color: const Color(0xFF8CEE4C),
                                      icon: Icons.engineering,
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (_isMenuOpen)
                GestureDetector(
                  onTap: () => setState(() => _isMenuOpen = false),
                  child: Container(
                    color: Colors.black26,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

              if (_isMenuOpen)
                Positioned(bottom: 80, left: 20, child: _buildMenuPopup()),

              Positioned(
                bottom: 20,
                left: 20,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
                  icon: Icon(
                    _isMenuOpen ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isMenuOpen ? "Tutup" : "Menu",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001942),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER DENGAN PERBAIKAN DECORATION ---

  Widget _buildDashboardCard({
    required String number,
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color, // HARUS DI DALAM SINI
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87, width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -5,
              left: 0,
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(icon, size: 35, color: Colors.black87),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(10),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _fetchDashboardCounts(selectedDay);
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Color(0xFF424242),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          todayDecoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  // --- HEADER & MENU TETAP SAMA ---
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          // Logo KAREBA
          Image.asset(
            'assets/images/logo.png',
            height: 45,
            errorBuilder: (ctx, err, stack) =>
                const Icon(Icons.school, size: 40, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 10),

          // Info Nama & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _namaLengkap,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Administrator",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // 1. Icon Refresh (Sync)
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.black87, size: 22),
            onPressed: () =>
                _fetchDashboardCounts(_selectedDay ?? DateTime.now()),
            tooltip: "Refresh Data",
          ),

          // 2. Icon Notifikasi
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
              size: 24,
            ),
            onPressed: () {
              // Arahkan ke halaman rekap notifikasi jika sudah ada filenya
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
            },
          ),

          const SizedBox(width: 5),

          // 3. Icon Profil (Fungsi sama dengan dashboard_guru.dart)
          GestureDetector(
            onTap: () async {
              // Berpindah ke halaman edit profil
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );

              // Jika kembali dari EditProfilePage dan membawa nilai 'true', refresh data profil
              if (refresh == true) {
                _fetchUserData();
              }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _fotoProfilUrl != null
                  ? NetworkImage(_fotoProfilUrl!)
                  : null,
              child: _fotoProfilUrl == null
                  ? const Icon(Icons.person, color: Colors.black54, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPopup() {
    Widget _buildMenuPopup() {
  return Container(
    width: 220,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPopupItem(Icons.people_outline, "Siswa", () {
          setState(() => _isMenuOpen = false);
          // Navigasi ke halaman siswa
        }),
        _buildPopupItem(Icons.inventory_2_outlined, "Sarpras", () {
          setState(() => _isMenuOpen = false);
          // Navigasi ke halaman sarpras
        }),
        
        // --- KEMBALIKAN FUNGSI LOGOUT SEBELUMNYA ---
        _buildPopupItem(Icons.logout, "Log Out", () async {
          setState(() => _isMenuOpen = false); // Tutup popup menu
          
          // Memanggil AuthService sesuai fungsi yang ada di dashboard_guru.dart
          await AuthService.logout(context); 
        }),
      ],
    ),
  );
}

  Widget _buildPopupItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
