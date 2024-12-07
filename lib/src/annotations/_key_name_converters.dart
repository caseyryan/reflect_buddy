part of 'json_annotations.dart';

abstract class JsonKeyNameConverter {
  const JsonKeyNameConverter();
  String convert(String value);

  String get description;
}

/// Used for json serialization. This annotation (is set on class)
/// will convert every field / variable name in a way that the first
/// letter will be uppercase
/// e.g. firstName will be converted to FirstName
class FirstToUpper extends JsonKeyNameConverter {
  const FirstToUpper();

  @override
  String convert(String value) {
    return value.firstToUpperCase();
  }

  @override
  String get description =>
      '$runtimeType converter takes a string value and convert its first letter to uppercase. e.g. firstName will be converted to FirstName';
}

/// Converts keys to snake case. Can be used on classes
/// as well as on public variables and getters
/// e.g. a name like userFirstName will be converted to
/// user_first_name
class CamelToSnake extends JsonKeyNameConverter {
  const CamelToSnake();

  @override
  String convert(String value) {
    return value.camelToSnake();
  }

  @override
  String get description =>
      '$runtimeType converter takes a string value and converts it to a snake case register. e.g. userFirstName will be converted to user_first_name';
}

class SnakeToCamel extends JsonKeyNameConverter {
  const SnakeToCamel();

  @override
  String convert(String value) {
    return value.snakeToCamel();
  }

  @override
  String get description =>
      '$runtimeType converter takes a string value and converts it to a camel case register. e.g. user_first_name will be converted to userFirstName';
}
