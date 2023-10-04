import 'dart:mirrors';

import 'package:reflect_buddy/src/annotations/json_annotations.dart';

extension JsonObjectExtension on Object {
  Map<String, dynamic>? toJson() {
    final classMirror = reflectType(runtimeType) as ClassMirror;
    final instanceMirror = reflect(this);

    return null;
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
            if (variableMirror.isConst) {
              continue;
            }

            final fieldType = variableMirror.type.hasReflectedType
                ? variableMirror.type.reflectedType
                : variableMirror.type.runtimeType;

            final valueConverters =
                variableMirror.getAnnotationsOfType<JsonValueConverter>().where(
                      (e) => e.useCase == JsonValueConvertorUseCase.deserialization,
                    );
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
  static final RegExp _regExp = RegExp(r'(?<=Symbol\(")[a-zA-Z0-9_]+');

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
