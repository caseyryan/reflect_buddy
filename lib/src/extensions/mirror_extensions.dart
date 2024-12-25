import 'dart:mirrors';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// used with [OnKeyConversion] and is there
/// to return the result of the key conversion
/// for example if you use toJson method and pass [OnKeyConversion]
/// callback you will get the conversion result for every key
/// e.g oldKey: userFirstName, newKey: user_first_name
/// if CamelToSnake() was used
class ConvertedKey {
  ConvertedKey({
    required this.oldKey,
    required this.newKey,
    required this.dartType,
  });
  final String oldKey;
  final String newKey;
  final Object? dartType;

  @override
  String toString() {
    return 'Instance of ConvertedKey [oldKey: $oldKey, newKey: $newKey, dartType: $dartType]';
  }
}

bool _alwaysIncludeParentFields = false;
set alwaysIncludeParentFields(bool value) {
  if (value == true) {
    print(
      '--> You have just set a global alwaysIncludeParentFields to true\n--> This will affect all classes that don\'t have an explicit JsonIncludeParentFields() annotation',
    );
  }
  _alwaysIncludeParentFields = value;
}

bool get alwaysIncludeParentFields => _alwaysIncludeParentFields;

JsonKeyNameConverter? _defaultKeyNameConverter;
get globalDefaultKeyNameConverter => _defaultKeyNameConverter;

set customGlobalKeyNameConverter(JsonKeyNameConverter? value) {
  if (value != null) {
    print(
        '--> You have just set a custom global key name converter of type: ${value.runtimeType}\n--> ${value.description}');
  }
  _defaultKeyNameConverter = value;
}

set useCamelToStakeForAll(bool value) {
  if (value == false) {
    if (_defaultKeyNameConverter is CamelToSnake) {
      customGlobalKeyNameConverter = null;
    }
  } else {
    customGlobalKeyNameConverter = CamelToSnake();
  }
}

set useSnakeToCamelForAll(bool value) {
  if (value == false) {
    if (_defaultKeyNameConverter is SnakeToCamel) {
      customGlobalKeyNameConverter = null;
    }
  } else {
    customGlobalKeyNameConverter = SnakeToCamel();
  }
}

typedef OnKeyConversion = Function(ConvertedKey);

/// This callback is used in [toJson] method
/// right after the key name conversion and right before the value conversion
/// So this callback will accept the value before any ValueConverter is applied to it
/// but at the same time it will return the correctly converted key name.
/// This might come useful when you need to represent the object filled with
/// default values like an API documentation generator
typedef OnBeforeValueSetting = Object? Function(
  Object? value,
  Type dartType,
  String keyName,
);

/// [onKeyConversion] is a callback that will be called
/// for every key that is being converted. It is useful
/// for logging purposes or for other purposes like creating a database indices
/// to understand what key was converted to what
Object? fromJson<T>(
  Object? data, {
  OnKeyConversion? onKeyConversion,
  bool tryUseNativeSerializerMethodsIfAny = true,
  bool tryApplyReversedKeyConversion = true,
}) {
  return T.fromJson(
    data,
    onKeyConversion: onKeyConversion,
    tryApplyReversedKeyConversion: tryApplyReversedKeyConversion,
    tryUseNativeSerializerMethodsIfAny: tryUseNativeSerializerMethodsIfAny,
  );
}

extension JsonEnumExtension on Enum {
  String? enumToString() {
    return toString().split('.')[1];
  }
}

extension JsonObjectExtension on Object {
  Object? fromJson<T>() {
    return T.fromJson(this);
  }

