import 'dart:mirrors';

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
  Object? toJson({
    bool includeNullValues = false,
  }) {
    final instanceMirror = reflect(this);
    final Map<String, dynamic> json = {};
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
          return rawValue.toIso8601String();
        } else if (rawValue is Map) {
          value = rawValue.map(
            (key, Object? value) => MapEntry(
              key,
              value?.toJson(
                includeNullValues: includeNullValues,
              ),
            ),
          );
        }

        final variableName = variableMirror.tryConvertVariableNameViaAnnotation(
          variableName: variableMirror.name,
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
          final declarationMirror = reflectionClassMirror.declarations[Symbol(kv.key)];
          if (declarationMirror != null && declarationMirror is VariableMirror) {
            final VariableMirror variableMirror = declarationMirror;
            if (variableMirror.isConst || variableMirror.isJsonIgnored) {
              continue;
            }
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
            // final keyNameConvertor = variableMirror.tryGetKeyNameConverter(
            //   variableName: variableName,
            // );
            // if (keyNameConvertor != null) {
            //   print(keyNameConvertor);
            // }

            instanceMirror.setField(
              variableMirror.simpleName,
              value,
            );
          }
        }
        return mapInstance;
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
  }) {
    final converter = tryGetKeyNameConverter(variableName: variableName);
    variableName = converter?.convert(variableName) ?? variableName;
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
}

extension _ClassMirrorExtension on ClassMirror {
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
