// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      title: fields[0] as String,
      text: fields[1] as String,
      created: fields[2] as DateTime,
      imagePaths: (fields[3] as List?)?.cast<String>(),
      filePaths: (fields[4] as List?)?.cast<String>(),
      isDeleted: fields[5] as bool,
      reminderDate: fields[6] as DateTime?,
      tagIds: (fields[7] as List?)?.cast<int>(),
      folderId: fields[9] as int?,
      isPinned: fields[8] as bool,
      isTask: fields[10] as bool,
      isCompleted: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.created)
      ..writeByte(3)
      ..write(obj.imagePaths)
      ..writeByte(4)
      ..write(obj.filePaths)
      ..writeByte(5)
      ..write(obj.isDeleted)
      ..writeByte(6)
      ..write(obj.reminderDate)
      ..writeByte(7)
      ..write(obj.tagIds)
      ..writeByte(8)
      ..write(obj.isPinned)
      ..writeByte(9)
      ..write(obj.folderId)
      ..writeByte(10)
      ..write(obj.isTask)
      ..writeByte(11)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
