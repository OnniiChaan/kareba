import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tambah_siswa_page.dart'; // Import halaman tambah siswa

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
  Map<String, int> _pelanggaranCount =
      {}; // Menyimpan total pelanggaran per siswa

  String _searchQuery = "";
  final Set<String> _expandedLetters =
      {}; // Menyimpan abjad mana yang sedang dibuka

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Ambil data semua siswa
      final resSiswa = await Supabase.instance.client
          .from('siswa')
          .select()
          .order('nama_lengkap', ascending: true);

      // 2. Ambil data pelanggaran di tanggal yang dipilih untuk menghitung (L)
      final dateStr =
          "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
      final resPelanggaran = await Supabase.instance.client
          .from('pelanggaran')
          .select('siswa_id')
          .eq('tanggal_input', dateStr);

      // Hitung pelanggaran per siswa
      Map<String, int> pCount = {};
      for (var p in resPelanggaran) {
        String sId = p['siswa_id'].toString();
        pCount[sId] = (pCount[sId] ?? 0) + 1;
      }

      setState(() {
        _allSiswa = resSiswa;
        _filteredSiswa = resSiswa;
        _pelanggaranCount = pCount;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _filterSiswa(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredSiswa = _allSiswa.where((siswa) {
        final nama = (siswa['nama_lengkap'] ?? '').toLowerCase();
        final nisn = (siswa['nisn'] ?? '').toLowerCase();
        final kelas = (siswa['kelas'] ?? '').toLowerCase();
        return nama.contains(_searchQuery) ||
            nisn.contains(_searchQuery) ||
            kelas.contains(_searchQuery);
      }).toList();
    });
  }

  // Kelompokkan siswa berdasarkan huruf pertama
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

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupSiswaByLetter();
    final letters = groupedData.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "List Siswa",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "Tahun Pelajaran 2026",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.black,
              size: 30,
            ),
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
            // --- KALENDER MINGGUAN ---
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat:
                  CalendarFormat.week, // Menampilkan 1 baris minggu saja
              availableCalendarFormats: const {CalendarFormat.week: 'Week'},
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _fetchData(); // Ambil ulang data L (pelanggaran) saat tanggal diganti
              },
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.redAccent),
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
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white),
                weekendStyle: TextStyle(color: Colors.redAccent),
              ),
            ),

            // --- PENCARIAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

            // --- DAFTAR ABJAD AKORDION ---
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
                      // Header Abjad (A, B, C...)
                      InkWell(
                        onTap: () {
                          setState(() {
                            isExpanded
                                ? _expandedLetters.remove(letter)
                                : _expandedLetters.add(letter);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "----------------------------------------------------------------",
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // List Card Siswa jika Expanded
                      if (isExpanded)
                        ...siswaList.map((siswa) {
                          int totalL =
                              _pelanggaranCount[siswa['id'].toString()] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black87),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${siswa['nama_lengkap']} (${siswa['kelas']})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            siswa['nisn'] ?? "-",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            "L: $totalL  P: 0",
                                            style: const TextStyle(
                                              fontSize: 13,
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
                                InkWell(
                                  onTap: () {
                                    // Tombol panah mengarah ke detail/edit (sesuai instruksi)
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TambahSiswaPage(),
                                      ),
                                    );
                                  },
                                  child: const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
}
