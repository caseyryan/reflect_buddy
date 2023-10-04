import 'dart:mirrors';

import 'package:reflect_buddy/src/annotations/json_annotations.dart';

extension JsonObjectExtension on Object {
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
        json[variableMirror.name] = value;
      }
    }
    return json;
  }
}

extension TypeExtension on Type {
  dynamic newTypedInstance() {
    /// I used reflectType here instead of reflectClass to preserve all
    /// the generic arguments which might be important
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror._instantiateUsingDefaultConstructor();
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

            final fieldType = variableMirror.type.hasReflectedType
                ? variableMirror.type.reflectedType
                : variableMirror.type.runtimeType;

            final valueConverters =
                variableMirror.getAnnotationsOfType<JsonValueConverter>();
            var value = kv.value;

            for (final converter in valueConverters) {
              value = converter.convert(value);
            }
            value = fieldType.fromJson(value);

            final valueValidators =
                variableMirror.getAnnotationsOfType<JsonValueValidator>();
            for (final validator in valueValidators) {
              validator.validate(
                fieldName: variableMirror.simpleName.toName(),
                actualValue: value,
              );
            }

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
