// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 1;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      id: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as String,
      status: fields[3] as String,
      themeColorHex: fields[4] as String,
      logoUrl: fields[5] as String?,
      bgImageUrl: fields[6] as String?,
      basePrice: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.themeColorHex)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.bgImageUrl)
      ..writeByte(7)
      ..write(obj.basePrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      themeColorHex: json['theme_color_hex'] as String,
      logoUrl: json['logo_url'] as String?,
      bgImageUrl: json['bg_image_url'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'theme_color_hex': instance.themeColorHex,
      'logo_url': instance.logoUrl,
      'bg_image_url': instance.bgImageUrl,
      'base_price': instance.basePrice,
    };
