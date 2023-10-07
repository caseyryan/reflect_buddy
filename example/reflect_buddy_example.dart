// ignore_for_file: unused_field

import 'package:reflect_buddy/reflect_buddy.dart';

/// Notice that this Enum also does not have any annotations
/// or helper methods
enum Gender {
  male,
  female,
}

void main() {
  /// Just uncomment any example to run it
  // _processSimpleUser();
  // _processSimpleUserWithPrivateId();
  // _processUserWrapperWithCustomDate();
  // _keyNameConversion();
  // _convertKeyNamesByClassAnnotation();
  // _validateContacts();
  final result = 'Some string'.toJson();
  print(result);
}

/// Applies different contact validators
void _validateContacts() {
  final instance = fromJson<ContactData>({
    'email': 'konstantin@github.com',

    /// the white spaces will be trimmed by  @TrimString() annotation
    'name': '     Константин     ',
  });
  print(instance);
  final json = instance?.toJson(
    keyNameConverter: CamelToSnake(),
  );
  print(json);
}

class ContactData {
  @EmailValidator(canBeNull: false)
  String? email;

  @TrimString()
  @NameValidator(canBeNull: false)
  String? name;
}

void _convertKeyNamesByClassAnnotation() {
  final instance = fromJson<SimpleUserClassKeyNames>({
    'firstName': 'Konstantin',
    'lastName': 'Serov',
    'age': 36,
    'gender': 'male',
    'dateOfBirth': '1987-01-02T21:50:45.241520'
  });
  print(instance);
  final json = instance?.toJson(
    keyNameConverter: CamelToSnake(),
  );
  print(json);
}

/// The most simple case. A flat structure with built-in types
/// outputs:
/// Instance of 'SimpleUser'
/// {firstName: Konstantin, lastName: Serov, age: 36, gender: male, dateOfBirth: 1987-01-02T21:50:45.241520}
void _processSimpleUser() {
  final instance = fromJson<SimpleUser>({
    'firstName': 'Konstantin',
    'lastName': 'Serov',
    'age': 36,
    'gender': 'male',
    'dateOfBirth': '1987-01-02T21:50:45.241520'
  });
  print(instance);
  final json = instance?.toJson();
  print(json);
}

void _processSimpleUserWithPrivateId() {
  final instance = fromJson<SimpleUserWithPrivateId>({
    '_id': 'userId888',
    'firstName': 'Konstantin',
    'lastName': 'Serov',
    'age': 36,
    'gender': 'male',
    'dateOfBirth': '1987-01-02T21:50:45.241520'
  });
  print(instance);
  final json = instance?.toJson();
  print(json);
}

/// This instance has key converter annotations applied to its fields
/// see inside [SimpleUserKeyConversion]
void _keyNameConversion() {
  final instance = fromJson<SimpleUserKeyConversion>({
    'firstName': 'Konstantin',
    'lastName': 'Serov',
    'age': 36,
    'gender': 'male',
    'dateOfBirth': '1987-01-02T21:50:45.241520'
  });
  print(instance);
  final json = instance?.toJson();
  print(json);
}

/// Easy case. This type of class is
/// the most simple to deserialize
/// from JSON. All variable types are primitive
class SimpleUser {
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

class SimpleUserWithPrivateId {
  @JsonInclude()
  String? _id;
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

/// An example of key transformation
class SimpleUserKeyConversion {
  @CamelToSnake()
  String? firstName;
  @CamelToSnake()
  String? lastName;

  @FirstToUpper()
  int age = 0;
  @FirstToUpper()
  Gender? gender;
  @FirstToUpper()
  DateTime? dateOfBirth;
}

@CamelToSnake()
class SimpleUserClassKeyNames {
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

/// This is a bit more complex example as it includes
/// not flat structure and a date formatting annotation
/// outputs: Instance of 'SimpleContainerWithCustomClass'
/// {id: userId123, user: {firstName: Konstantin, lastName: Serov, age: 36, gender: male, dateOfBirth: 1987_01_01}}
void _processUserWrapperWithCustomDate() {
  final instance = fromJson<SimpleContainerWithCustomClass>({
    'id': 'userId123',
    'user': {
      'firstName': 'Konstantin',
      'lastName': 'Serov',
      'age': 36,
      'gender': 'male',
      'dateOfBirth': '1987_01_01'
    }
  });
  print(instance);
  final json = instance?.toJson();
  print(json);
}

/// A bit more complex but nothing much
class SimpleContainerWithCustomClass {
  String? id;
  SimpleUserWithCustomDateFormat? user;
}

class SimpleUserWithCustomDateFormat {
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;

  /// Applies a custom format to a date. It works in both directions
  @JsonDateConverter(dateFormat: 'yyyy_MM_dd')
  DateTime? dateOfBirth;
}

/// Even more complex but still not that much
class ContainerWithCustomList {
  String? id;
  List<SimpleUser>? users;
}

const containerWithCustomList = {
  'id': 'userId123',
  'users': [
    {
      'firstName': 'Konstantin',
      'lastName': 'Serov',
      'age': 36,
      'dateOfBirth': '1987_01_02',
    },
  ]
};

/// More complex than the list example because
/// requires instantiation of a generic map
class ContainerWithCustomMap {
  String? id;
  Map<String, SimpleUser>? users;
}

const containerWithCustomMap = {
  'id': 'userId123',
  'users': {
    'first': {
      'firstName': 'Konstantin',
      'lastName': 'Serov',
      'age': 36,
    },
    'second': {
      'firstName': 'Karolina',
      'lastName': 'Serova',
      'age': 5,
    },
  }
};

/// One of the most challenging cases
/// that requires instantiating classes with
/// complex generic types
class ContainerWithCustomGenerics {
  String? id;
  Map<String, List<SimpleUser>>? users;
}

const containerWithCustomGenerics = {
  'id': 'userId123',
  'users': {
    'listOfUsers': [
      {
        'firstName': 'Konstantin',
        'lastName': 'Serov',
        'age': 36,
      },
    ],
  }
};
