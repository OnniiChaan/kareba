import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';
import 'siswa_page.dart';
import 'sarpras_page.dart';
import 'package:kareba/Screens/logout.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
  final isDialOpen = ValueNotifier<bool>(false); // Notifier untuk SpeedDial

SpeedDialChild _buildSpeedDialItem({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return SpeedDialChild(
      child: Container(
        width: 250, // Sesuaikan lebar agar teks tidak terpotong
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8), 
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Agar container menyesuaikan isi
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      onTap: onTap,
    );
  }

  // DATA DUMMY
  List<Map<String, dynamic>> aktivitasList = [
    {
      "nama": "Nama Lengkap Siswa",
      "kelas": "Nama Kelas Siswa",
      "jenis": "Jenis Pelanggaran",
      "L": 5,
      "P": 2,
      "isPelanggaran": true,
    },
    {
      "nama": "Nama Lengkap Siswa",
      "kelas": "Nama Kelas Siswa",
      "jenis": "Jenis Prestasi",
      "L": 1,
      "P": 8,
      "isPelanggaran": false,
    },
  ];

  List<Map<String, dynamic>> sarprasList = [
    {"item": "Item 1", "status": "Perlu perbaikan", "isSelesai": false},
    {"item": "Item 2", "status": "Telah diperbaiki", "isSelesai": true},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchUserData();
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
        _namaLengkap = response['nama_lengkap'] ?? "User Tidak Dikenal";
        if (response['foto_url'] != null &&
            response['foto_url'].toString().isNotEmpty) {
          _fotoProfilUrl = Supabase.instance.client.storage
              .from('profil_images')
              .getPublicUrl(response['foto_url']);
        } else {
          _fotoProfilUrl = null;
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _refreshPage() async {
    await _fetchUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Halaman diperbarui'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // MODIFIKASI: Menggunakan SpeedDial untuk menu bawah
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF80CBC4)],
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
                          const Text(
                            "Rekam Aktivitas Siswa",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...aktivitasList.map(
                            (item) => _buildDataCard(
                              title: "${item['nama']} (${item['kelas']})",
                              subtitle: item['jenis'],
                              trailing: "L: ${item['L']}   P: ${item['P']}",
                              color: item['isPelanggaran']
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Pelaporan Sarpras",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...sarprasList.map(
                            (item) => _buildDataCard(
                              title: item['item'],
                              subtitle: item['status'],
                              color: item['isSelesai']
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // FLOATING MENU (Sisi Kiri) & SPEED DIAL (Sisi Kanan)
              // Ganti bagian Positioned lama dengan ini
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. Tombol Menu Samping (Tetap seperti sebelumnya)
                    _buildNavButton(
                      Icons.menu,
                      "Menu",
                      () => _showFloatingMenu(context),
                    ),

                    // 2. TOMBOL TAMBAH DENGAN SPEED DIAL CUSTOM
                    SpeedDial(
                      openCloseDial: isDialOpen,
                      icon: Icons.add_circle_outline,
                      activeIcon: Icons.cancel_outlined,
                      label: const Text(
                        "Tambah",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFF001942),
                      foregroundColor: Colors.white,
                      activeBackgroundColor: const Color(0xFF001942),
                      // Menghilangkan shadow/background putih yang mengganggu
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      spacing: 15,
                      childPadding: const EdgeInsets.all(0),
                      childrenButtonSize: const Size(
                        220,
                        50,
                      ), // Membuat ukuran popup memanjang ke samping

                      children: [
                        _buildSpeedDialItem(
                          icon: Icons.stars_rounded,
                          label: "Rekam Prestasi Siswa",
                          onTap: () => debugPrint("Ke Prestasi"),
                        ),
                        _buildSpeedDialItem(
                          icon: Icons.assignment_late_rounded,
                          label: "Rekam Pelanggaran Siswa",
                          onTap: () => debugPrint("Ke Pelanggaran"),
                        ),
                        _buildSpeedDialItem(
                          icon: Icons.home_repair_service_rounded,
                          label: "Lapor Perbaikan Sarpras",
                          onTap: () => debugPrint("Ke Sarpras"),
                        ),
                      ],
                    ),
                  ],
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
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Guru",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.black87),
            onPressed: _refreshPage,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () async {
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              if (refresh == true) _fetchUserData();
            },
            child: CircleAvatar(
              radius: 16,
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

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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

  Widget _buildDataCard({
    required String title,
    required String subtitle,
    String? trailing,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (trailing != null)
                      Text(
                        trailing,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: color,
            radius: 15,
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF001942),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // FUNGSI POPUP MENU SAMPING (Siswa, Sarpras, Logout)
  void _showFloatingMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.transparent,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 20, bottom: 85),
            padding: const EdgeInsets.all(10),
            width: 220,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPopupItem(Icons.people_outline, "Siswa", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SiswaListPage(),
                      ),
                    );
                  }),
                  _buildPopupItem(Icons.inventory_2_outlined, "Sarpras", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SarprasListPage(),
                      ),
                    );
                  }),
                  _buildPopupItem(Icons.logout, "Log Out", () async {
                    Navigator.pop(context);
                    await AuthService.logout(context);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
