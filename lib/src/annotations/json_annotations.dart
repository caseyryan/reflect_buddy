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
