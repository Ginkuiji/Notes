import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 2) // НОВЫЙ уникальный typeId
class Folder extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime created;

  Folder({
    required this.name,
    required this.created,
  });
}
