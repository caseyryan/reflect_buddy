import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:reflect_buddy/src/annotations/_card_validator_support.dart';
import 'package:reflect_buddy/src/annotations/_phone_validator_support.dart';
import 'package:reflect_buddy/src/intl_local/lib/intl.dart';

part '_key_name_converters.dart';
part '_value_converters.dart';
part '_value_validators.dart';

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
