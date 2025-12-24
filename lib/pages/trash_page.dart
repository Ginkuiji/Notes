import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notesBox = Hive.box<Note>('notes');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Корзина"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Очистить корзину",
            onPressed: () {
              for (final note in notesBox.values) {
                if (note.isDeleted) note.delete();
              }
            },
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (_, Box<Note> box, __) {
          final deletedNotes =
          box.values.where((note) => note.isDeleted).toList();

          if (deletedNotes.isEmpty) {
            return const Center(child: Text("Корзина пуста"));
          }

          return ListView.builder(
            itemCount: deletedNotes.length,
            itemBuilder: (_, index) {
              final note = deletedNotes[index];

              return ListTile(
                title: Text(
                  note.title.isEmpty ? "Без названия" : note.title,
                  style: const TextStyle(decoration: TextDecoration.lineThrough),
                ),
                subtitle: Text(
                  note.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Восстановление заметки
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    note.isDeleted = false;
                    note.save();
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
