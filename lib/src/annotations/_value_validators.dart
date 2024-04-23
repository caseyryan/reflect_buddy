part of 'json_annotations.dart';

/// If you need to validate a value before assigning it to
/// a field, you can annotate the field with a descendant of
/// this class. You can use many of these validators on a field
/// You can see an example implementation in [IntValidator]
/// If a validator does not validate a value it must throw an exception
abstract class JsonValueValidator {
  const JsonValueValidator({
    required this.canBeNull,
  });

  final bool canBeNull;

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

  /// [actualValue] the value to validate against
  /// [fieldName] the name of the instance field if required to
  /// be able to display it in an exception if the validation fails
  void validate({
    covariant Object? actualValue,
    required String fieldName,
  });
}

class RequiredValidator extends JsonValueValidator {
  const RequiredValidator() : super(canBeNull: false);

  @override
  void validate({
    covariant Object? actualValue,
    required String fieldName,
  }) {
    checkForNull(
      canBeNull: canBeNull,
      fieldName: fieldName,
      actualValue: actualValue,
    );
  }
}

class IntValidator extends NumValidator {
  const IntValidator({
    required int minValue,
    required int maxValue,
    required super.canBeNull,
  }) : super(
          minValue: minValue,
          maxValue: maxValue,
        );
}

class DoubleValidator extends NumValidator {
  const DoubleValidator({
    required double minValue,
    required double maxValue,
    required super.canBeNull,
  }) : super(
          minValue: minValue,
          maxValue: maxValue,
        );
}

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

class StringValidator extends JsonValueValidator {
  const StringValidator({
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

class PasswordValidator extends JsonValueValidator {
  static final _digitsRegex = RegExp(r'[0-9]+');
  static final _upperCaseLettersRegex = RegExp(r'[A-ZА-ЯЁ]+');
  static final _lowerCaseLettersRegex = RegExp(r'[a-zа-яё]+');
  static final _specialCharRegex =
      RegExp("[\"!#\$%&')(*+,-\\.\\/:;<=>?@\\][^_`|}{~]+");

  const PasswordValidator({
    this.minDigits = 1,
    this.minLength = 8,
    this.minLowerCaseLetters = 1,
    this.minSpecialChars = 1,
    this.minUpperCaseLetters = 1,
  }) : super(canBeNull: false);

  final int minLength;
  final int minSpecialChars;
  final int minUpperCaseLetters;
  final int minLowerCaseLetters;
  final int minDigits;

  bool _isDigitsOk(String value) {
    if (minDigits < 1) {
      return true;
    }
    return _digitsRegex.allMatches(value).length >= minDigits;
  }

  bool _isLengthOk(String value) {
    return value.length >= minLength;
  }

  bool _isLowerCaseOk(
    String value,
  ) {
    if (minLowerCaseLetters < 1) {
      return true;
    }
    return _lowerCaseLettersRegex.allMatches(value).length >=
        minLowerCaseLetters;
  }

  bool _isUpperCaseOk(
    String value,
  ) {
    if (minUpperCaseLetters < 1) {
      return true;
    }
    return _upperCaseLettersRegex.allMatches(value).length >=
        minUpperCaseLetters;
  }

  bool _isSpecialCharsOk(
    String value,
  ) {
    if (minSpecialChars < 1) {
      return true;
    }
    return _specialCharRegex.allMatches(value).length >= minSpecialChars;
  }

  String _getEnding(int num) {
    if (num < 2) {
      return '';
    }
    return 's';
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
      if (!_isDigitsOk(actualValue!)) {
        throw 'A password must contain at least $minDigits digit${_getEnding(minDigits)}';
      }
      if (!_isSpecialCharsOk(actualValue)) {
        throw 'A password must contain at least $minSpecialChars special character${_getEnding(minSpecialChars)}';
      }
      if (!_isLowerCaseOk(actualValue)) {
        throw 'A password must contain at least $minLowerCaseLetters lower case latin or cyrillic letter${_getEnding(minLowerCaseLetters)}';
      }
      if (!_isUpperCaseOk(actualValue)) {
        throw 'A password must contain at least $minUpperCaseLetters upper case latin or cyrillic letter${_getEnding(minUpperCaseLetters)}';
      }
      if (!_isLengthOk(actualValue)) {
        throw 'A password must be at least $minLength character${_getEnding(minLength)} long';
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

class PhoneValidator extends JsonValueValidator {
  const PhoneValidator({
    required super.canBeNull,
  });

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
      if (!isPhoneValid(actualValue!)) {
        throw 'Phone number is invalid [$fieldName]';
      }
    }
  }
}

class CreditCardNumberValidator extends JsonValueValidator {
  const CreditCardNumberValidator({
    required super.canBeNull,
    this.useLuhnAlgo = true,
  });

  final bool useLuhnAlgo;

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
      if (!isCardNumberValid(
        cardNumber: actualValue!,
        useLuhnAlgo: useLuhnAlgo,
      )) {
        throw 'A card number is invalid [$fieldName]';
      }
    }
  }
}
