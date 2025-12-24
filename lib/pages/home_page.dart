import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../models/folder.dart';

import 'note_editor.dart';
import 'trash_page.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';
import '../services/folder_service.dart';
import '../services/export_service.dart';

// ================= WEATHER HEADER =================

class WeatherHeader extends StatefulWidget {
  const WeatherHeader({super.key});

  @override
  State<WeatherHeader> createState() => _WeatherHeaderState();
}

class _WeatherHeaderState extends State<WeatherHeader> {
  Map<String, dynamic>? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    try {
      final pos = await LocationService.getPosition();
      final data = await WeatherService.getWeather(
        lat: pos.latitude,
        lon: pos.longitude,
      );
      setState(() {
        weather = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text("Ошибка погоды: $error"),
      );
    }

    final temp = weather!["main"]["temp"].round();
    final desc = weather!["weather"][0]["description"];
    final city = weather!["name"];

    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.wb_sunny, size: 32),
        title: Text("$temp°C, $desc"),
        subtitle: Text(city),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: loadWeather,
        ),
      ),
    );
  }
}

// ================= HOME PAGE =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = "";
  String sortBy = "date";
  int? selectedFolderId;

  // ---------- FOLDER DELETE ----------

  void _confirmDeleteFolder(Folder folder) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Удалить папку?"),
        content: Text(
          "Все заметки из папки «${folder.name}» "
              "останутся, но будут перемещены в «Без папки».",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () async {
              await _deleteFolder(folder);
              Navigator.pop(context);
            },
            child: const Text(
              "Удалить",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(Folder folder) async {
    final notesBox = Hive.box<Note>('notes');

    for (final note in notesBox.values) {
      if (note.folderId == folder.key) {
        note.folderId = null;
        await note.save();
      }
    }

    await folder.delete();

    if (selectedFolderId == folder.key) {
      selectedFolderId = null;
    }

    setState(() {});
  }

  // ---------- TAG HELPERS ----------

  List<Tag> _noteTags(Note note) {
    final tagBox = Hive.box<Tag>('tags');
    return note.tagIds
        .map((id) => tagBox.get(id))
        .whereType<Tag>()
        .toList();
  }

  bool _noteHasTagMatching(Note note, String q) {
    return _noteTags(note)
        .any((t) => t.name.toLowerCase().contains(q));
  }

  String _firstTagName(Note note) {
    final tags = _noteTags(note);
    return tags.isEmpty ? "" : tags.first.name.toLowerCase();
  }

  // ---------- FOLDER BAR ----------

  Widget _buildFolderBar() {
    final folders = FolderService.getAll();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Все"),
            selected: selectedFolderId == null,
            onSelected: (_) => setState(() => selectedFolderId = null),
          ),
          const SizedBox(width: 8),
          ...folders.map((folder) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: () => _confirmDeleteFolder(folder),
                child: ChoiceChip(
                  label: Text(folder.name),
                  selected: selectedFolderId == folder.key,
                  onSelected: (_) =>
                      setState(() => selectedFolderId = folder.key as int),
                ),
              ),
            );
          }),
          ActionChip(
            avatar: const Icon(Icons.create_new_folder),
            label: const Text(""),
            onPressed: _createFolderDialog,
          ),
        ],
      ),
    );
  }

  void _createFolderDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Новая папка"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Название папки"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                FolderService.create(name);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Создать"),
          ),
        ],
      ),
    );
  }

  void _moveNoteToFolder(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final folders = FolderService.getAll();

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text("Без папки"),
                onTap: () async {
                  note.folderId = null;
                  await note.save();
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ...folders.map((folder) {
                return ListTile(
                  title: Text(folder.name),
                  onTap: () async {
                    note.folderId = folder.key as int;
                    await note.save();
                    setState(() {});
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final notesBox = Hive.box<Note>('notes');

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () async {
            final notesBox = Hive.box<Note>('notes');
            final notes =
            notesBox.values.where((n) => !n.isDeleted).toList();

            if (notes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Нет заметок для экспорта"),
                ),
              );
              return;
            }

            try {
              final file =
              await ExportService.exportAllNotesToTxt(notes);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Все заметки экспортированы:\n${file.path}",
                  ),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Ошибка экспорта: $e"),
                ),
              );
            }
          },
          child: const Text('Заметки'),
        ),
        actions: [
          DropdownButton<String>(
            value: sortBy,
            underline: const SizedBox(),
            icon: const Icon(Icons.sort, color: Colors.white),
            items: const [
              DropdownMenuItem(value: "date", child: Text("По дате")),
              DropdownMenuItem(value: "title", child: Text("По названию")),
              DropdownMenuItem(value: "tags", child: Text("По тегам")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => sortBy = value);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Корзина",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashPage()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Поиск...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v.toLowerCase()),
            ),
          ),

          const WeatherHeader(),
          _buildFolderBar(),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: notesBox.listenable(),
              builder: (_, Box<Note> box, __) {
                final notes = box.values.where((note) {
                  if (note.isDeleted) return false;

                  if (selectedFolderId != null &&
                      note.folderId != selectedFolderId) {
                    return false;
                  }

                  final q = query.trim();
                  if (q.isEmpty) return true;

                  return note.title.toLowerCase().contains(q) ||
                      note.text.toLowerCase().contains(q) ||
                      _noteHasTagMatching(note, q);
                }).toList();

                notes.sort((a, b) {
                  if (a.isPinned != b.isPinned) {
                    return a.isPinned ? -1 : 1;
                  }

                  // задачи: выполненные вниз
                  if (a.isTask && b.isTask &&
                      a.isCompleted != b.isCompleted) {
                    return a.isCompleted ? 1 : -1;
                  }

                  switch (sortBy) {
                    case "title":
                      return a.title
                          .toLowerCase()
                          .compareTo(b.title.toLowerCase());
                    case "tags":
                      return _firstTagName(a).compareTo(_firstTagName(b));
                    case "date":
                    default:
                      return b.created.compareTo(a.created);
                  }
                });

                if (notes.isEmpty) {
                  return const Center(child: Text("Нет заметок"));
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (_, index) {
                    final note = notes[index];
                    final tags = _noteTags(note);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),

                      leading: note.isTask
                          ? Checkbox(
                        value: note.isCompleted,
                        onChanged: (value) async {
                          note.isCompleted = value ?? false;
                          await note.save();
                          setState(() {});
                        },
                      )
                          : null,

                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty
                                  ? "Без названия"
                                  : note.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: note.isTask &&
                                    note.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: note.isTask &&
                                    note.isCompleted
                                    ? Colors.grey
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(tag.color),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag.name,
                                    style:
                                    const TextStyle(fontSize: 11),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (note.isPinned)
                            const Icon(Icons.push_pin,
                                size: 18, color: Colors.orange),
                        ],
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            note.text.isEmpty ? "(пусто)" : note.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${note.created.day.toString().padLeft(2, '0')}."
                                "${note.created.month.toString().padLeft(2, '0')}."
                                "${note.created.year}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteEditor(note: note),
                          ),
                        );
                      },

                      onLongPress: () async {
                        final result =
                        await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading:
                                  const Icon(Icons.check_box),
                                  title: Text(
                                    note.isTask
                                        ? "Снять отметку задачи"
                                        : "Сделать задачей",
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    note.isTask = !note.isTask;
                                    if (!note.isTask) {
                                      note.isCompleted = false;
                                    }
                                    await note.save();
                                    setState(() {});
                                  },
                                ),
                                ListTile(
                                  leading: Icon(note.isPinned
                                      ? Icons.push_pin_outlined
                                      : Icons.push_pin),
                                  title: Text(note.isPinned
                                      ? "Открепить"
                                      : "Закрепить"),
                                  onTap: () =>
                                      Navigator.pop(context, "pin"),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.folder),
                                  title:
                                  const Text("Переместить в папку"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _moveNoteToFolder(note);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: const Text("Экспортировать"),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    try {
                                      final file = await ExportService.exportNoteToTxt(note);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Заметка экспортирована:\n${file.path}",
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Ошибка экспорта: $e"),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading:
                                  const Icon(Icons.delete_outline),
                                  title:
                                  const Text("В корзину"),
                                  onTap: () =>
                                      Navigator.pop(context, "delete"),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (result == null) return;

                        if (result == "pin") {
                          note.isPinned = !note.isPinned;
                          await note.save();
                        } else if (result == "delete") {
                          await NotificationService()
                              .cancelReminder(note);
                          note.isDeleted = true;
                          await note.save();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newNote = Note(
            title: "",
            text: "",
            created: DateTime.now(),
            imagePaths: [],
            filePaths: [],
            tagIds: [],
            folderId: selectedFolderId,
          );

          await notesBox.add(newNote);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditor(note: newNote),
            ),
          );
        },
      ),
    );
  }
}
