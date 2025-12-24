import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../services/notification_service.dart';
import '../services/tag_service.dart';

class NoteEditor extends StatefulWidget {
  final Note note;

  const NoteEditor({super.key, required this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();



}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _textController;

  bool _showTagInput = false;
  // final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    // _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  // ================= TAG HELPERS (M:N) =================

  List<Tag> _noteTags() {
    final tagBox = Hive.box<Tag>('tags');
    return widget.note.tagIds
        .map((id) => tagBox.get(id))
        .whereType<Tag>()
        .toList();
  }

  void _addTag(String name) {
    final tag = TagService.getOrCreate(name);

    if (!widget.note.tagIds.contains(tag.key)) {
      widget.note.tagIds.add(tag.key as int);
      widget.note.save();
    }

    //_tagController.clear();
    setState(() => _showTagInput = false);
  }

  void _removeTag(int tagId) {
    widget.note.tagIds.remove(tagId);
    widget.note.save();
    setState(() {});
  }

  // ================= ATTACHMENTS =================

  Future<void> addImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    widget.note.imagePaths.add(img.path);
    await widget.note.save();
    setState(() {});
  }

  Future<void> addCameraPhoto() async {
    final XFile? img = await picker.pickImage(source: ImageSource.camera);
    if (img == null) return;

    widget.note.imagePaths.add(img.path);
    await widget.note.save();
    setState(() {});
  }

  Future<void> addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    widget.note.filePaths.add(path);
    await widget.note.save();
    setState(() {});
  }

  void openFile(String path) {
    OpenFilex.open(path);
  }

  Future<void> deleteAttachment({
    required bool isImage,
    required int index,
  }) async {
    if (isImage) {
      widget.note.imagePaths.removeAt(index);
    } else {
      widget.note.filePaths.removeAt(index);
    }
    await widget.note.save();
    setState(() {});
  }

  Future<void> saveText() async {
    widget.note.title = _titleController.text;
    widget.note.text = _textController.text;
    await widget.note.save();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Редактор заметки"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await saveText();
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- TITLE ----------
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Название",
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),


            // ---------- TAG HEADER ----------
            Row(
              children: [
                const Text(
                  "Теги",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Добавить тег",
                  onPressed: () {
                    setState(() => _showTagInput = !_showTagInput);
                    if (_showTagInput) {
                      Future.delayed(
                        const Duration(milliseconds: 100),
                            () => _tagFocusNode.requestFocus(),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ---------- TAG LIST ----------
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _noteTags().map((tag) {
                return Chip(
                  label: Text(tag.name),
                  backgroundColor: Color(tag.color),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () =>
                      _removeTag(tag.key as int),
                );
              }).toList(),
            ),

            // ---------- TAG INPUT WITH AUTOCOMPLETE ----------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  SizeTransition(sizeFactor: animation, child: child),
              child: _showTagInput
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                    Autocomplete<Tag>(
                      optionsBuilder: (TextEditingValue value) {
                        final text = value.text.trim().toLowerCase();
                        if (text.isEmpty) return const Iterable<Tag>.empty();
                        print(
                            'ALL TAGS: ${TagService.getAll().map((t) => t.name).toList()}'
                        );
                        return TagService.getAll().where(
                          (tag) =>
                            tag.name.toLowerCase().contains(text) &&
                              !widget.note.tagIds.contains(tag.key),
                        );
                      },
                      displayStringForOption: (tag) => tag.name,
                      onSelected: (tag) => _addTag(tag.name),
                      fieldViewBuilder:
                          (context, controller, focusNode, _) {
                        return TextField(
                          controller: controller,
                          focusNode: _tagFocusNode,
                          decoration: const InputDecoration(
                            labelText: "Новый тег",
                            border: UnderlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            final name = value.trim();
                            if (name.isNotEmpty) {
                              _addTag(name);
                            }
                          },
                        );
                      },

                      optionsViewBuilder:
                          (context, onSelected, options){
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 48,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((tag) {
                                  return ListTile(
                                    title: Text(tag.name),
                                    onTap: () => onSelected(tag),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                        },
                    ),
                  )
                  : const SizedBox.shrink(),
                ),

            const SizedBox(height: 24),

            // ---------- REMINDER ----------
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(
                note.reminderDate == null
                    ? "Напоминание не установлено"
                    : "Напоминание: "
                    "${note.reminderDate!.day.toString().padLeft(2, '0')}."
                    "${note.reminderDate!.month.toString().padLeft(2, '0')}."
                    "${note.reminderDate!.year} "
                    "${note.reminderDate!.hour.toString().padLeft(2, '0')}:"
                    "${note.reminderDate!.minute.toString().padLeft(2, '0')}",
              ),
              onTap: () async {
                final now = DateTime.now();
                final initial = note.reminderDate ?? now;

                final date = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                  initialDate: initial,
                );
                if (date == null) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                if (time == null) return;

                note.reminderDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                await note.save();
                await NotificationService().scheduleReminder(note);
                setState(() {});
              },
              trailing: note.reminderDate != null
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () async {
                  await NotificationService().cancelReminder(note);
                  note.reminderDate = null;
                  await note.save();
                  setState(() {});
                },
              )
                  : null,
            ),

            const SizedBox(height: 16),

            // ---------- TEXT ----------
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: "Текст",
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- IMAGES ----------
            if (note.imagePaths.isNotEmpty) ...[
              const Text("Фото:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(note.imagePaths.length, (i) {
                  final path = note.imagePaths[i];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageFullscreen(path),
                        child: Image.file(File(path),
                          width: 120, height: 120, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () =>
                              deleteAttachment(isImage: true, index: i),
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],

            // ---------- FILES ----------
            if (note.filePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text("Файлы:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: List.generate(note.filePaths.length, (i) {
                  final path = note.filePaths[i];
                  final name =
                      path.split(Platform.pathSeparator).last;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(name),
                      onTap: () => openFile(path),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            deleteAttachment(isImage: false, index: i),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),

      // ---------- BOTTOM BAR ----------
      bottomNavigationBar: BottomAppBar(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: "Фото из галереи",
              icon: const Icon(Icons.photo, size: 28),
              onPressed: addImage,
            ),
            IconButton(
              tooltip: "Сделать фото",
              icon: const Icon(Icons.camera_alt, size: 28),
              onPressed: addCameraPhoto,
            ),
            IconButton(
              tooltip: "Прикрепить файл",
              icon: const Icon(Icons.attach_file, size: 28),
              onPressed: addFile,
            ),
          ],
        ),
      ),
    );
  }
  void _openImageFullscreen(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(File(path)),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
