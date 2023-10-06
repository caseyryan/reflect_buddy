import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:reflect_buddy/src/intl_local/lib/intl.dart';

class JsonInclude extends JsonKey {
  const JsonInclude()
      : super(
          isIgnored: false,
          isIncluded: true,
        );
}

class JsonIgnore extends JsonKey {
  const JsonIgnore()
      : super(
          isIgnored: true,
          isIncluded: false,
        );
}

/// [isIgnored] means this field will be ignored from a
/// deserialized json even if it's public
///
/// [isIncluded] makes sense only for private fields if you
/// want them to be included to a resulting JSON. By default
/// private fields are ignored
///
/// [name] if you want the field name to be changed to some alternative
/// one in a resulting JSON, just type this alternative name here
class JsonKey {
  const JsonKey({
    this.isIgnored = false,
    this.isIncluded = true,
    this.name,
  }) : assert(isIgnored != isIncluded);

  final bool isIgnored;
  final bool isIncluded;
  final String? name;
}

/// If you need to validate a value before assigning it to
/// a field, you can annotate the field with a descendant of
/// this class. You can use many of these validators on a field
/// You can see an example implementation in [JsonIntValidator]
/// If a validator does not validate a value it must throw an exception
abstract class JsonValueValidator {
  const JsonValueValidator();

  /// [actualValue] the value to validate against
  /// [fieldName] the name of the instance field if required to
  /// be able to display it in an exception if the validation fails
  void validate({
    covariant Object? actualValue,
    required String fieldName,
  });
}

class JsonIntValidator extends JsonNumValidator {
  const JsonIntValidator({
    required int minValue,
    required int maxValue,
    required super.canBeNull,
  }) : super(
          minValue: minValue,
          maxValue: maxValue,
        );
}

class JsonDoubleValidator extends JsonNumValidator {
  const JsonDoubleValidator({
    required double minValue,
    required double maxValue,
    required super.canBeNull,
  }) : super(
          minValue: minValue,
          maxValue: maxValue,
        );
}

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

class JsonStringValidator extends JsonValueValidator {
  const JsonStringValidator({
    required this.canBeNull,
    this.regExpPattern,
  });

  final bool canBeNull;
  final String? regExpPattern;

  @override
  void validate({
    String? actualValue,
    required String fieldName,
  }) {
    if (!canBeNull) {
      if (actualValue == null) {
        throw '"$fieldName" can\'t be null';
      }
    } else {
      if (actualValue == null) {
        return;
      }
    }
    if (regExpPattern != null) {
      final regExp = RegExp(regExpPattern!);
      final match = regExp.firstMatch(actualValue);
      if (match == null || match.start > 0 || match.end < actualValue.length) {
        throw '"$actualValue" is an invalid value for "$fieldName"';
      }
    }
  }
}

/// Similar to [JsonValueValidator] but it must not
/// throw any exceptions but convert a value instead
/// For example: you get 101 from your json map, but an
/// expected value must be in a range between 10 and 50.
/// You simply clamp the actual value and return the max
/// expected value in this case
/// NOTICE: [JsonValueConverter]'s are called before
/// a value is deserialized, so it can prepare an incoming value
/// to be correctly deserialized
abstract class JsonValueConverter {
  const JsonValueConverter();

  Object? convert(covariant Object? value);
}

/// Serializes / Deserializes dates by a provided
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

class JsonIntConverter extends JsonNumConverter {
  const JsonIntConverter({
    required int minValue,
    required int maxValue,
    required super.canBeNull,
  }) : super(
          minValue: minValue,
          maxValue: maxValue,
        );
}

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