  /// [includeNullValues] if true, the keys
  /// whose values are null will still be included in a
  /// resulting JSON with null values.
  ///
  /// If you want to skip the unset values just pass false
  /// [keyNameConverter] if you need to apply some conversion
  /// on the resulting JSON key names, pass a converter here.
  /// [onKeyConversion] is a callback that will be called
  /// for every key that is being converted. It is useful
  /// for logging purposes or for other purposes like creating a database indices
  /// to understand what key was converted to what
  /// [tryUseNativeSerializerMethodsIfAny] whether or not
  /// to use the native toJson / toMap methods if any
  /// e.g. in case it's a json_serializable model
  /// if any of these methods is present it will be used
  /// [includeTypeDescription] can be used to include a key type
  /// represented as string. This might come useful if you
  /// need to generate a documentation for something
  /// IMPORTANT: if [includeTypeDescription] is true, no key conversion
  /// will be applied. The fields will be represented in a way they are present
  /// in the original model
  Object? toJson({
    bool includeNullValues = false,
    bool tryUseNativeSerializerMethodsIfAny = true,
    JsonKeyNameConverter? keyNameConverter,
    OnKeyConversion? onKeyConversion,
    OnBeforeValueSetting? onBeforeValueSetting,
    bool includeTypeDescription = false,
  }) {
    keyNameConverter ??= globalDefaultKeyNameConverter;
    if (runtimeType.isPrimitive) {
      return this;
    } else if (this is Map) {
      final newMap = {};
      final curMap = this as Map;
      for (var kv in curMap.entries) {
        final key = (kv.key as Object).toJson();
        if (kv.value == null) {
          newMap[key] = null;
        } else {
          newMap[key] = (kv.value as Object).toJson(
            includeNullValues: includeNullValues,
            keyNameConverter: keyNameConverter,
            onBeforeValueSetting: onBeforeValueSetting,
            includeTypeDescription: includeTypeDescription,
            tryUseNativeSerializerMethodsIfAny:
                tryUseNativeSerializerMethodsIfAny,
            onKeyConversion: onKeyConversion,
          );
        }
      }
      return newMap;
    } else if (this is Enum) {
      return (this as Enum).enumToString();
    } else if (this is List) {
      return (this as List).map(
        (e) {
          return (e as Object).toJson(
            includeNullValues: includeNullValues,
            keyNameConverter: keyNameConverter,
            onKeyConversion: onKeyConversion,
            onBeforeValueSetting: onBeforeValueSetting,
            includeTypeDescription: includeTypeDescription,
            tryUseNativeSerializerMethodsIfAny:
                tryUseNativeSerializerMethodsIfAny,
          );
        },
      ).toList();
    } else if (this is Type) {
      /// this is required to process types as instances
      /// because raw types cannot
      /// be as easily converted to json
      final typeInstance = (this as Type).newTypedInstance();
      final json = (typeInstance as Object).toJson(
        includeNullValues: includeNullValues,
        keyNameConverter: keyNameConverter,
        onKeyConversion: onKeyConversion,
        onBeforeValueSetting: onBeforeValueSetting,
        includeTypeDescription: includeTypeDescription,
        tryUseNativeSerializerMethodsIfAny: tryUseNativeSerializerMethodsIfAny,
      );
      return json;
    }
    final instanceMirror = reflect(this);

    if (tryUseNativeSerializerMethodsIfAny) {
      /// if it's a json_serializable class (or similar),
      /// it will try to call its native toJson / toMap method
      /// instead of mirroring the fields
      const possibleSerializers = ['toJson', 'toMap'];
      for (var possibleSerializer in possibleSerializers) {
        final serializerReflectee = instanceMirror.tryCallMethod(
          methodName: possibleSerializer,
          positionalArguments: [],
        );
        if (serializerReflectee != null) {
          return serializerReflectee;
        }
      }
    }

    final declarations = instanceMirror.includeParentDeclarationsIfNecessary();

    final Map<String, dynamic> json = {};
    JsonKeyNameConverter? classLevelKeyNameConverter =
        instanceMirror.type.tryGetKeyNameConverter();
    if (classLevelKeyNameConverter != null && keyNameConverter != null) {
      /// if you pass a keyNameConverter, it will override the existing annotation of the same type
      classLevelKeyNameConverter = null;
    }
    keyNameConverter ??= classLevelKeyNameConverter;
    for (var kv in declarations.entries) {
      if (kv.value is VariableMirror) {
        final variableMirror = kv.value as VariableMirror;
        if (variableMirror.isStatic) {
          continue;
        }
        Object? rawValue = instanceMirror
            .getField(
              variableMirror.simpleName,
            )
            .reflectee;
        final isJsonIncluded = variableMirror.isJsonIncluded;
        if (variableMirror.isPrivate) {
          if (!isJsonIncluded(SerializationDirection.toJson)) {
            continue;
          }
        } else {
          if (variableMirror.isJsonIgnored(SerializationDirection.toJson)) {
            continue;
          }
        }
        if (!includeNullValues && rawValue == null) {
          continue;
        }
        final alternativeName = variableMirror.alternativeName;

        String? oldKey;
        String? newKey;
        if (onKeyConversion != null) {
          oldKey = variableMirror.name;
        }
        String variableName;
        if (includeTypeDescription == true) {
          /// this is because we need to represent the type as is
          variableName = variableMirror.name;
        } else {
          variableName = alternativeName ??
              variableMirror.tryConvertVariableNameViaAnnotation(
                variableName: variableMirror.name,
                keyNameConverter: keyNameConverter,
              );
        }
        if (oldKey != null) {
          newKey = variableName;
          onKeyConversion!(
            ConvertedKey(
              oldKey: oldKey,
              newKey: newKey,
              dartType: variableMirror.type.reflectedType,
            ),
          );
        }

        final dartType = variableMirror.type.reflectedType;
        if (onBeforeValueSetting != null) {
          rawValue = onBeforeValueSetting(
            rawValue,
            dartType,
            variableName,
          );
        }
        final valueConverters =
            variableMirror.getAnnotationsOfType<JsonValueConverter>();
        for (final converter in valueConverters) {
          rawValue = converter.convert(
            rawValue,
            SerializationDirection.toJson,
          );
        }

        Object? value;
        if (rawValue.runtimeType.isPrimitive) {
          value = rawValue;
        } else if (rawValue is List) {
          value = rawValue.map(
            (Object? e) {
              return e?.toJson(
                includeNullValues: includeNullValues,
                keyNameConverter: keyNameConverter,
                onKeyConversion: onKeyConversion,
                onBeforeValueSetting: onBeforeValueSetting,
                includeTypeDescription: includeTypeDescription,
                tryUseNativeSerializerMethodsIfAny:
                    tryUseNativeSerializerMethodsIfAny,
              );
            },
          ).toList();
        } else if (rawValue is Enum) {
          value = rawValue.enumToString();
        } else if (rawValue is DateTime) {
          value = rawValue.toIso8601String();
        } else if (rawValue is Map) {
          value = rawValue.map(
            (key, Object? value) => MapEntry(
              key,
              value?.toJson(
                includeNullValues: includeNullValues,
                keyNameConverter: keyNameConverter,
                onKeyConversion: onKeyConversion,
                onBeforeValueSetting: onBeforeValueSetting,
                includeTypeDescription: includeTypeDescription,
                tryUseNativeSerializerMethodsIfAny:
                    tryUseNativeSerializerMethodsIfAny,
              ),
            ),
          );
        } else {
          value = rawValue?.toJson(
            includeNullValues: includeNullValues,
            keyNameConverter: keyNameConverter,
            onKeyConversion: onKeyConversion,
            onBeforeValueSetting: onBeforeValueSetting,
            includeTypeDescription: includeTypeDescription,
            tryUseNativeSerializerMethodsIfAny:
                tryUseNativeSerializerMethodsIfAny,
          );
        }
        json[variableName] = value;

        /// allows to include a type represented as a string value
        if (includeTypeDescription) {
          json['${variableName}__TYPE__'] = variableMirror.type.reflectedType;
        }
      }
    }
    return json;
  }
}

