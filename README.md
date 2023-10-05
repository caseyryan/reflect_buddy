# Reflect Buddy 

## A powerful live Dart JSON serializer / deserializer based on reflection ([dart:mirrors](https://api.dart.dev/stable/3.1.3/dart-mirrors/dart-mirrors-library.html))

- [The concept](#the-concept)
    - [Background](#background)
    - [How it works](#how-it-works)
    - [Limitations](#limitations)
    - [Supported built-in types](#supported-built-in-types)
    - [Advantages](#advantages)
    - [Disadvantages](#disadvantages)
- [Getting started](#getting-started)
- [Serializing / Deserializing simple classes](#serializing-deserializing-simple-classes)
- [Using annotations](#using-annotations)
- [List of Built-in annotations](#list-of-built-in-annotations)
- [Writing custom annotations](#writing-custom-annotations)

---
If you want to support my development you can donate some `ETH / USDT`
**0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1**

<img src="https://github.com/caseyryan/reflect_buddy/blob/master/trust.jpg?raw=true" width="220"/>

[Donate via Trust Wallet](https://link.trustwallet.com/send?address=0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1&asset=c60)

---

## The concept
This library is used to generate strictly typed objects based on JSON input without the necessity to prepare any models in advance. Literally in runtime.

Most of the serializers in Dart are written using code builders. This is due to the fact that, most often, they are used with [Flutter](https://flutter.dev), the release assembly of which uses, so called, [Ahead of Time](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation. The [AOT](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation, makes it impossible to assemble types at runtime. All of the times there are known in advance.

Unlike other serializers, **Reflect Buddy** uses [Just-in-Time](https://en.wikipedia.org/wiki/Just-in-time_compilation) compilation and does not require any pre-built models. Almost any regular class can be serialized/deserialized by calling just one method.

### Background
The tool was originally developed as a component of my other project: [Dart Net Core API](https://github.com/caseyryan/dart_net_core_api). But, since it may be useful for other developments, I decided to put it in a separate package

### How it works
Imagine you have some class, for example a User, which contains the typical 
values like first name, last name, age, id and other stuff like that. You want to send the instance of the user over a network. Of course you need to serialize it to some simple data like a JSON String.  

Usually you need to write toJson() method by hand or use some template for a code generator like this package [json_serializable](https://pub.dev/packages/json_serializable). It's a very good option if you use The [AOT](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation. But in [JIT](https://en.wikipedia.org/wiki/Just-in-time_compilation) you can dramatically simplify it by just calling ```toJson()``` on any instance. That's it. It is really that simple

A class like this is completely ready to work with **Reflect Buddy**. As you can see there is absolutely nothing special here. It's just a regular [Dart](https://dart.dev/language/classes) class. 

```dart
class User {
  String? firstName;
  String? lastName;
  int age = 0;
  DateTime? dateOfBirth;
}
```

You can use nullable or non-nullable fields. You can also use `late` modifier. But be careful with that, since if you don't provide a value for a field in your json, it will fail at runtime. So I would recommend using default values or nullable types instead. But it's up to you. 


### Limitations

- **Reflect Buddy** can work with basic structures: [Map](https://api.dart.dev/stable/3.1.3/dart-core/Map-class.html) and [List](https://api.dart.dev/stable/3.1.3/dart-core/List-class.html). It **cannot** work with more exotic type like [Set](https://api.dart.dev/stable/3.1.3/dart-core/Set-class.html) so you have to plan your classes with JSON in mind.
Below is the list of built-in types it can work with by default (including generic modifications):

- **Reflect Buddy** can work **only** with [JIT](https://en.wikipedia.org/wiki/Just-in-time_compilation) compilation. So it **won't** work with [Flutter](https://flutter.dev), so don't even try it. For [Flutter](https://flutter.dev) I recommend [json_serializable](https://pub.dev/packages/json_serializable)


### Supported built-in types
* [Map](https://api.dart.dev/stable/3.1.3/dart-core/Map-class.html) + generics
* [List](https://api.dart.dev/stable/3.1.3/dart-core/List-class.html) + generics
* [DateTime](https://api.dart.dev/stable/3.1.3/dart-core/DateTime-class.html) + can use ```@JsonDateConverter(dateFormat: 'yyyy_MM_dd')``` with custom format. Which works in both directions. You can see it in examples
* [String](https://api.dart.dev/stable/3.1.3/dart-core/String-class.html)
* [double](https://api.dart.dev/stable/3.1.3/dart-core/double-class.html)
* [int](https://api.dart.dev/stable/3.1.3/dart-core/int-class.html)
* [num](https://api.dart.dev/stable/3.1.3/dart-core/num-class.html)
* [bool](https://api.dart.dev/stable/3.1.3/dart-core/bool-class.html)
* [Enum](https://api.dart.dev/stable/3.1.3/dart-core/Enum-class.html)

## Getting started

Import the library
```dart
import 'package:reflect_buddy/reflect_buddy.dart';
```

Get some JSON you want to deserialize to a typed object, e.g.
```json
const containerWithUsers = {
  'id': 'userId123',
  'users': {
    'male': {
      'firstName': 'Konstantin',
      'lastName': 'Serov',
      'age': 36,
      'dateOfBirth': '2018-01-01T21:50:45.241520'
    },
    'female': {
      'firstName': 'Karolina',
      'lastName': 'Serova',
      'age': 5,
      'dateOfBirth': '2018-01-01T21:50:45.241520'
    },
  }
};
```

And types to deserialize to. They **must** exactly correspond to the structure of you JSON
```dart
class ContainerWithCustomUsers {
  String? id;
  Map<String, User>? users;
}

class User {
  String? firstName;
  String? lastName;
  int age = 0;
  DateTime? dateOfBirth;
}

```

There is tree ways to create an instance of `ContainerWithCustomUsers` from JSON. They all use the same logic under the hood. So just pick the one you like the most.

1. Call `fromJson` method directly on a type like this (parentheses are required here to distinguish this call from a static method call)
```dart
final containerInstance = (ContainerWithCustomUsers).fromJson(containerWithUsers);

```
2. Use a generic shorthand method 
```dart
final containerInstance = fromJson<ContainerWithCustomUsers>(containerWithUsers);
```

3. Object extension method
```dart
final containerInstance = containerWithUsers.toInstance<ContainerWithCustomUsers>();

```




## Serializing / Deserializing simple classes


## Using annotations


## List of Built-in annotations


## Writing custom annotations