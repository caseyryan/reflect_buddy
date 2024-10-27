// ignore_for_file: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';

part 'human_json_serializable.g.dart';

/// json_serializable package is not required for reflect_buddy at all
/// but it's here to demonstrate that reflect_buddy
/// can also work with classes generated
/// using it and in this case it will call their methods toJson / fromJson
/// instead of building the class / map on the fly using mirrors
/// This might come useful when you want to reuse your flutter models
/// IMPORTANT! In this case NO annotations from reflect_buddy must be added
/// to any fields because they will not work nor in reflect_buddy neither in Flutter
@JsonSerializable(explicitToJson: true)
class HumanJsonSerializable {
  HumanJsonSerializable({
    this.age,
    this.name,
    this.hobbies,
  });

  int? age;
  String? name;
  List<String>? hobbies;

  factory HumanJsonSerializable.fromJson(Map<String, dynamic> json) {
    return _$HumanJsonSerializableFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$HumanJsonSerializableToJson(this);
  }
}