extension InstanceMirrorExtension on InstanceMirror {
  /// Just adds parent fields if necessary.
  Map<Symbol, DeclarationMirror> includeParentDeclarationsIfNecessary() {
    return type.includeParentDeclarationsIfNecessary();
  }

  Object? tryCallMethod({
    required String methodName,
    List<Object?> positionalArguments = const [],
    Map<Symbol, Object?> namedArguments = const {},
  }) {
    final symbolName = Symbol(methodName);
    final classMirror = reflectClass(type.reflectedType);
    if (classMirror.declarations.containsKey(symbolName)) {
      return invoke(
        symbolName,
        positionalArguments,
        namedArguments,
      ).reflectee;
    }
    return null;
  }
}

extension TypeExtension on Type {
  /// returns a JSON with all public fields
  /// of the type and their respective types.
  /// The field names are included as is, without any conversion
  Map documentType() {
    final types = <String, String>{};
    final json = toJson(
      includeNullValues: true,
      includeTypeDescription: true,
    );
    if (json is Map) {
      _describeTypesInMap(
        json,
        toString(),
        types,
      );
    }
    return types;
  }

  /// [type] a map is required to avoid duplicate classes
  void _describeTypesInMap(
    Map json,
    String typeName,
    Map types,
  ) {
    final buffer = StringBuffer('$typeName \n');
    for (var kv in json.entries) {
      final innerType = json['${kv.key}__TYPE__'];
      bool isLinkedType = false;
      if (innerType is Type) {
        if (!innerType.isPrimitive) {
          if (!innerType.isDateTime &&
              !innerType.isListType &&
              !innerType.isMapType &&
              !innerType.isRawObjectType) {
            isLinkedType = true;
          }
        }
      }
      if (kv.key.contains('__TYPE__')) {
        /// this is the type conversion.
        /// Because the value is null, we need to make a JSON from
        /// the type itself
        if (kv.value is Type) {
          final asType = kv.value as Type;
          isLinkedType = true;

          /// this case means we need to to describe some custom type
          if (asType.isPrimitive == false) {
            if (asType.isDateTime) {
              continue;
            } else {
              if (asType.isListType ||
                  asType.isMapType ||
                  asType.isRawObjectType) {
                /// A simple check. We just don't need to display the contents
                /// of these types even though it will work
                ///
                /// Because we don't iterate over the list or map
                /// Some of the generic types might be lost but this
                /// is acceptable for now
                // TODO: process generic types of list and map
                continue;
              }
            }
            final description = asType.documentType();
            types.addAll(description);
          }
        }
        continue;
      }
      final rawTypeName = innerType.toString();

      /// Wrap type in brackets to be compatible with a markdown link format
      String typeName =
          !isLinkedType ? rawTypeName : '[$rawTypeName]($rawTypeName)';
      buffer.writeln('\t$typeName ${kv.key}: ${kv.value}');
    }
    buffer.writeln('}');
    types[typeName] = buffer.toString();
  }

