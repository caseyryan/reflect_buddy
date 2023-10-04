import 'package:reflect_buddy/reflect_buddy.dart';

/// Easy-peasy. This type of class is
/// the most simple to deserialize
/// from JSON. All variable types are primitive
class SimpleUser {
  String? firstName;
  String? lastName;
  int age = 0;

  /// Notice that it can parse some weird stuff like this
  @JsonDateConverter(dateFormat: 'yyyy_MM_dd')
  DateTime? dateOfBirth;
}

const Map simpleUser = {
  'firstName': 'Konstantin',
  'lastName': 'Serov',
  'age': 36,
  'dateOfBirth': '1987_01_02',
};

/// A bit more complex but nothing much
class SimpleContainerWithCustomClass {
  String? id;
  SimpleUser? user;
}

const simpleContainerWithCustomClass = {
  'id': 'userId123',
  'user': {
    'firstName': 'Konstantin',
    'lastName': 'Serov',
    'age': 36,
  }
};

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
      // 'dateOfBirth': '1987-01-02T21:50:45.241520',
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
