/*
(c) Copyright 2023 Serov Konstantin.

Licensed under the MIT license:

    http://www.opensource.org/licenses/mit-license.php

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import '../utils/formatter_utils.dart';

class CardSystem {
  static const String kMir = 'MIR';
  static const String kUnionPay = 'UnionPay';
  static const String kVisa = 'Visa';
  static const String kMasterCard = 'Mastercard';
  static const String kJcb = 'JCB';
  static const String kDiscover = 'Discover';
  static const String kMaestro = 'Maestro';
  static const String kAmex = 'Amex';
  static const String kDinersClub = 'DinersClub';
  static const String kUzCard = 'UzCard';
}

/// [useLuhnAlgo] validates the number using the Luhn algorithm
bool isCardNumberValid({
  required String cardNumber,
  bool checkLength = false,
  bool useLuhnAlgo = true,
}) {
  cardNumber = toNumericString(
    cardNumber,
    allowAllZeroes: true,
    allowHyphen: false,
    allowPeriod: false,
  );
  if (cardNumber.isEmpty) {
    return false;
  }
  var countryData = _CardSystemDatas.getCardSystemDataByNumber(cardNumber);
  if (countryData == null) {
    return false;
  }
  if (useLuhnAlgo) {
    final isLuhnOk = checkNumberByLuhn(number: cardNumber);
    if (!isLuhnOk) {
      return false;
    }
  }
  var formatted = _formatByMask(cardNumber, countryData.numberMask!);
  var reprocessed = toNumericString(formatted);
  return reprocessed == cardNumber &&
      (checkLength == false || reprocessed.length == countryData.numDigits);
}

String formatAsCardNumber(
  String cardNumber, {
  bool useSeparators = true,
}) {
  if (!isCardNumberValid(
    cardNumber: cardNumber,
  )) {
    return cardNumber;
  }
  cardNumber = toNumericString(
    cardNumber,
  );
  var cardSystemData = _CardSystemDatas.getCardSystemDataByNumber(cardNumber)!;
  return _formatByMask(cardNumber, cardSystemData.numberMask!);
}

CardSystemData? getCardSystemData(
  String cardNumber,
) {
  return _CardSystemDatas.getCardSystemDataByNumber(cardNumber);
}

String _formatByMask(
  String text,
  String mask,
) {
  var chars = text.split('');
  var result = <String>[];
  var index = 0;
  for (var i = 0; i < mask.length; i++) {
    if (index >= chars.length) {
      break;
    }
    var curChar = chars[index];
    if (mask[i] == '0') {
      if (isDigit(curChar)) {
        result.add(curChar);
        index++;
      } else {
        break;
      }
    } else {
      result.add(mask[i]);
    }
  }
  return result.join();
}

class CardSystemData {
  final String? system;
  final String? systemCode;
  final String? numberMask;
  final int? numDigits;

  CardSystemData._init({
    this.numberMask,
    this.system,
    this.systemCode,
    this.numDigits,
  });

  factory CardSystemData.fromMap(Map value) {
    return CardSystemData._init(
      system: value['system'],
      systemCode: value['systemCode'],
      numDigits: value['numDigits'],
      numberMask: value['numberMask'],
    );
  }
  @override
  String toString() {
    return '[CardSystemData(system: $system, systemCode: $systemCode]';
  }
}

class _CardSystemDatas {
  static CardSystemData? getCardSystemDataByNumber(
    String cardNumber, {
    int? substringLength,
  }) {
    if (cardNumber.isEmpty) return null;
    substringLength = substringLength ?? cardNumber.length;

    if (substringLength < 1) return null;
    Map? rawData;
    List<Map> tempSystems = [];
    for (var data in _data) {
      final systemCode = data['systemCode'];
      if (cardNumber.startsWith(systemCode)) {
        tempSystems.add(data);
      }
    }
    if (tempSystems.isEmpty) {
      return null;
    }
    if (tempSystems.length == 1) {
      rawData = tempSystems.first;
    } else {
      tempSystems.sort((a, b) => b['systemCode'].compareTo(a['systemCode']));
      final int maxCodeLength = tempSystems.first['systemCode'].length;
      tempSystems = tempSystems
          .where(
            (e) => e['systemCode'].length == maxCodeLength,
          )
          .toList();

      tempSystems.sort((a, b) => a['systemCode'].compareTo(b['systemCode']));
      for (var data in tempSystems) {
        final int numMaskDigits = data['numDigits']!;
        if (cardNumber.length <= numMaskDigits) {
          rawData = data;
          break;
        }
      }
      rawData ??= tempSystems.last;
    }
    return CardSystemData.fromMap(rawData);
  }

  static final List<Map<String, dynamic>> _data = <Map<String, dynamic>>[
    {
      'system': CardSystem.kVisa,
      'systemCode': '4',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kDinersClub,
      'systemCode': '14',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kDinersClub,
      'systemCode': '36',
      'numberMask': '0000 000000 0000',
      'numDigits': 14,
    },
    {
      'system': CardSystem.kDinersClub,
      'systemCode': '54',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kDinersClub,
      'systemCode': '30',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kMasterCard,
      'systemCode': '5',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kMasterCard,
      'systemCode': '222',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kMasterCard,
      'systemCode': '2720',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kAmex,
      'systemCode': '34',
      'numberMask': '0000 000000 00000',
      'numDigits': 15,
    },
    {
      'system': CardSystem.kAmex,
      'systemCode': '37',
      'numberMask': '0000 000000 00000',
      'numDigits': 15,
    },
    {
      'system': CardSystem.kJcb,
      'systemCode': '35',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kUzCard,
      'systemCode': '8600',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    // {
    //   'system': CardSystem.JCB,
    //   'systemCode': '35',
    //   'numberMask': '0000 0000 0000 0000 000',
    //   'numDigits': 19,
    // },
    {
      'system': CardSystem.kDiscover,
      'systemCode': '60',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kDiscover,
      'systemCode': '60',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 19,
    },
    {
      'system': CardSystem.kMaestro,
      'systemCode': '67',
      'numberMask': '0000 0000 0000 0000 0',
      'numDigits': 17,
    },
    {
      'system': CardSystem.kMaestro,
      'systemCode': '67',
      'numberMask': '00000000 0000000000',
      'numDigits': 18,
    },
    {
      'system': CardSystem.kMir,
      'systemCode': '2200',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kMir,
      'systemCode': '2204',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kUnionPay,
      'systemCode': '62',
      'numberMask': '0000 0000 0000 0000',
      'numDigits': 16,
    },
    {
      'system': CardSystem.kUnionPay,
      'systemCode': '62',
      'numberMask': '0000 0000 0000 0000 000',
      'numDigits': 19,
    },
  ];
}

/// Implementation of th Luhn algorithm
/// https://en.wikipedia.org/wiki/Luhn_algorithm
bool checkNumberByLuhn({
  required String number,
}) {
  final cardNumbers = number.split('');
  int numDigits = cardNumbers.length;

  int sum = 0;
  bool isSecond = false;
  for (int i = numDigits - 1; i >= 0; i--) {
    int d = int.parse(cardNumbers[i]);

    if (isSecond == true) {
      d = d * 2;
    }

    sum += d ~/ 10;
    sum += d % 10;

    isSecond = !isSecond;
  }
  return (sum % 10 == 0);
}
