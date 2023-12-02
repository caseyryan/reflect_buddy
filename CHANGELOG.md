## 1.4.0
- JsonIgnore and JsonInclude now can have a direction
## 1.3.5
- List toJson now also returns List
## 1.3.4
- Ignore null values now works correctly even for the fields that are annotated with `JsonInclude()`
## 1.3.3
- `JsonIncludeParentFields` is now also available in `fromJson` direction
- `JsonKey` is also applied to `fromJson`
## 1.3.1
- includeParentDeclarationsIfNecessary as extension method on InstanceMirror
## 1.3.0
- Added JsonIncludeParentFields annotation that lets `toJson()` serialize 
instances including their parent fields
## 1.2.2
- Made mirror extensions public
## 1.2.1
- Allowed setting unknown value type to `dynamic` fields
## 1.2.0
- Added conversion direction to `JsonValueConvertor`
## 1.1.8
- Removed unnecessary prints
## 1.1.7
- Added support for Enums as primitive values to `toJson`
## 1.1.6
- Added support for Enums as primitive values to `fromJson`
## 1.1.5
- Fixed broken type check
## 1.1.4
- Added a support for dynamic declarations
## 1.1.3
- Added JsonPhoneConverter
## 1.1.2
- Added a possibility to convert Map to JSON as well
## 1.1.1
- Renamed some validators and converters
## 1.0.11
- Added PasswordValidator with configuration
- Added PhoneValidator which validates a phone against real country codes and formats not against a regular expression, which makes a validation much more reliable
- Added CreditCardNumberValidator which can use Luhn algo to validate a card number combined with a card system check
## 1.0.8
- actualValue in checkForNull is now required
## 1.0.7
- checkForNull method in value validators is not public
## 1.0.6
- Fixed toJson for primitive types
## 1.0.4
- Fixed readme anchors
## 1.0.3

- Added 2 validators and one converter
## 1.0.0

- Initial version.
