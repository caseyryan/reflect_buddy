# Reflect Buddy 

<a href="https://pub.dev/packages/reflect_buddy"><img src="https://img.shields.io/pub/v/reflect_buddy?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) 

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
- [Serializing and deserializing classes](#serializing-and-deserializing-classes)
- [Using annotations](#using-annotations)
- [Validators](#validators)
- [Value converters](#value-converters)
- [Key name converters](#key-name-converters)
- [List of Built-In Annotations](#list-of-built-in-annotations)
- [Writing custom annotations](#writing-custom-annotations)


---
If you want to support my development you can donate some `ETH / USDT`
**0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1**

<img src="https://github.com/caseyryan/reflect_buddy/blob/master/trust.jpg?raw=true" width="220"/>

[Donate via Trust Wallet](https://link.trustwallet.com/send?address=0xaDed99fda2AA53B3aFC8bB2d27b14910dB9CEdA1&asset=c60)

---

## Small Intro

Having been involved in a C# development in the past, I always liked its ability to serialize and deserialize ordinary objects without any problems. There is no need to prepare any models, and field management can be done using attributes. To write an easy-to-use backend solution, I really missed such a functionality in Dart. So I decided to develop it myself. Meet **Reflect Buddy**:

## The concept
This library is used to generate strictly typed objects based on JSON input without the need to prepare any models in advance. It works at runtime, literally on the fly.
The library can serialize and deserialize objects with any nesting depth.

Most of the serializers in Dart are written using code builders. This is due to the fact that, most often, they are used with [Flutter](https://flutter.dev), the release assembly of which uses, so called, [Ahead of Time](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation. The [AOT](https://en.wikipedia.org/wiki/Ahead-of-time_compilation) compilation, makes it impossible to assemble types at runtime. All of the types there are known in advance.

Unlike other serializers, **Reflect Buddy** uses [Just-in-Time](https://en.wikipedia.org/wiki/Just-in-time_compilation) compilation and does not require any pre-built models. Almost any regular class can be serialized/deserialized by calling just one method.

### Background
The tool was originally developed as a component of my other project: [Dart Net Core API](https://github.com/caseyryan/dart_net_core_api), also inspired (to some extent) by a C# library calles [Dotnet Core API](https://dotnet.microsoft.com/en-us/apps/aspnet/apis). But, since it may be useful for other developments, I decided to put it in a separate package

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

There are three ways to create an instance of `ContainerWithCustomUsers` from JSON. They all use the same logic under the hood. So just pick the one you like the most.

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


## Serializing and deserializing classes

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
You can extend `JsonValueValidator` class and write your own logic of a value validation for any fields you want. If the value is invalid, just throw an exception. 

Here's an example of the `NumValidator` descendant

```dart 
class NumValidator extends JsonValueValidator {
  const NumValidator({
    required this.minValue,
    required this.maxValue,
    required super.canBeNull,
  });

  final num minValue;
  final num maxValue;

  @override
  void validate({
    num? actualValue,
    required String fieldName,
  }) {
    if (checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    )) {
      if (actualValue! < minValue || actualValue > maxValue) {
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
In `JsonDateConverter` you can pass any date format and it will be used to parse a date from or to a String. For example:
```dart
@JsonDateConverter(dateFormat: 'yyyy-MM-dd')
```

This will allow you to have custom date representation in your JSON


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

## Key name converters

There are certain scenarios in which you need to change the key names in the output JSON. For example, in the database they are stored as a `camelCase`, but on the front end a `snake_case` (or something else) is expected.
**Reflect Buddy** has special annotations for this case too. They inherit from `JsonKeyNameConverter`. Here is an example of using several different converters. 

```dart 

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

```

Calling `toJson()` on an instance of this class, will lead to a result like this:

```
{first_name: Konstantin, last_name: Serov, Age: 36, Gender: male, DateOfBirth: 1987-01-02T21:50:45.241520}
```

Of course, if you use the same key naming strategy for all fields, then it would be stupid to write an annotation for each field separately. In this case you have two options:

1. You can pass a descendant of a `JsonKeyNameConverter` as a parameter to the 
```dart 
  Object? toJson({
    bool includeNullValues = false,
    JsonKeyNameConverter? keyNameConverter,
  }) {
    ...  
  }

``` 
method

2. You can annotate the whole class like this:
```dart
@CamelToSnake()
class SimpleUserClassKeyNames {

  String? firstName;
  String? lastName;
  int age = 0;
  Gender? gender;
  DateTime? dateOfBirth;
}

```

But keep in mind, that field annotations have a higher priority over all 
other options. And they will override whatever you use on a class or pass to the `toJson()` method arguments. And the argument will override the class level annotation.

So the hierarchy is like this:
* Field level annotation
  * argument (of `toJson()`)
    * Class level annotation
 
**Notice** that another way to change the key name is to add a
```dart
@JsonKey(name: 'someNewName')
```
annotation to a field

In this case, `JsonKey` will have the highest priority over any name converters


## List of Built-In Annotations

### Field rules
- `@JsonInclude()` - a field level annotation which forces the key/value to be included to a resulting JSON
event if the field is private
- `@JsonIgnore()` - the reverse of `JsonInclude`. It completely excludes the field from being serialized
- `@JsonKey()` - **base class** for a field rule

### Validators
- `@JsonValueValidator()` - **base class** can be extended for any type validation
- `@IntValidator()` - this annotation allows to to check if an int value is within the allowed rand. It will throw an exception if the value is beyond that
- `@DoubleValidator()` - the same as int validator but for double
- `@NumValidator()` - the same as int validator but for double
- `@StringValidator()` - can validate a string against a regular expression pattern
- `@EmailValidator()` - validates an email against a regular expression
- `@PasswordValidator()` - a password validator with options
- `@CreditCardNumberValidator()` - a credit card number validator that can use Luhn algorithm
- `@PhoneValidator()` - a phone validator which validates upon a database of country phone codes and phone masks which makes it more reliable than the one base on regular expression 
- `@NameValidator()` - validates a name written in latin or cyrillic letters. If you need other letters, you should write your own validator. Take this one as an example


### Value converters
- `@JsonValueConverter()` - **base class**: can be extended for any type conversion
- `@JsonDateConverter()` - allows you to provide a default date format for a DateTime, e.g. `yyyy-MM-dd` or some other
- `@JsonIntConverter()` - this one allows to clamp an `int` value between min and max values or to give it a default value if the actual value is null
- `@JsonNumConverter()` - the same as `int` converter but for `num`
- `@JsonKeyNameConverter()` - **base class**: can be used to write custom converters
- `@JsonTrimString()` - trims white spaces from a string. Left, right or both
- `@JsonPhoneConverter()` - formats a phone or removes a format, depending on args

### Key converters
- `@CamelToSnake()` - converts a field name to `snake_case_style` 
- `@SnakeToCamel()`- converts a field name to `camelCaseStyle` 
- `@FirstToUpper()` - converts a first letter of a field name to upper case


## Writing custom annotations

Some of the annotations above are marked as **base class** you can extend them and write a custom logic. 

I will also add some types here later


