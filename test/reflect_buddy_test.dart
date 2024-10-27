import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final Human? human = {
      'age': 37,
      'name': 'Konstantin', 
      'hobbies': ['reading', 'running']
    }.fromJson<Human>() as Human?;
    assert(human != null);
    assert(human!.age == 36);
    assert(human!.name == 'Konstantin');
    assert(human!.hobbies?.length == 2);
    assert(human!.hobbies!.contains('reading'));
  });

}


class Human {
  int? age;
  String? name;
  List<String>? hobbies;
}