  Object? newTypedInstance() {
    if (isPrimitive) {
      if (this == String) {
        return '';
      } else if (this == int) {
        return 0;
      } else if (this == double || this == num) {
        return 0.0;
      } else if (this == bool) {
        return false;
      }
    }

    /// I used reflectType here instead of reflectClass to preserve all
    /// the generic arguments which might be important
    final classMirror = reflectType(this) as ClassMirror;
    final instance = classMirror._instantiateUsingDefaultConstructor();
    return instance;
  }

  bool hasAnnotation<T>() {
    return reflectType(this).metadata.any(
          (m) => m.reflectee.runtimeType == T,
        );
  }

  Object? newEnumInstance(Object? value) {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror._instantiateEnum(value);
  }

  bool get isDynamic {
    return toString().contains('dynamic');
  }

  bool get isPrimitive {
    switch (this) {
      case String:
      case double:
      case num:
      case int:
      case bool:
        return true;
    }
    return false;
  }

  bool get isDateTime {
    return this == DateTime;
  }

  /// This primitive check should be enough in most cases
  bool get isListType {
    // return (reflectType(this) as ClassMirror).isList;
    return toString().contains('List');
  }

  bool get isMapType {
    return toString().contains('Map');
  }

  bool get isRawObjectType {
    final strType = toString();
    return strType == 'Object' || strType == 'Object?';
  }

