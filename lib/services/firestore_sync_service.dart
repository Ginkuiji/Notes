import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../models/note.dart';

class FirestoreSyncService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> loadNotesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Пользователь не авторизован");
    }

    final notesBox = Hive.box<Note>('notes');
    final notesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes');

    final snapshot = await notesRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final key = int.tryParse(doc.id);
      if (key == null) continue;

      Note note;

      if (notesBox.containsKey(key)) {
        note = notesBox.get(key)!;
      } else {
        note = Note(
          title: '',
          text: '',
          created: DateTime.now(),
          imagePaths: [],
          filePaths: [],
          tagIds: [],
        );
        await notesBox.put(key, note);
      }

      note
        ..title = data['title'] ?? ''
        ..text = data['text'] ?? ''
        ..created =
            (data['created'] as Timestamp?)?.toDate() ?? DateTime.now()
        ..reminderDate =
        (data['reminderDate'] as Timestamp?)?.toDate()
        ..isPinned = data['isPinned'] ?? false
        ..folderId = data['folderId']
        ..tagIds = List<int>.from(data['tagIds'] ?? []);

      await note.save();
    }
  }

  /// Синхронизация ВСЕХ заметок пользователя
  static Future<void> syncNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Пользователь не авторизован");
    }

    final notesBox = Hive.box<Note>('notes');
    final userNotesRef =
    _firestore.collection('users').doc(user.uid).collection('notes');

    // ---------- 1. Загрузка локальных заметок в Firestore ----------
    for (final note in notesBox.values) {
      if (note.isDeleted) continue;

      await userNotesRef.doc(note.key.toString()).set({
        'title': note.title,
        'text': note.text,
        'created': note.created,
        'reminderDate': note.reminderDate,
        'isPinned': note.isPinned,
        'folderId': note.folderId,
        'tagIds': note.tagIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ---------- 2. Загрузка заметок из Firestore в Hive ----------
    final snapshot = await userNotesRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final key = int.tryParse(doc.id);
      if (key == null) continue;

      Note note;

      if (notesBox.containsKey(key)) {
        note = notesBox.get(key)!;
      } else {
        note = Note(
          title: '',
          text: '',
          created: DateTime.now(),
          imagePaths: [],
          filePaths: [],
          tagIds: [],
        );
        await notesBox.put(key, note);
      }

      note
        ..title = data['title'] ?? ''
        ..text = data['text'] ?? ''
        ..created =
            (data['created'] as Timestamp?)?.toDate() ?? DateTime.now()
        ..reminderDate =
        (data['reminderDate'] as Timestamp?)?.toDate()
        ..isPinned = data['isPinned'] ?? false
        ..folderId = data['folderId']
        ..tagIds = List<int>.from(data['tagIds'] ?? []);

      await note.save();
    }
  }
}
