part of 'json_annotations.dart';

enum ConvertDirection {
  fromJson,
  toJson,
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

  Object? convert(
    covariant Object? value,
    ConvertDirection direction,
  );
}

/// Serializes / Deserializes dates by a provided
class JsonDateConverter extends JsonValueConverter {
  const JsonDateConverter({
    required this.dateFormat,
  });

  final String dateFormat;

  @override
  Object? convert(
    covariant Object? value,
    ConvertDirection direction,
  ) {
    if (value is String) {
      return DateFormat(dateFormat).parse(value);
    } else if (value is DateTime) {
      return DateFormat(dateFormat).format(value);
    }
    return null;
  }
}

/// Trims a string before assigning
class JsonTrimString extends JsonValueConverter {
  const JsonTrimString({
    this.trimLeft = true,
    this.trimRight = true,
  });

  final bool trimLeft;
  final bool trimRight;

  @override
  Object? convert(
    covariant String? value,
    ConvertDirection direction,
  ) {
    if (!trimLeft && !trimRight) {
      return value;
    }
    if (trimLeft == trimRight) {
      return value?.trim();
    }
    if (trimRight) {
      return value?.trimRight();
    } else {
      return value?.trimLeft();
    }
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

enum PhoneStringType {
  formatted,
  unformatted,
}

class JsonPhoneConverter extends JsonValueConverter {
  final PhoneStringType type;
  final bool addLeadingPlus;
  const JsonPhoneConverter({
    this.type = PhoneStringType.unformatted,
    this.addLeadingPlus = true,
  });

  @override
  Object? convert(
    covariant Object? value,
    ConvertDirection direction,
  ) {
    if (value is String) {
      if (type == PhoneStringType.formatted) {
        return formatAsPhoneNumber(value);
      } else if (type == PhoneStringType.unformatted) {
        /// we first format it to fix possible errors
        final formatted = formatAsPhoneNumber(value);
        final numbers = toNumericString(
          formatted,
          allowAllZeroes: true,
          allowHyphen: true,
        );
        if (addLeadingPlus) {
          return '+$numbers';
        }
        return numbers;
      }
    }
    return value;
  }
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
  num? convert(
    covariant num? value,
    ConvertDirection direction,
  ) {
    if (value == null) {
      if (canBeNull) {
        return value;
      }
      return minValue;
    }
    return value.clamp(minValue, maxValue);
  }
}