  /// [tryUseNativeSerializerMethodsIfAny] whether or not
  /// to use the native fromJson / fromMap methods if any
  /// e.g. in case it's a json_serializable model
  /// if any of these methods is present it will be used
  /// [tryApplyReversedKeyConversion] if true it will try to apply reversed key conversion
  /// e.g. if there's a CamelToSnake converter applied to a field or a class
  /// and the current value is determined as a snake case then it will try to convert it back to camel case
  /// it might not work 100% perfectly so use it with caution.
  /// It's more reliable to apply [JsonKey] with a particular field name to a required field
  /// in this case it will be used instead and [tryApplyReversedKeyConversion] will be ignored
  /// [useValidators] if you don't want to apply validators, just pass false
  Object? fromJson(
    Object? data, {
    OnKeyConversion? onKeyConversion,
    bool tryUseNativeSerializerMethodsIfAny = true,
    bool tryApplyReversedKeyConversion = true,
    bool useValidators = true,
  }) {
    if (data == null) {
      return null;
    } else if (this == data.runtimeType) {
      return data;
    } else if (isDateTime) {
      if (data is String) {
        return DateTime.tryParse(data);
      }
    } else if (isPrimitive) {
      return data;
    } else if (data is List) {
      final reflection = reflectType(this);

      final reflectionClassMirror = (reflection as ClassMirror);

      final listInstance =
          reflectionClassMirror._instantiateUsingDefaultConstructor();
      if (listInstance is List) {
        for (var rawValue in data) {
          if (reflectionClassMirror.isGeneric) {
            final actualType =
                reflectionClassMirror.typeArguments.first.reflectedType;
            final actualValue = actualType.fromJson(
              rawValue,
              useValidators: useValidators,
            );
            listInstance.add(actualValue);
          } else {
            if (rawValue.runtimeType.isPrimitive) {
              listInstance.add(data);
            }
          }
        }
        return listInstance;
      }
    } else if (data is Map) {
      final reflection = reflectType(this);
      final reflectionClassMirror = (reflection as ClassMirror);
      final mapInstance =
          reflectionClassMirror._instantiateUsingDefaultConstructor();
      if (reflectionClassMirror.isMap) {
        for (var kv in data.entries) {
          final rawKeyData = kv.key;
          final rawValueData = kv.value;
          final actualKeyType = reflection.typeArguments[0].reflectedType;
          final actualValueType = reflection.typeArguments[1].reflectedType;
          final actualKey = actualKeyType.fromJson(
            rawKeyData,
            useValidators: useValidators,
          );
          final actualValue = actualValueType.fromJson(
            rawValueData,
            useValidators: useValidators,
          );
          mapInstance[actualKey] = actualValue;
        }
        return mapInstance;
      } else {
        final instanceMirror = reflect(mapInstance);

        if (tryUseNativeSerializerMethodsIfAny) {
          /// this is required to process json_serializable classes
          /// (and other classes that have a fromJson / fromMap method)
          /// which have it's own methods to convert from and to json
          /// it will assume that the fromJson / fromMap method is static or it's
          /// a factory constructor with the first positional argument being a map
          const possibleDeserializers = ['fromJson', 'fromMap'];
          for (var possibleDeserializer in possibleDeserializers) {
            final deserializerReflectee =
                reflectionClassMirror.tryCallStaticMethodOrFactoryConstructor(
              methodName: possibleDeserializer,
              positionalArguments: [
                data,
              ],
            );
            if (deserializerReflectee != null) {
              return deserializerReflectee;
            }
          }
        }

        /// to support reversed key conversion
        /// if the values were previously converted using a SnakeToCamel converter
        /// this will try to convert them back to snake case
        JsonKeyNameConverter? classLevelKeyNameConverter =
            reflectionClassMirror.tryGetKeyNameConverter() ??
                globalDefaultKeyNameConverter;

        final declarations =
            reflectionClassMirror.includeParentDeclarationsIfNecessary();
        for (var declaration in declarations.entries) {
          DeclarationMirror? declarationMirror;
          JsonKeyNameConverter? keyNameConverter = classLevelKeyNameConverter;

          /// this hack is needed to be able to access private fields
          /// simply calling reflectionClassMirror.declarations[Symbol(kv.key)]; won't work
          /// in this case since private keys have unique namings based on their hash
          /// toName() extension doesn't care for that, it uses a RegExp to parse
          /// the name
          String simpleDartFieldName = declaration.key.toName();
          String? oldKey;
          String? newKey;
          if (declaration.value is VariableMirror) {
            final VariableMirror variableMirror =
                declaration.value as VariableMirror;

            final jsonKey =
                variableMirror.getAnnotationsOfType<JsonKey>().firstOrNull;
            if (jsonKey?.name?.isNotEmpty == true) {
              if (onKeyConversion != null) {
                oldKey = simpleDartFieldName;
              }
              simpleDartFieldName = jsonKey!.name!;
              if (oldKey != null) {
                newKey = simpleDartFieldName;
                onKeyConversion!(
                  ConvertedKey(
                    oldKey: oldKey,
                    newKey: newKey,
                    dartType: variableMirror.type.reflectedType,
                  ),
                );
              }
            } else {
              if (tryApplyReversedKeyConversion) {
                final variableLevelKeyNameConverter =
                    variableMirror.tryGetKeyNameConverter(
                  variableName: simpleDartFieldName,
                );
                if (variableLevelKeyNameConverter != null) {
                  keyNameConverter = variableLevelKeyNameConverter;
                }
                if (keyNameConverter != null) {
                  if (onKeyConversion != null) {
                    oldKey = simpleDartFieldName;
                  }
                  if (!simpleDartFieldName.isUndeterminedCase()) {
                    // bool allowConversion = false;
                    // if (keyNameConverter is SnakeToCamel) {
                    //   allowConversion = simpleName.isCamelCase();
                    // } else if (keyNameConverter is CamelToSnake) {
                    //   allowConversion = simpleName.isSnakeCase();
                    // }
                    // if (allowConversion) {

                    simpleDartFieldName =
                        keyNameConverter.convert(simpleDartFieldName);
                    if (oldKey != null) {
                      newKey = simpleDartFieldName;
                      onKeyConversion!(
                        ConvertedKey(
                          oldKey: oldKey,
                          newKey: newKey,
                          dartType: variableMirror.type.reflectedType,
                        ),
                      );
                    }
                    // }
                  }
                }
              }
            }
          }
          declarationMirror = declaration.value;
          dynamic valueFromJson;

          /// Trying to get the value for it from json map
          valueFromJson = data[simpleDartFieldName];
          if (declarationMirror is VariableMirror) {
            final VariableMirror variableMirror = declarationMirror;
            if (variableMirror.isConst ||
                variableMirror.isJsonIgnored(SerializationDirection.fromJson)) {
              continue;
            }
            if (variableMirror.isPrivate) {
              if (!variableMirror
                  .isJsonIncluded(SerializationDirection.fromJson)) {
                continue;
              }
            }
            if (variableMirror.type is ClassMirror) {
              final variableClassMirror = variableMirror.type as ClassMirror;
              final fieldType = variableMirror.type.hasReflectedType
                  ? variableClassMirror.reflectedType
                  : variableClassMirror.runtimeType;
              final isEnum = variableClassMirror.isEnum;

              final valueConverters =
                  variableMirror.getAnnotationsOfType<JsonValueConverter>();
              var value = valueFromJson;

              for (final converter in valueConverters) {
                value = converter.convert(
                  value,
                  SerializationDirection.fromJson,
                );
              }
              if (isEnum && value is! Enum) {
                value = fieldType.newEnumInstance(value);
              }

              value = fieldType.fromJson(
                value,
                useValidators: useValidators,
              );
              if (useValidators) {
                final valueValidators =
                    variableMirror.getAnnotationsOfType<JsonValueValidator>();
                final variableName = variableMirror.simpleName.toName();
                for (final validator in valueValidators) {
                  validator.validate(
                    fieldName: variableName,
                    actualValue: value,
                  );
                }
              }
              try {
                instanceMirror.setField(
                  variableMirror.simpleName,
                  value ??
                      instanceMirror
                          .getField(variableMirror.simpleName)
                          .reflectee,
                );
              } catch (_) {
                /// this exception is suppressed to avoid setting
                /// unwanted types
              }
            } else if (variableMirror.type.reflectedType.isDynamic) {
              /// This is the most dangerous situation. You SHOULD
              /// always try to avoid
              /// using dynamic type in your model declarations where it's possible
              /// since the value is set as is (with no validations or conversions)
              /// and it is not guaranteed that this will
              /// be an acceptable value.
              /// And of course, never try to use `dynamic` where some non-primitive
              /// value is expected since it might just not work
              try {
                instanceMirror.setField(
                  variableMirror.simpleName,
                  valueFromJson ??
                      instanceMirror
                          .getField(variableMirror.simpleName)
                          .reflectee,
                );
              } catch (_) {
                /// this exception is suppressed to avoid setting
                /// unwanted types
              }
            }
          } else {
            // passed some key that is not present in the model
            // print('no mirror $valueFromJson');
          }
        }

        return mapInstance;
      }
    } else {
      /// This might be the case when an Enum is expected
      /// but a string is passed, for example
      final reflection = reflectType(this);
      if (reflection is ClassMirror) {
        final reflectionClassMirror = reflection;
        final isEnum = reflectionClassMirror.isEnum;
        if (isEnum && data is! Enum) {
          return reflectionClassMirror.reflectedType.newEnumInstance(data);
        } else {
          throw '''
          Value is unsupported. Please report this case: https://github.com/caseyryan/reflect_buddy/issues
          Expected value type: ${reflectionClassMirror.reflectedType}
          Actual value: $data
        ''';
        }
      }
    }

    return data;
  }
}

