import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/note.dart';
import 'models/tag.dart';
import 'models/folder.dart';
import 'pages/home_page.dart';
import 'pages/app_shell.dart';
import 'services/folder_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(TagAdapter());
  //await Hive.deleteBoxFromDisk('notes');
  await Hive.openBox<Note>('notes');
  await Hive.openBox<Folder>('folders');
  await Hive.openBox<Tag>('tags');
  await NotificationService().init();
  await Firebase.initializeApp();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),   // <── вот это важно
    );
  }
}
