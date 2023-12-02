import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:reflect_buddy/src/annotations/_card_validator_support.dart';
import 'package:reflect_buddy/src/annotations/_phone_validator_support.dart';
import 'package:reflect_buddy/src/intl_local/lib/intl.dart';
import 'package:reflect_buddy/src/utils/formatter_utils.dart';

part '_key_name_converters.dart';
part '_value_converters.dart';
part '_value_validators.dart';

/// A class level annotation. It will also include the fields of the direct parent.
///
/// This annotation might come useful when you have some common fields
/// for many classes e.g. a data model class might have id, createdAt, updatedAt etc.
/// fields that you want to store in a super class.
/// In this case you can add this annotation to your class
/// and the fields from its super class will automatically be added to
/// the resulting JSON
class JsonIncludeParentFields {
  const JsonIncludeParentFields();
}

class JsonInclude extends JsonKey {
  const JsonInclude({
    List<SerializationDirection> includeDirections = const [
      SerializationDirection.fromJson,
      SerializationDirection.toJson,
    ],
  }) : super(
          ignoreDirections: const [],
          includeDirections: includeDirections,
        );
}

class JsonIgnore extends JsonKey {
  const JsonIgnore({
    List<SerializationDirection> ignoreDirections = const [
      SerializationDirection.fromJson,
      SerializationDirection.toJson,
    ],
  }) : super(
          includeDirections: const [],
          ignoreDirections: ignoreDirections,
        );
}

/// [ignoreDirections] contains a list of directions which will be ignored
/// [includeDirections] contains a list of directions which will be included
///
/// [isIncluded] makes sense only for private fields if you
/// want them to be included to a resulting JSON. By default
/// private fields are ignored
///
/// [name] if you want the field name to be changed to some alternative
/// one in a resulting JSON, just type this alternative name here
class JsonKey {
  const JsonKey({
    required this.ignoreDirections,
    required this.includeDirections,
    this.name,
  });

  final List<SerializationDirection> ignoreDirections;
  final List<SerializationDirection> includeDirections;

  final String? name;

  void checkIfValid() {
    const error =
        'You can\'t use both `ignoreDirections` and `ignoreDirections` at the same time with all values. The lists must be completely different';
    if (ignoreDirections.isNotEmpty && includeDirections.isNotEmpty) {
      if (ignoreDirections.length > 1 && includeDirections.length > 1) {
        throw error;
      } else if (ignoreDirections.length == 1 &&
          includeDirections.length == 1) {
        if (ignoreDirections.first == includeDirections.first) {
          throw error;
        }
      }
    }
  }
}
