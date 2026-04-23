import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardGuru extends StatefulWidget {
  const DashboardGuru({super.key});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _namaLengkap = "Memuat...";
  String? _fotoProfilUrl;

  // --- VARIABEL UNTUK MENAMPUNG JUMLAH DATA (DYNAMIC) ---
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
    // Ambil data untuk tanggal hari ini saat pertama kali buka
    _fetchDashboardCounts(_focusedDay);
  }

  // 1. FUNGSI AMBIL DATA PROFIL
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

  // 2. FUNGSI QUERY FILTER BERDASARKAN TANGGAL (INTI PERUBAHAN)
  Future<void> _fetchDashboardCounts(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoadingCounts = true);

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      // CARA TERBARU: Gunakan head: true untuk mendapatkan count tanpa mengambil seluruh data
      final resPelanggaran = await Supabase.instance.client
          .from('pelanggaran')
          .select()
          .eq('tanggal_input', dateStr)
          .count(CountOption.exact); // Cara baru mengambil jumlah data

      final resPrestasi = await Supabase.instance.client
          .from('prestasi_siswa')
          .select()
          .eq('tanggal', dateStr)
          .count(CountOption.exact);

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
          // Ambil hasil count-nya
          countPelanggaran = resPelanggaran.count;
          countPrestasi = resPrestasi.count;
          countPerluPerbaikan = resPerbaikan.count;
          countDiproses = resDiproses.count;
          countSelesai = resSelesai.count;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
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
                              // KOLOM KIRI (Aktivitas Siswa)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Aktivitas Siswa",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
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

                              // KOLOM KANAN (Pelaporan Sarpras)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Pelaporan Sarpras",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
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
                    size: 20,
                  ),
                  label: Text(
                    _isMenuOpen ? "Tutup" : "Menu",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001942),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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

  // --- WIDGET HELPER ---

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 45,
            errorBuilder: (ctx, err, stack) =>
                const Icon(Icons.school, size: 40, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _namaLengkap,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                ),
                const Text(
                  "Administrator",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () =>
                _fetchDashboardCounts(_selectedDay ?? DateTime.now()),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _fotoProfilUrl != null
                ? NetworkImage(_fotoProfilUrl!)
                : null,
          ),
        ],
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
          // TRIGGER QUERY SETIAP GANTI TANGGAL
          _fetchDashboardCounts(selectedDay);
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: const CalendarStyle(
          defaultDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          weekendDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
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
          color: color,
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

  Widget _buildMenuPopup() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPopupItem(Icons.people_outline, "Siswa", () {}),
          _buildPopupItem(Icons.inventory_2_outlined, "Sarpras", () {}),
          _buildPopupItem(Icons.logout, "Log Out", () {}),
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
