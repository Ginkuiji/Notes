import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/notification_service.dart';
import '../models/note.dart';
import 'note_editor.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<DateTime, List<Note>> _buildEvents(Iterable<Note> notes) {
    final map = <DateTime, List<Note>>{};
    for (final n in notes) {
      final rd = n.reminderDate;
      if (rd == null) continue;
      if (n.isDeleted) continue;

      final day = _dateOnly(rd);
      (map[day] ??= []).add(n);
    }

    // сортируем заметки внутри дня по времени напоминания
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final notesBox = Hive.box<Note>('notes');

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),

      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (_, Box<Note> box, __) {
          final notes = box.values;
          final events = _buildEvents(notes);

          final selectedKey = _dateOnly(_selectedDay);
          final dayNotes = events[selectedKey] ?? const <Note>[];

          return Column(
            children: [
              TableCalendar<Note>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) =>
                    isSameDay(day, _selectedDay),
                eventLoader: (day) {
                  final key = _dateOnly(day);
                  return events[key] ?? const <Note>[];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: dayNotes.isEmpty
                    ? const Center(
                  child: Text('На этот день напоминаний нет'),
                )
                    : ListView.builder(
                  itemCount: dayNotes.length,
                  itemBuilder: (_, i) {
                    final note = dayNotes[i];
                    final rd = note.reminderDate!;
                    final time =
                        '${rd.hour.toString().padLeft(2, '0')}:${rd.minute.toString().padLeft(2, '0')}';

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.alarm),
                        title: Text(
                          note.title.isEmpty
                              ? 'Без названия'
                              : note.title,
                        ),
                        subtitle: Text(
                          '$time • ${note.text.isEmpty ? '(пусто)' : note.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NoteEditor(note: note),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ================= FAB ДОБАВЛЕНИЯ ЗАМЕТКИ =================
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить заметку на выбранный день',
        child: const Icon(Icons.add),
        onPressed: () async {
          final notesBox = Hive.box<Note>('notes');

          // напоминание на выбранный день в 00:00
          final reminderDate = DateTime(
            _selectedDay.year,
            _selectedDay.month,
            _selectedDay.day,
            0,
            0,
          );

          final newNote = Note(
            title: '',
            text: '',
            created: DateTime.now(),
            reminderDate: reminderDate,
            imagePaths: [],
            filePaths: [],
            tagIds: [],
          );

          await notesBox.add(newNote);

          // сразу планируем уведомление
          await NotificationService().scheduleReminder(newNote);

          // открываем редактор
          if (!mounted) return;
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