extension VariableMirrorExtension on VariableMirror {
  Iterable<T> getAnnotationsOfType<T>() {
    return metadata.map((e) => e.reflectee).whereType<T>();
  }

  String tryConvertVariableNameViaAnnotation({
    required String variableName,
    required JsonKeyNameConverter? keyNameConverter,
  }) {
    final converter = tryGetKeyNameConverter(variableName: variableName);
    if (converter == null) {
      variableName = keyNameConverter?.convert(variableName) ?? variableName;
    } else {
      variableName = converter.convert(variableName);
    }

    return variableName;
  }

  JsonKeyNameConverter? tryGetKeyNameConverter({
    required String variableName,
  }) {
    final keyNameConvertors = getAnnotationsOfType<JsonKeyNameConverter>();
    final numConverters = keyNameConvertors.length;
    if (numConverters > 0) {
      if (numConverters > 1) {
        throw 'You can only apply one annotation of type $JsonKeyNameConverter to a field. $variableName has $numConverters';
      }
      return keyNameConvertors.first;
    }
    return null;
  }

  String get name {
    return simpleName.toName();
  }

  bool isJsonIgnored(SerializationDirection direction) {
    final jsonKey = getAnnotationsOfType<JsonKey>().firstOrNull;
    if (jsonKey == null) {
      return false;
    }
    jsonKey.checkIfValid();
    return jsonKey.ignoreDirections.contains(direction);
  }

