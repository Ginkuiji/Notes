import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String text;

  @HiveField(2)
  DateTime created;

  @HiveField(3)
  List<String> imagePaths; // пути к фото

  @HiveField(4)
  List<String> filePaths;  // пути к файлам

  @HiveField(5)
  bool isDeleted;

  @HiveField(6)
  DateTime? reminderDate;

  @HiveField(7)
  List<int> tagIds;

  @HiveField(8)
  bool isPinned;

  @HiveField(9)
  int? folderId;

  @HiveField(10)
  bool isTask;

  @HiveField(11)
  bool isCompleted;

  Note({
    required this.title,
    required this.text,
    required this.created,
    List<String>? imagePaths,
    List<String>? filePaths,
    this.isDeleted = false,
    this.reminderDate,
    List<int>? tagIds,
    this.folderId,
    this.isPinned = false,
    this.isTask = false,
    this.isCompleted = false,
  })  : imagePaths = imagePaths ?? [],
        filePaths = filePaths ?? [],
        tagIds = tagIds ?? [];
}
