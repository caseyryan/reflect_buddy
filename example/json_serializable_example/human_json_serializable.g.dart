// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'human_json_serializable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HumanJsonSerializable _$HumanJsonSerializableFromJson(
        Map<String, dynamic> json) =>
    HumanJsonSerializable(
      age: (json['age'] as num?)?.toInt(),
      name: json['name'] as String?,
      hobbies:
          (json['hobbies'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$HumanJsonSerializableToJson(
        HumanJsonSerializable instance) =>
    <String, dynamic>{
      'age': instance.age,
      'name': instance.name,
      'hobbies': instance.hobbies,
    };
