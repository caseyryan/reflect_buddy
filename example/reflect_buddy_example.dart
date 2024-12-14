// ignore_for_file: unused_field, unused_element

import 'package:reflect_buddy/reflect_buddy.dart';

import 'json_serializable_example/human_json_serializable.dart';
import 'test_models.dart';

/// Notice that this Enum also does not have any annotations
/// or helper methods
enum Gender {
  male,
  female,
}

@CamelToSnake()
class Car {
  int? id;

  String? manufacturer;
  int? enginePower;
}

void main() {
  /// Just uncomment any example to run it
  // _chainedInheritance();
  // _processSimpleUser();
  // _processSimpleUserWithPrivateId();
  // _processUserWrapperWithCustomDate();
  // _keyNameConversion();
  // _convertKeyNamesByClassAnnotation();
  // _validateContacts();
  // _processJsonSerializable();
  // _tryIgnoreDefaultValues();
  // _toJsonWithDefaultValues();
  // _carFromJson();
  // final data = (User).fromJson({
  //   // 'id': 1,
  // });
  // print(data);
  useCamelToStakeForAll = true;
  alwaysIncludeParentFields = true;
  var user = User()
    ..id = 1
    ..firstName = 'Konstantin'
    ..createdAt = DateTime.now();

  final map = user.toJson() as Map;
  print(map);

  var newUser = (User).fromJson({
    'bithDate': '2022-01-01T21:50:45.241520',
  });
  print(newUser);
}

void _carFromJson() {
  final car = fromJson<Car>(
    {
      'id': 1,
      'manufacturer': 'BMW',
      'engine_power': 100,
    },
  );
  print(car);
}

void _toJsonWithDefaultValues() {}

void _tryIgnoreDefaultValues() {
  final emptyMap = {};
  final defaulted = fromJson<Defaulted>(emptyMap);
  print(defaulted);
}

class Defaulted {
  bool name = true;
}

void _processJsonSerializable() {
  final map = {
    'age': 37,
    'name': 'Konstantin',
    'hobbies': ['reading', 'running']
  };

  /// it is intentionally called this way to first call
  /// the fromJson method built into the reflect_buddy.
  /// But it will still find the fromJson method of the json_serializable
  /// class and call it internally
  final human = (HumanJsonSerializable).fromJson(map);
  print(human);
  final json = human?.toJson(
    tryUseNativeSerializerMethodsIfAny: true,
  );
  print(json);
}

/// This example demonstrates how [JsonIncludeParentFields]
/// annotation works. The field called `firstName` is declared in a
/// superclass. But since [Child] is annotated with [JsonIncludeParentFields]
/// parent fields will also be included
void _chainedInheritance() {
  final child = Child()
    ..age = 5
    ..firstName = 'Caroline';
  final json = child.toJson();
  print(json);
}

class Parent {
  String? firstName;
}

@JsonIncludeParentFields()
class Child extends Parent {
  int? age;
}

/// Applies different contact validators
void _validateContacts() {
  final instance = fromJson<ContactData>({
    'email': 'konstantin@github.com',

    /// the white spaces will be trimmed by  @JsonTrimString() annotation
    'name': '     Константин     ',
    'phone': '+7 (945) 234-12-12',
    // 'creditCard': '5479 9588 6475 9774',
    'creditCard': '5536 9138 3148 5962',
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
  @PhoneValidator(canBeNull: false)
  String? phone;
  @CreditCardNumberValidator(
    canBeNull: false,
    useLuhnAlgo: true,
  )
  String? creditCard;

  @JsonTrimString()
  @NameValidator(canBeNull: false)
  String? name;
}

void _convertKeyNamesByClassAnnotation() {
  final instance = fromJson<SimpleUserClassKeyNames>(
    {
      'firstName': 'Konstantin',
      'lastName': 'Serov',
      'age': 36,
      'gender': 'male',
      'dateOfBirth': '1987-01-02T21:50:45.241520'
    },
    tryApplyReversedKeyConversion: true,
  );
  print(instance);
  final json = instance?.toJson(
    // keyNameConverter: CamelToSnake(),
    onKeyConversion: (ConvertedKey result) {
      print(result);
    },
  );
  print(json);

  /// Notice that the key conversion is reversed here
  // final reverseKeyInstance = (SimpleUserClassKeyNames).fromJson(
  //   json,
  //   onKeyConversion: (ConvertedKey result) {
  //     // print(result);
  //   },
  // );
  // print(reverseKeyInstance);
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
