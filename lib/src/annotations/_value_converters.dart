part of 'json_annotations.dart';

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

/// Trims a string before assigning
class TrimString extends JsonValueConverter {
  const TrimString({
    this.trimLeft = true,
    this.trimRight = true,
  });

  final bool trimLeft;
  final bool trimRight;

  @override
  Object? convert(covariant String? value) {
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