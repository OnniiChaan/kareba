import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'tambah_siswa_page.dart'; // Import halaman tambah siswa
import 'detail_siswa_page.dart'; // Import halaman detail siswa

class SiswaPage extends StatefulWidget {
  const SiswaPage({super.key});

  @override
  State<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends State<SiswaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<dynamic> _allSiswa = [];
  List<dynamic> _filteredSiswa = [];
  Map<String, int> _pelanggaranCount = {}; 
  Map<String, int> _prestasiCount = {};

  String _searchQuery = "";
  final Set<String> _expandedLetters = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    try {
      // 1. Ambil data semua siswa (untuk referensi dasar)
      final resSiswa = await Supabase.instance.client
          .from('siswa')
          .select()
          .order('nama_lengkap', ascending: true);
      
      // 2. Ambil total pelanggaran per siswa (L) pada tanggal terpilih
      Map<String, int> pCount = {};
      try {
        final resPelanggaran = await Supabase.instance.client
            .from('pelanggaran')
            .select()
            .eq('tanggal_input', dateStr);

        for (var p in resPelanggaran) {
          String? sKey = p['nisn']?.toString() ?? p['siswa_id']?.toString() ?? p['id_siswa']?.toString() ?? p['siswa']?.toString();
          if (sKey != null) {
            pCount[sKey] = (pCount[sKey] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint("Error fetching pelanggaran: $e");
      }

      // 3. Ambil total prestasi per siswa (P) pada tanggal terpilih
      Map<String, int> prCount = {};
      try {
        final resPrestasi = await Supabase.instance.client
            .from('prestasi_siswa')
            .select()
            .eq('tanggal', dateStr);

        for (var p in resPrestasi) {
          String? sKey = p['nisn']?.toString() ?? p['siswa_id']?.toString() ?? p['id_siswa']?.toString() ?? p['siswa']?.toString();
          if (sKey != null) {
            prCount[sKey] = (prCount[sKey] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint("Error fetching prestasi: $e");
      }

      setState(() {
        _allSiswa = resSiswa;
        _pelanggaranCount = pCount;
        _prestasiCount = prCount;
        
        // Tampilkan semua siswa, tapi tetap dukung fitur pencarian
        _filteredSiswa = resSiswa.where((s) {
          if (_searchQuery.isEmpty) return true;
          
          final nama = (s['nama_lengkap'] ?? '').toLowerCase();
          final nisn = (s['nisn'] ?? '').toLowerCase();
          final kelas = (s['kelas'] ?? '').toLowerCase();
          return nama.contains(_searchQuery) || nisn.contains(_searchQuery) || kelas.contains(_searchQuery);
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  void _filterSiswa(String query) {
    _searchQuery = query.toLowerCase();
    _fetchData();
  }

  Map<String, List<dynamic>> _groupSiswaByLetter() {
    Map<String, List<dynamic>> grouped = {};
    for (var siswa in _filteredSiswa) {
      String nama = siswa['nama_lengkap'] ?? '?';
      String initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
      if (!grouped.containsKey(initial)) {
        grouped[initial] = [];
      }
      grouped[initial]!.add(siswa);
    }
    return grouped;
  }

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final List<int> _years = [2024, 2025, 2026, 2027, 2028];

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupSiswaByLetter();
    final letters = groupedData.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 40),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "List Siswa",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "Tahun Pelajaran 2026",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.black, size: 30),
                onPressed: () async {
                  final refresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TambahSiswaPage(),
                    ),
                  );
                  if (refresh == true) _fetchData();
                },
              ),
            ),
          ),
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
        child: Column(
          children: [
            const SizedBox(height: 10),
            // --- DROPDOWNS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRealDropdown(
                  value: _months[_focusedDay.month - 1],
                  items: _months,
                  onChanged: (val) {
                    if (val != null) {
                      int monthIdx = _months.indexOf(val) + 1;
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, monthIdx, _focusedDay.day);
                      });
                    }
                  },
                ),
                const SizedBox(width: 10),
                _buildRealDropdown(
                  value: _focusedDay.year.toString(),
                  items: _years.map((e) => e.toString()).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _focusedDay = DateTime(int.parse(val), _focusedDay.month, _focusedDay.day);
                      });
                    }
                  },
                ),
              ],
            ),
            
            // --- CALENDAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.week,
                availableCalendarFormats: const {CalendarFormat.week: 'Week'},
                startingDayOfWeek: StartingDayOfWeek.sunday,
                headerStyle: HeaderStyle(
                  leftChevronIcon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 25),
                  rightChevronIcon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 25),
                  formatButtonVisible: false,
                  titleCentered: false, // Kita sembunyikan title karena sudah ada dropdown di atas
                  headerPadding: EdgeInsets.zero,
                  leftChevronMargin: EdgeInsets.zero,
                  rightChevronMargin: EdgeInsets.zero,
                  titleTextStyle: const TextStyle(fontSize: 0), // Hide default title
                ),
                daysOfWeekHeight: 25,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchData();
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // Opsi: Bisa juga fetch data jika ingin hari pertama di minggu tersebut terpilih
                },
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  weekendTextStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  selectedDecoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.white30,
                    shape: BoxShape.circle,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  dowTextFormatter: (date, locale) {
                    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
                    return days[date.weekday % 7];
                  },
                  weekdayStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  weekendStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // --- PENCARIAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: TextField(
                onChanged: _filterSiswa,
                decoration: InputDecoration(
                  hintText: "Cari nama, NISN, kelas siswa",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // --- DAFTAR ABJAD ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  String letter = letters[index];
                  bool isExpanded = _expandedLetters.contains(letter);
                  List<dynamic> siswaList = groupedData[letter]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLetterHeader(letter, isExpanded),
                      if (isExpanded)
                        ...siswaList.map((siswa) => _buildSiswaCard(siswa)).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLetterHeader(String letter, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          isExpanded ? _expandedLetters.remove(letter) : _expandedLetters.add(letter);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              letter,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: CustomPaint(
                painter: DottedLinePainter(),
                child: const SizedBox(height: 1),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSiswaCard(dynamic siswa) {
    String nisn = (siswa['nisn'] ?? "").toString();
    int totalL = _pelanggaranCount[nisn] ?? 0;
    int totalP = _prestasiCount[nisn] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${siswa['nama_lengkap']} (${siswa['kelas']})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "NISN: ${siswa['nisn'] ?? "-"}",
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      "L: $totalL  P: $totalP",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.blueGrey, size: 35),
            onPressed: () async {
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailSiswaPage(siswa: siswa),
                ),
              );
              if (refresh == true) _fetchData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSiswa(dynamic siswa) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data"),
        content: Text("Hapus data ${siswa['nama_lengkap']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await Supabase.instance.client.from('siswa').delete().eq('id', siswa['id']);
        _fetchData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
      }
    }
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
