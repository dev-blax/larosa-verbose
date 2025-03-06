// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPostAdapter extends TypeAdapter<CachedPost> {
  @override
  final int typeId = 1;

  @override
  CachedPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPost(
      id: fields[0] as String,
      data: (fields[1] as Map).cast<String, dynamic>(),
      timestamp: fields[2] as int,
      mediaUrls: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPost obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.mediaUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
