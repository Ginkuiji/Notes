import 'package:hive/hive.dart';
import '../models/folder.dart';

class FolderService {
  static Box<Folder> get _box => Hive.box<Folder>('folders');

  static List<Folder> getAll() =>
      _box.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  static Folder create(String name) {
    final folder = Folder(
      name: name,
      created: DateTime.now(),
    );
    _box.add(folder);
    return folder;
  }
}
