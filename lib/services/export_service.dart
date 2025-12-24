import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class ExportService {
  /// Экспорт одной заметки в TXT
  static Future<File> exportNoteToTxt(Note note) async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception("Не удалось получить директорию");
    }

    final fileName =
        "note_${DateTime.now().millisecondsSinceEpoch}.txt";
    final file = File("${dir.path}/$fileName");

    final buffer = StringBuffer();

    buffer.writeln("ЗАМЕТКА");
    buffer.writeln("========");
    buffer.writeln();
    buffer.writeln("Название:");
    buffer.writeln(note.title.isEmpty ? "(без названия)" : note.title);
    buffer.writeln();
    buffer.writeln("Текст:");
    buffer.writeln(note.text.isEmpty ? "(пусто)" : note.text);
    buffer.writeln();

    buffer.writeln("Дата создания:");
    buffer.writeln(note.created.toString());

    if (note.reminderDate != null) {
      buffer.writeln();
      buffer.writeln("Напоминание:");
      buffer.writeln(note.reminderDate.toString());
    }

    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }
  /// Экспорт всех заметок в один TXT-файл

  static Future<File> exportAllNotesToTxt(List<Note> notes) async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception("Не удалось получить директорию");
    }

    final fileName =
        "all_notes_${DateTime.now().millisecondsSinceEpoch}.txt";
    final file = File("${dir.path}/$fileName");

    final buffer = StringBuffer();

    buffer.writeln("ВСЕ ЗАМЕТКИ");
    buffer.writeln("==========");
    buffer.writeln();

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];

      buffer.writeln("Заметка ${i + 1}");
      buffer.writeln("--------------------");

      buffer.writeln("Название:");
      buffer.writeln(note.title.isEmpty ? "(без названия)" : note.title);
      buffer.writeln();

      buffer.writeln("Текст:");
      buffer.writeln(note.text.isEmpty ? "(пусто)" : note.text);
      buffer.writeln();

      buffer.writeln("Дата создания:");
      buffer.writeln(note.created.toString());

      if (note.reminderDate != null) {
        buffer.writeln("Напоминание:");
        buffer.writeln(note.reminderDate.toString());
      }

      if (note.isTask) {
        buffer.writeln("Тип: Задача");
        buffer.writeln(
          note.isCompleted ? "Статус: выполнена" : "Статус: не выполнена",
        );
      }

      buffer.writeln();
      buffer.writeln("========================================");
      buffer.writeln();
    }

    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }
}
