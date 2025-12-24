import 'package:hive/hive.dart';
import '../models/tag.dart';

class TagService {
  static Box<Tag> get _box => Hive.box<Tag>('tags');

  static Tag getOrCreate(String name) {
    final existing = _box.values.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Tag(name: name, color: 0xFF90CAF9),
    );

    if (!existing.isInBox) {
      _box.add(existing);
    }

    return existing;
  }

  static List<Tag> getAll() => _box.values.toList();

  static Tag? getById(int id) => _box.get(id);
}
