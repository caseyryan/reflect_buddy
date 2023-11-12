import 'dart:mirrors';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:reflect_buddy/src/annotations/json_annotations.dart';

Object? fromJson<T>(Object? data) {
  return T.fromJson(data);
}

extension JsonEnumExtension on Enum {
  String? enumToString() {
    return toString().split('.')[1];
  }
}

extension JsonObjectExtension on Object {
  Object? toInstance<T>() {
    return T.fromJson(this);
  }

  /// [includeNullValues] if true, the keys
  /// whose values are null will still be included in a
  /// resulting JSON with null values.
  ///
  /// If you want to skip the unset values just pass false
  /// [keyNameConverter] if you need to apply some conversion
  /// on the resulting JSON key names, pass a converter here.
  Object? toJson({
    bool includeNullValues = false,
    JsonKeyNameConverter? keyNameConverter,
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
    }
    final instanceMirror = reflect(this);
    final Map<String, dynamic> json = {};
    JsonKeyNameConverter? classLevelKeyNameConverter =
        instanceMirror.type.tryGetKeyNameConverter();
    if (classLevelKeyNameConverter != null && keyNameConverter != null) {
      /// if you pass a keyNameConverter, it will override the existing annotation of the same type
      classLevelKeyNameConverter = null;
    }
    keyNameConverter ??= classLevelKeyNameConverter;
    for (var kv in instanceMirror.type.declarations.entries) {
      if (kv.value is VariableMirror) {
        final variableMirror = kv.value as VariableMirror;
        Object? rawValue = instanceMirror
            .getField(
              variableMirror.simpleName,
            )
            .reflectee;
        final isJsonIncluded = variableMirror.isJsonIncluded;
        if (variableMirror.isPrivate) {
          if (!isJsonIncluded) {
            continue;
          }
        } else {
          if (variableMirror.isJsonIgnored) {
            continue;
          }
        }
        if (!includeNullValues && rawValue == null) {
          if (isJsonIncluded == false) {
            continue;
          }
        }
        final alternativeName = variableMirror.alternativeName;
        final valueConverters = variableMirror.getAnnotationsOfType<JsonValueConverter>();
        for (final converter in valueConverters) {
          rawValue = converter.convert(rawValue);
        }

        Object? value;
        if (rawValue.runtimeType.isPrimitive) {
          value = rawValue;
        } else if (rawValue is List) {
          value = rawValue
              .map(
                (Object? e) => e?.toJson(
                  includeNullValues: includeNullValues,
                ),
              )
              .toList();
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
              ),
            ),
          );
        } else {
          value = rawValue?.toJson();
        }
        final variableName = alternativeName ??
            variableMirror.tryConvertVariableNameViaAnnotation(
              variableName: variableMirror.name,
              keyNameConverter: keyNameConverter,
            );

        json[variableName] = value;
      }
    }
    return json;
  }
}

extension TypeExtension on Type {
  Object? newTypedInstance() {
    /// I used reflectType here instead of reflectClass to preserve all
    /// the generic arguments which might be important
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror._instantiateUsingDefaultConstructor();
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

  Object? fromJson(Object? data) {
    print(this);
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
      final listInstance = reflectionClassMirror._instantiateUsingDefaultConstructor();
      if (listInstance is List) {
        for (var rawValue in data) {
          if (reflectionClassMirror.isGeneric) {
            final actualType = reflectionClassMirror.typeArguments.first.reflectedType;
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
      final mapInstance = reflectionClassMirror._instantiateUsingDefaultConstructor();
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
        for (var kv in data.entries) {
          DeclarationMirror? declarationMirror;
          for (var declaration in reflectionClassMirror.declarations.entries) {
            /// this hack is needed to be able to access private fields
            /// simply calling reflectionClassMirror.declarations[Symbol(kv.key)]; won't work
            /// in this case since private keys have unique namings based on their hash
            /// toName() extension doesn't care for that, it uses a RegExp to parse
            /// the name
            final simpleName = declaration.key.toName();
            if (simpleName == kv.key) {
              declarationMirror = declaration.value;
              break;
            }
          }
          if (declarationMirror != null && declarationMirror is VariableMirror) {
            final VariableMirror variableMirror = declarationMirror;
            if (variableMirror.isConst || variableMirror.isJsonIgnored) {
              continue;
            }
            if (variableMirror.isPrivate) {
              if (!variableMirror.isJsonIncluded) {
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
              var value = kv.value;

              for (final converter in valueConverters) {
                value = converter.convert(value);
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
              instanceMirror.setField(
                variableMirror.simpleName,
                value,
              );
            } else if (variableMirror.type.reflectedType.isDynamic) {
              if (!kv.value.runtimeType.isPrimitive) {
                throw '''
                  Your variable type is declared as `dynamic` 
                  but the provided value is not primitive.
                  You must replace the declaration with a strictly typed one
                ''';
              }

              /// This is the most dangerous situation. You SHOULD
              /// always try to avoid
              /// using dynamic type in your model declarations where it's possible
              /// since the value is set as is (with no validations or conversions)
              /// and it is not guaranteed that this will
              /// be an acceptable value.
              /// And of course, never try to use `dynamic` where some non-primitive
              /// value is expected since it will just not work
              instanceMirror.setField(
                variableMirror.simpleName,
                kv.value,
              );
            }
          }
        }
        return mapInstance;
      }
    } else {
      /// This might be the case when an Enum is expected
      /// but a string is passed, for example
      final reflection = reflectType(this);
      final reflectionClassMirror = (reflection as ClassMirror);
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

    return data;
  }
}

extension _VariableMirrorExtension on VariableMirror {
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

  bool get isJsonIgnored {
    return getAnnotationsOfType<JsonKey>().firstOrNull?.isIgnored == true;
  }

  bool get isJsonIncluded {
    return getAnnotationsOfType<JsonKey>().firstOrNull?.isIncluded == true;
  }

  String? get alternativeName {
    return getAnnotationsOfType<JsonKey>().firstWhereOrNull((e) => e.name != null)?.name;
  }
}

extension _ClassMirrorExtension on ClassMirror {
  Iterable<T> getAnnotationsOfType<T>() {
    return metadata.map((e) => e.reflectee).whereType<T>();
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

extension _SymbolExtension on Symbol {
  /// It's a hack.
  /// The time measure showed that using RegExp for this purpose
  /// (after the RegExp is compiled) takes 2000 - 2100 microseconds
  /// or just about 2 milliseconds
  /// I consider it to be an acceptable value for most cases
  /// so using reflection would just make the code more complex here
  static final RegExp _regExp = RegExp(
    r'(?<=Symbol\(")[a-zA-Z0-9_]+',
  );

  String toName() {
    final name = toString();
    final match = _regExp.firstMatch(name);
    if (match == null) {
      return '';
    }
    return name.substring(
      match.start,
      match.end,
    );
  }
}
