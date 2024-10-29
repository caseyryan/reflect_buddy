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
  final String oldKey;
  final String newKey;
  ConvertedKey({
    required this.oldKey,
    required this.newKey,
  });

  @override
  String toString() {
    return 'Instance of ConvertedKey [oldKey: $oldKey, newKey: $newKey]';
  }
}

typedef OnKeyConversion = Function(ConvertedKey);

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
  Object? toJson({
    bool includeNullValues = false,
    bool tryUseNativeSerializerMethodsIfAny = true,
    JsonKeyNameConverter? keyNameConverter,
    OnKeyConversion? onKeyConversion,
  }) {
    if (runtimeType.isPrimitive) {
      return this;
    } else if (this is Map) {
      final newMap = {};
      final curMap = this as Map;
      for (var kv in curMap.entries) {
        newMap[(kv.key as Object).toJson()] = (kv.value as Object).toJson(
          includeNullValues: includeNullValues,
          keyNameConverter: keyNameConverter,
        );
      }
      return newMap;
    } else if (this is Enum) {
      return (this as Enum).enumToString();
    } else if (this is List) {
      return (this as List)
          .map(
            (e) => (e as Object).toJson(
              includeNullValues: includeNullValues,
              keyNameConverter: keyNameConverter,
            ),
          )
          .toList();
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
              );
            },
          ).toList();
        } else if (rawValue is Enum) {
          value = rawValue.enumToString();
        } else if (rawValue is DateTime) {
          // TODO: try to apply value converter
          value = rawValue.toIso8601String();
        } else if (rawValue is Map) {
          value = rawValue.map(
            (key, Object? value) => MapEntry(
              key,
              value?.toJson(
                includeNullValues: includeNullValues,
              ),
            ),
          );
        } else {
          value = rawValue?.toJson();
        }
        String? oldKey;
        String? newKey;
        if (onKeyConversion != null) {
          oldKey = variableMirror.name;
        }
        final variableName = alternativeName ??
            variableMirror.tryConvertVariableNameViaAnnotation(
              variableName: variableMirror.name,
              keyNameConverter: keyNameConverter,
            );
        if (oldKey != null) {
          newKey = variableName;
          onKeyConversion!(
            ConvertedKey(
              oldKey: oldKey,
              newKey: newKey,
            ),
          );
        }

        json[variableName] = value;
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
  Object? newTypedInstance() {
    /// I used reflectType here instead of reflectClass to preserve all
    /// the generic arguments which might be important
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror._instantiateUsingDefaultConstructor();
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
  Object? fromJson(
    Object? data, {
    OnKeyConversion? onKeyConversion,
    bool tryUseNativeSerializerMethodsIfAny = true,
    bool tryApplyReversedKeyConversion = true,
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
            final actualValue = actualType.fromJson(rawValue);
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
          final actualKey = actualKeyType.fromJson(rawKeyData);
          final actualValue = actualValueType.fromJson(rawValueData);
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
            reflectionClassMirror.tryGetKeyNameConverter();

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
          String simpleName = declaration.key.toName();
          String? oldKey;
          String? newKey;
          if (declaration.value is VariableMirror) {
            final VariableMirror variableMirror =
                declaration.value as VariableMirror;

            final jsonKey =
                variableMirror.getAnnotationsOfType<JsonKey>().firstOrNull;
            if (jsonKey?.name?.isNotEmpty == true) {
              if (onKeyConversion != null) {
                oldKey = simpleName;
              }
              simpleName = jsonKey!.name!;
              if (oldKey != null) {
                newKey = simpleName;
                onKeyConversion!(
                  ConvertedKey(
                    oldKey: oldKey,
                    newKey: newKey,
                  ),
                );
              }
            } else {
              if (tryApplyReversedKeyConversion) {
                final variableLevelKeyNameConverter =
                    variableMirror.tryGetKeyNameConverter(
                  variableName: simpleName,
                );
                if (variableLevelKeyNameConverter != null) {
                  keyNameConverter = variableLevelKeyNameConverter;
                }
                if (keyNameConverter != null) {
                  if (onKeyConversion != null) {
                    oldKey = simpleName;
                  }
                  if (!simpleName.isUndeterminedCase()) {
                    // bool allowConversion = false;
                    // if (keyNameConverter is SnakeToCamel) {
                    //   allowConversion = simpleName.isCamelCase();
                    // } else if (keyNameConverter is CamelToSnake) {
                    //   allowConversion = simpleName.isSnakeCase();
                    // }
                    // if (allowConversion) {
                    simpleName = keyNameConverter.convert(simpleName);
                    if (oldKey != null) {
                      newKey = simpleName;
                      onKeyConversion!(
                        ConvertedKey(
                          oldKey: oldKey,
                          newKey: newKey,
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
          valueFromJson = data[simpleName];

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

              value = fieldType.fromJson(value);

              final valueValidators =
                  variableMirror.getAnnotationsOfType<JsonValueValidator>();
              final variableName = variableMirror.simpleName.toName();
              for (final validator in valueValidators) {
                validator.validate(
                  fieldName: variableName,
                  actualValue: value,
                );
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
    if (includeParentFields() == true) {
      final tempDeclarations = {...childDeclarations};
      while (type != null) {
        final declarations = type.declarations.entries.where(
          (e) => e.value is VariableMirror,
        );
        type = type.superclass;
        final needsToIncludeParent = type?.includeParentFields() == true;
        if (!needsToIncludeParent) {
          type = null;
        }
        tempDeclarations.addEntries(declarations);
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
    return Symbol.empty;
  }

  bool get isGeneric {
    return typeArguments.isNotEmpty;
  }

  Map<Symbol, dynamic> get _defaultNamedArgs {
    if (isList) {
      return {
        const Symbol('growable'): true,
      };
    }
    return {};
  }

  List get _defaultPositionalArgs {
    if (isMap) {
      return [{}];
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
    return newInstance(
      _defaultConstructorName,
      _defaultPositionalArgs,
      _defaultNamedArgs,
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
