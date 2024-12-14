import 'package:reflect_buddy/reflect_buddy.dart';

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
