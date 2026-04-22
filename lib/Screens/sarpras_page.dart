import 'package:flutter/material.dart'; // Wajib ada
import 'package:supabase_flutter/supabase_flutter.dart'; // Wajib ada

class SarprasListPage extends StatelessWidget {
  const SarprasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Sarpras (Data Rusak)")),
      body: FutureBuilder(
        future: Supabase.instance.client.from('data_rusak').select(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Tidak ada data kerusakan"));
          }

          final data = snapshot.data as List;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(item['nama_barang'] ?? "Tanpa Nama Barang"),
                  subtitle: Text("Status: ${item['status'] ?? 'Dilaporkan'}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Pastikan class ProgresPengajuanPage sudah Bapak buat nanti
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (context) => ProgresPengajuanPage(sarprasId: item['id']),
                    // ));
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
