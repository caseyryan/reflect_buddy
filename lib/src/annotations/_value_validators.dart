part of 'json_annotations.dart';

/// If you need to validate a value before assigning it to
/// a field, you can annotate the field with a descendant of
/// this class. You can use many of these validators on a field
/// You can see an example implementation in [JsonIntValidator]
/// If a validator does not validate a value it must throw an exception
abstract class JsonValueValidator {
  const JsonValueValidator({
    required this.canBeNull,
  });

  final bool canBeNull;

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

class JsonStringValidator extends JsonValueValidator {
  const JsonStringValidator({
    required super.canBeNull,
    this.regExpPattern,
  });

  final String? regExpPattern;

  @override
  void validate({
    String? actualValue,
    required String fieldName,
  }) {
    if (checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    )) {
      if (regExpPattern != null) {
        final regExp = RegExp(regExpPattern!);
        final match = regExp.firstMatch(actualValue!);
        if (match == null ||
            match.start > 0 ||
            match.end < actualValue.length) {
          throw '"$actualValue" is an invalid value for "$fieldName"';
        }
      }
    }
  }
}

class EmailValidator extends JsonValueValidator {
  static final RegExp _emailRegex = RegExp(
    r"^[\w!#$%&'*+\-/=?\^_`{|}~]+(\.[\w!#$%&'*+\-/=?\^_`{|}~]+)*@((([\-\w]+\.)+[a-zA-Z]{2,12})|(([0-9]{1,12}\.){12}[0-9]{1,12}))$",
  );
  const EmailValidator({
    required super.canBeNull,
  });

  bool _isEmailValid(String value) {
    return _emailRegex.stringMatch(value) != null;
  }

  @override
  void validate({
    covariant String? actualValue,
    required String fieldName,
  }) {
    if (checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    )) {
      if (!_isEmailValid(actualValue!)) {
        throw 'Email is invalid [$fieldName]';
      }
    }
  }
}

class NameValidator extends JsonValueValidator {
  static final RegExp _lettersRegExp = RegExp(r'[A-Za-zА-Яа-яЁё]+');
  static final RegExp _nameValidatorRegExp =
      RegExp(r'^(?!\s)([А-Яа-яЁёA-Za-z- ])+$');
  static final RegExp _doubleSpaceRegExp = RegExp(r'\s{2}');
  static final RegExp _dashKillerRegExp = RegExp(r'(-{2})|(-[\s]+)|(\s[-]+)');
  // static final RegExp _lettersRegExp = RegExp(r'[A-Za-zА-Яа-я ёЁ-]+');
  // static final RegExp _nameValidatorRegExp = RegExp(r'^(?!\s)([A-Za-zА-Яа-я ёЁ-])+$');
  // static final RegExp _doubleSpaceRegExp = RegExp(r'\s{2}');
  // static final RegExp _dashKillerRegExp = RegExp(r'(-{2})|(-[\s]+)|(\s[-]+)');

  const NameValidator({
    required super.canBeNull,
  });

  String? _getNameValidationError({
    required String value,
    required String fieldName,
  }) {
    if (value.isEmpty) {
      return '`$fieldName` cannot be empty';
    }
    if (!value.startsWith(_lettersRegExp)) {
      return '`$fieldName` must start with a letter';
    }
    if (!_lettersRegExp.hasMatch(value.lastCharacter())) {
      return '`$fieldName` must end with a letter';
    }

    if (!_nameValidatorRegExp.hasMatch(value.trim())) {
      return '`$fieldName` must contain only letters, dashes, or spaces in the middle';
    }

    if (_doubleSpaceRegExp.hasMatch(value)) {
      return 'Only a single space is allowed between words in `$fieldName`';
    }

    if (_dashKillerRegExp.hasMatch(value)) {
      return 'Only a single dash is allowed between words in `$fieldName`';
    }

    return null;
  }

  @override
  void validate({
    covariant String? actualValue,
    required String fieldName,
  }) {
    if (checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    )) {
      final error = _getNameValidationError(
        fieldName: fieldName,
        value: actualValue!,
      );
      if (error != null) {
        throw error;
      }
    }
  }
}

bool checkForNull({
  required Object? actualValue,
  required bool canBeNull,
  required String fieldName,
}) {
  if (!canBeNull) {
    if (actualValue == null) {
      throw '`$fieldName` is required';
    }
  } else {
    if (actualValue == null) {
      return false;
    }
  }
  return true;
}
