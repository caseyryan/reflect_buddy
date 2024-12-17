import 'package:reflect_buddy/reflect_buddy.dart';

import 'reflect_buddy_example.dart';

// @JsonIncludeParentFields()
class User extends BaseModel {
  String? firstName;
  String? lastName;
  String? email;

  @JsonDateConverter(
    dateFormat: 'yyyy-MM-dd',
  )
  DateTime? birthDate;
}

class BaseModel {
  int? id;
  @JsonDateConverter(dateFormat: 'yyyy_MM_dd')
  DateTime? createdAt;
  DateTime? updatedAt;
}

/// this is here to test instantiation
/// of types that just don't have a default constructor
class BadRequestException extends NoDefaultConstructor {
  BadRequestException(
    this.car1, {
    required super.message,
    required this.car2,
  });

  final Car car1;
  final Car? car2;
}

class NoDefaultConstructor {
  String? message;
  NoDefaultConstructor({
    this.message,
  });
}
