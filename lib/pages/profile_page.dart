import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_sync_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase ещё инициализируется
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;

        // ---------- НЕ АВТОРИЗОВАН ----------
        if (user == null) {
          return const LoginPage(embedded: true);
        }

        // ---------- АВТОРИЗОВАН ----------
        return Scaffold(
          appBar: AppBar(
            title: const Text("Профиль"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Вы вошли как:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? "(email не указан)",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Синхронизация началась...")),
                      );

                      await FirestoreSyncService.syncNotes();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Синхронизация завершена")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Ошибка синхронизации: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text("Синхронизация"),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Загрузка из облака...")),
                      );

                      await FirestoreSyncService.loadNotesFromFirestore();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Заметки загружены")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Ошибка загрузки: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Загрузить из облака"),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Выйти"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Синхронизация заметок\nдоступна после авторизации.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
