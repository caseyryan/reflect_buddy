# Reflect Buddy 

## A powerful live Dart JSON serializer / deserializer based on reflection ([dart:mirrors](https://api.dart.dev/stable/3.1.3/dart-mirrors/dart-mirrors-library.html))

- [Small Intro](#small-intro)
- [The concept](#the-concept)
    - [Background](#background)
    - [How it works](#how-it-works)
    - [Limitations](#limitations)
    - [Supported built-in types](#supported-built-in-types)
    - [Advantages](#advantages)
    - [Disadvantages](#disadvantages)
- [Getting started](#getting-started)
- [Ignoring or Including fields](#ignoring-or-including-fields)
- [Using annotations](#using-annotations)
- [Validators](#validators)
- [Value converters](#validators)
- [List of Annotations](#list-of-annotations)


---
If you want to support my development you can donate some `ETH / USDT`
**0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1**

<img src="https://github.com/caseyryan/reflect_buddy/blob/master/trust.jpg?raw=true" width="220"/>

[Donate via Trust Wallet](https://link.trustwallet.com/send?address=0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1&asset=c60)

---

## Small Intro

Having been involved in a C# development in the past, I always liked its ability to serialize and deserialize ordinary objects without any problems. There is no need to prepare any models, and field management can be done using attributes. To develop an easy-to-use backend, I really missed such functionality in Dart. So I decided to develop it. Meet **Reflect Buddy**

## The concept
This library is used to generate strictly typed objects based on JSON input without the need to prepare any models in advance. It works at runtime, literally on the fly.

Most of the serializers in Dart are written using code builders. This is due to the fact that, most often, they are used with [Flutter](https://flutter.dev), the release assembly of which uses, so called, [Ahead of Time](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation. The [AOT](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation, makes it impossible to assemble types at runtime. All of the types there are known in advance.

Unlike other serializers, **Reflect Buddy** uses [Just-in-Time](https://en.wikipedia.org/wiki/Just-in-time_compilation) compilation and does not require any pre-built models. Almost any regular class can be serialized/deserialized by calling just one method.

### Background
The tool was originally developed as a component of my other project: [Dart Net Core API](https://github.com/caseyryan/dart_net_core_api), also inspired (to some extent) by a C# library calles [Dotnet Core API](https://dotnet.microsoft.com/en-us/apps/aspnet/apis). But, since it may be useful for other developments, I decided to put it in a separate package

### How it works
Imagine you have some class, for example a User, which contains the typical 
values like first name, last name, age, id and other stuff like that. You want to send the instance of the user over a network. Of course you need to serialize it to some simple data like a JSON String.сщ  

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
```
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
  Gender? gender;
}

enum Gender {
  male,
  female,
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

Any work with JSON sometimes requires hiding or, conversely, adding certain keys to the output.
For example, in your User model, `_id` is a private field, but you want to return it to the frontend to be able to uniquely identify the object.
By default, **Reflect Buddy** ignores private fields, but you can force them into json by adding the `@JsonInclude()` annotation to the field

```dart
class SimpleUserWithPrivateId {
  @JsonInclude()
  String? _id;
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

/// This will also include a private `_id` field

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

```


## Using annotations

Above there was already an example of using annotations. The example with `@JsonInclude()`. The library also has several more types of built-in annotations. One of them is @JsonIgnore(). You can add it to any field you want to exclude from the output. After which the field will no longer be included in JSON, even if it is filled in the model

```dart
class SimpleUser {

  /// This will exclude firstName from a resulting JSON
  @JsonIgnore()
  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

```

## Validators

There is also often a need to validate values before assigning them. You can use `JsonValueValidator` descendants for this purpose. This is the abstract class with only one method called `validate`. The method is called internally by **Reflect Buddy** and it accepts two arguments: the actual value that is about to be assigned to a field and the name of the field (for logging purposes). 
You can extend `JsonValueValidator` class and write your own logic of a value validation for any fields ypu want. If the value is invalid, just throw an exception. You can see an example of such an implementation in `JsonNumValidator`

```dart 
class JsonNumValidator extends JsonValueValidator {
  const JsonNumValidator({
    required this.minValue,
    required this.maxValue,
    required this.canBeNull,
  });

  final num minValue;
  final num maxValue;
  final bool canBeNull;

  @override
  void validate({
    num? actualValue,
    required String fieldName,
  }) {
    if (!canBeNull) {
      if (actualValue == null) {
        throw Exception(
          '"$actualValue" value is not allowed for [$fieldName]',
        );
      }
    }
    if (actualValue != null) {
      if (actualValue < minValue || actualValue > maxValue) {
        throw Exception(
          '"$actualValue" is out of scope for "$fieldName" expected ($minValue - $maxValue)',
        );
      }
    }
  }
}
```

## Value converters

Another possible use case for annotations is data conversion.
Imagine that you don't want to throw an exception if a value is out of bounds, but you also don't want to assign an invalid value. In this case, you can use a descendant of the `JsonValueConverter` class.

Just like with `JsonValueValidator`, you can extend `JsonValueConverter` and write your own implementation for the `Object? convert(covariant Object? value);` method

An example of such an implementation can be seen in this `JsonDateConverter`

```dart
class JsonDateConverter extends JsonValueConverter {
  const JsonDateConverter({
    required this.dateFormat,
  });

  final String dateFormat;

  @override
  Object? convert(covariant Object? value) {
    if (value is String) {
      return DateFormat(dateFormat).parse(value);
    } else if (value is DateTime) {
      return DateFormat(dateFormat).format(value);
    }
    return null;
  }
}

```

Or this one. It just clamps a numeric value

```dart
class JsonNumConverter extends JsonValueConverter {
  const JsonNumConverter({
    required this.minValue,
    required this.maxValue,
    required this.canBeNull,
  });
  final num minValue;
  final num maxValue;
  final bool canBeNull;

  @override
  num? convert(covariant num? value) {
    if (value == null) {
      if (canBeNull) {
        return value;
      }
      return minValue;
    }
    return value.clamp(minValue, maxValue);
  }
}

```




## List of Built-in annotations


## Writing custom annotations