import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaListPage extends StatelessWidget {
  const SiswaListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Data Siswa"), 
        backgroundColor: const Color(0xFF0D47A1), 
        foregroundColor: Colors.white
      ),
      body: FutureBuilder(
        // Mengambil data dari tabel 'siswa' di Supabase
        future: Supabase.instance.client.from('siswa').select(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text("Belum ada data siswa di database."));
          }

          final listSiswa = snapshot.data as List;
          return ListView.builder(
            itemCount: listSiswa.length,
            itemBuilder: (context, index) {
              final siswa = listSiswa[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0D47A1),
                    child: Text(
                      siswa['nama_siswa'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(siswa['nama_siswa'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Kelas: ${siswa['kelas']} | NISN: ${siswa['nisn']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // SEKARANG SUDAH TIDAK ERROR karena class sudah didefinisikan di bawah
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DetailKarakterSiswa(
                        siswaId: siswa['id'], 
                        namaSiswa: siswa['nama_siswa']
                      )
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- CLASS BARU UNTUK DETAIL PELANGGARAN & PRESTASI ---
class DetailKarakterSiswa extends StatelessWidget {
  final String siswaId;
  final String namaSiswa;

  const DetailKarakterSiswa({super.key, required this.siswaId, required this.namaSiswa});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dua Tab: Pelanggaran dan Prestasi
      child: Scaffold(
        appBar: AppBar(
          title: Text(namaSiswa),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.warning_amber), text: "Pelanggaran"),
              Tab(icon: Icon(Icons.emoji_events), text: "Prestasi"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListKarakter('pelanggaran_siswa'),
            _buildListKarakter('prestasi_siswa'),
          ],
        ),
      ),
    );
  }

  // Fungsi pembantu untuk memuat list data dari Supabase berdasarkan nama tabel
  Widget _buildListKarakter(String tableName) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from(tableName)
          .select()
          .eq('siswa_id', siswaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Text(
              tableName == 'pelanggaran_siswa' 
                ? "Tidak ada data pelanggaran." 
                : "Belum ada prestasi tercatat.",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final data = snapshot.data as List;
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final isPelanggaran = tableName == 'pelanggaran_siswa';
            
            return Card(
              child: ListTile(
                leading: Icon(
                  isPelanggaran ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: isPelanggaran ? Colors.red : Colors.green,
                ),
                title: Text(isPelanggaran ? item['jenis_pelanggaran'] : item['nama_prestasi']),
                subtitle: Text("Tanggal: ${item['tanggal']}"),
                trailing: Text(
                  isPelanggaran ? "-${item['poin']} Poin" : "+Poin", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isPelanggaran ? Colors.red : Colors.green
                  )
                ),
              ),
            );
          },
        );
      },
    );
  }
}