  bool isJsonIncluded(SerializationDirection direction) {
    final jsonKey = getAnnotationsOfType<JsonKey>().firstOrNull;
    if (jsonKey == null) {
      return false;
    }
    jsonKey.checkIfValid();
    return jsonKey.includeDirections.contains(direction);
  }

  String? get alternativeName {
    return getAnnotationsOfType<JsonKey>()
        .firstWhereOrNull((e) => e.name != null)
        ?.name;
  }
}

extension MethodMirrorExtension on MethodMirror {
  /// used to simplify method calling by passing default values
  /// required for documentation generation based on
  Map<Symbol, dynamic> getNamedParametersWithDefaultValues() {
    final params = parameters.where((e) => e.isNamed).map((e) {
      final dartType = e.type.reflectedType;
      return MapEntry(
        e.simpleName,
        dartType.newTypedInstance(),
      );
    });
    return Map.fromEntries(params);
  }

  List<dynamic> getPositionalArgsWithDefaultValues() {
    return parameters.where((e) => !e.isNamed).map((e) {
      final dartType = e.type.reflectedType;
      return dartType.newTypedInstance();
    }).toList();
  }
}

extension ClassMirrorExtension on ClassMirror {
  Iterable<T> getAnnotationsOfType<T>() {
    return metadata.map((e) => e.reflectee).whereType<T>();
  }

  bool includeParentFields() {
    return metadata.any(
          (e) => e.reflectee.runtimeType == JsonIncludeParentFields,
        ) ==
        true;
  }

  bool excludeParentFields() {
    return metadata.any(
          (e) => e.reflectee.runtimeType == JsonExcludeParentFields,
        ) ==
        true;
  }

  Object? tryCallStaticMethodOrFactoryConstructor({
    required String methodName,
    List<Object?> positionalArguments = const [],
    Map<Symbol, Object?> namedArguments = const {},
  }) {
    final factoryConstructorSymbol =
        Symbol('${reflectedType.toString()}.$methodName');
    final methodSymbol = Symbol(methodName);
    if (declarations.containsKey(methodSymbol)) {
      return invoke(
        methodSymbol,
        positionalArguments,
        namedArguments,
      ).reflectee;
    } else if (declarations.containsKey(factoryConstructorSymbol)) {
      final possibleFactoryConstructor = declarations[factoryConstructorSymbol];
      if (possibleFactoryConstructor is MethodMirror &&
          possibleFactoryConstructor.isFactoryConstructor) {
        return newInstance(
          methodSymbol,
          positionalArguments,
          namedArguments,
        ).reflectee;
      }
    }
    return null;
  }

