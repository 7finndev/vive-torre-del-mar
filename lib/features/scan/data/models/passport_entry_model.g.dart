// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PassportEntryModelAdapter extends TypeAdapter<PassportEntryModel> {
  @override
  final int typeId = 4;

  @override
  PassportEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PassportEntryModel(
      establishmentName: fields[0] as String,
      establishmentId: fields[1] as int,
      scannedAt: fields[2] as DateTime,
      isSynced: fields[3] as bool,
      rating: fields[4] as int,
      eventId: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PassportEntryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.establishmentName)
      ..writeByte(1)
      ..write(obj.establishmentId)
      ..writeByte(2)
      ..write(obj.scannedAt)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.rating)
      ..writeByte(5)
      ..write(obj.eventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassportEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PassportEntryModel _$PassportEntryModelFromJson(Map<String, dynamic> json) =>
    PassportEntryModel(
      establishmentName: json['establishmentName'] as String,
      establishmentId: (json['product_id'] as num).toInt(),
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      eventId: (json['event_id'] as num).toInt(),
    );

Map<String, dynamic> _$PassportEntryModelToJson(PassportEntryModel instance) =>
    <String, dynamic>{
      'establishmentName': instance.establishmentName,
      'product_id': instance.establishmentId,
      'scanned_at': instance.scannedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'rating': instance.rating,
      'event_id': instance.eventId,
    };
