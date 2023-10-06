RegExp _uppercase = RegExp(r'[A-Z]');
RegExp _oddUnderscores = RegExp(r'_{2,}');

extension JsonStringExtensions on String {
  String firstToUpperCase() {
    if (isEmpty) return this;
    final first = this[0].toUpperCase();
    return '$first${substring(1)}';
  }

  String lastCharacter() {
    if (length < 1) return '';
    return this[length - 1];
  }

  String camelToSnake() {
    if (isEmpty) return this;
    final presplit = split('');
    final buffer = StringBuffer();
    for (var i = 0; i < presplit.length; i++) {
      final letter = presplit[i];
      if (_uppercase.hasMatch(letter)) {
        if (i > 0) {
          buffer.write('_');
        }
        buffer.write(letter.toLowerCase());
      } else {
        buffer.write(letter);
      }
    }
    return buffer.toString();
  }

  String snakeToCamel() {
    if (isEmpty) return this;
    final str = replaceAll(_oddUnderscores, '_');
    final presplit = str.split('');

    final buffer = StringBuffer();
    for (var i = 0; i < presplit.length; i++) {
      final letter = presplit[i];
      if (letter == '_') {
        if (i == 0) {
          continue;
        }
        if (i < presplit.length - 1) {
          final nextLetter = presplit[i + 1];
          if (i > 1) {
            buffer.write(nextLetter.toUpperCase());
            i++;
          } else {
            buffer.write(nextLetter);
            i++;
          }
        }
      } else {
        buffer.write(letter);
      }
    }
    return buffer.toString();
  }
}
