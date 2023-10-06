part of 'json_annotations.dart';

abstract class JsonKeyNameConverter {
  const JsonKeyNameConverter();
  String convert(String value);
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
}

class SnakeToCamel extends JsonKeyNameConverter {
  const SnakeToCamel();

  @override
  String convert(String value) {
    return value.snakeToCamel();
  }
}
