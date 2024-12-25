## 1.7.0
- Add `documentType()` extension method on `Type` which can be used to generate 
documentation
## 1.6.4
- Fixed an issue with `null` values in maps
## 1.6.3
- Excluded static getters from parsing
## 1.6.2
- Fixed an issue with `JsonExcludeParentFields()` when this lead to not inclusion of the fields from current 
superclass
## 1.6.1
- Added support for non-default constructor instantiation. Not `toJson` method can instantiate 
even those types that don't have empty default constructor
## 1.6.0
- Added `OnBeforeValueSetting` callback. This callback is used in `toJson` method right after the key name conversion and right before the value conversion. This might come useful when you need to represent the object filled with default values like an API documentation generator by type
## 1.5.9
- Added `useValidators` parameter to `fromJson` method. Pass false to skip validators
## 1.5.8
- Added global setters for `useCamelToStakeForAll` or `useSnakeToCamelForAll` that 
allow to use some type of key converters for all field names
- Also added `customGlobalKeyNameConverter` setter where you can set your own converter
- Added global setter for `alwaysIncludeParentFields` that allows to include parent fields for all classes that don't have an explicit `JsonIncludeParentFields()` annotation
- Added `JsonExcludeParentFields()` annotation that allows to exclude parent fields from a particular class
in case `alwaysIncludeParentFields` is set to true globally
## 1.5.5
- Fixed reverse key conversion for `fromJson` method
## 1.5.4
- Added onKeyConversion: (ConvertedKey result) {} callback to both `toJson` and `fromJson` methods
- Added tryUseNativeSerializerMethodsIfAny: true to both `toJson` and `fromJson` methods
- A reverse conversion of keys is now possible for default converters `CamelToSnake` and `SnakeToCamel`
It's not guaranteed to work 100% perfectly son use it with caution
## 1.5.2
- Correct processing of default values for fields
## 1.5.1
- A quick hotfix for a bug that was introduced in 1.5.0 which failed the parsing if a class didn't have toJson method
## 1.5.0
- Added native support for json_serializable fromJson / toJson methods. Besides that it also supports fromMap / toMap methods. If either of these is present in a class or an instance, it will call it instead of reflecting the fields
IMPORTANT! no `reflect_buddy` annotations will work in this case
## 1.4.2
- Fixed incorrect logic for field comparison
## 1.4.1
- Added support for a dynamic Map
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