  Map<Symbol, DeclarationMirror> includeParentDeclarationsIfNecessary() {
    Map<Symbol, DeclarationMirror> childDeclarations = declarations;
    ClassMirror? type = superclass;
    if ((includeParentFields() == true || alwaysIncludeParentFields) &&
        !excludeParentFields()) {
      final tempDeclarations = {...childDeclarations};
      while (type != null) {
        final declarations = type.declarations.entries.where(
          (e) => e.value is VariableMirror,
        );
        tempDeclarations.addEntries(declarations);
        bool needsToExcludeParent = type.excludeParentFields();
        type = type.superclass;
        if (type == null || needsToExcludeParent) {
          break;
        }
        final needsToIncludeParent =
            (type.includeParentFields() == true || alwaysIncludeParentFields);
        if (!needsToIncludeParent) {
          type = null;
        }
      }
      return tempDeclarations;
    }
    return childDeclarations;
  }

  JsonKeyNameConverter? tryGetKeyNameConverter() {
    final keyNameConvertors = getAnnotationsOfType<JsonKeyNameConverter>();
    final numConverters = keyNameConvertors.length;
    if (numConverters > 0) {
      if (numConverters > 1) {
        throw 'You can only apply one annotation of type $JsonKeyNameConverter to a class.';
      }
      return keyNameConvertors.first;
    }
    return null;
  }

  Symbol get _defaultConstructorName {
    if (isList) {
      return const Symbol('empty');
    } else if (isMap) {
      return const Symbol('from');
    }
    final constructors = declarations.values
        .where(
          (e) => e is MethodMirror && e.isConstructor,
        )
        .cast<MethodMirror>();

    if (constructors.isNotEmpty) {
      if (constructors.any((e) => e.constructorName == Symbol.empty)) {
        return Symbol.empty;
      }
      return constructors.first.constructorName;
    }
    return Symbol.empty;
  }

  bool get isGeneric {
    return typeArguments.isNotEmpty;
  }

  Map<Symbol, dynamic> _getDefaultNamedArgs(
    Symbol constructorName,
  ) {
    if (isList) {
      return {
        const Symbol('growable'): true,
      };
    }
    final constructor = tryGetConstructorByName(constructorName);
    if (constructor != null) {
      return constructor.getNamedParametersWithDefaultValues();
    }

    return {};
  }

  MethodMirror? tryGetConstructorByName(
    Symbol constructorName,
  ) {
    return declarations.values.firstWhereOrNull(
      (e) =>
          e is MethodMirror &&
          e.isConstructor &&
          e.constructorName == constructorName,
    ) as MethodMirror?;
  }

  List _getDefaultPositionalArgs(
    Symbol constructorName,
  ) {
    if (isMap) {
      return [{}];
    }
    final constructor = tryGetConstructorByName(constructorName);
    if (constructor != null) {
      return constructor.getPositionalArgsWithDefaultValues();
    }

    return [];
  }

  dynamic _instantiateEnum(Object? value) {
    if (value == null || value is! String) {
      return null;
    }
    final valueSymbol = Symbol(value);
    if (declarations.keys.any((e) => e == valueSymbol)) {
      return getField(valueSymbol).reflectee;
    }
  }

  dynamic _instantiateUsingDefaultConstructor() {
    final constructorName = _defaultConstructorName;
    final namedArguments = _getDefaultNamedArgs(constructorName);
    final positionalArguments = _getDefaultPositionalArgs(constructorName);

    return newInstance(
      constructorName,
      positionalArguments,
      namedArguments,
    ).reflectee;
  }

  bool get isList {
    return qualifiedName == const Symbol('dart.core.List') ||
        qualifiedName == const Symbol('dart.core.GrowableList');
  }

  bool get isMap {
    return qualifiedName == const Symbol('dart.core.Map');
  }
}

extension SymbolExtension on Symbol {
  String toName() {
    return MirrorSystem.getName(this);
  }
}
