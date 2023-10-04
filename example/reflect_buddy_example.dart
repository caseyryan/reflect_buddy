import 'package:reflect_buddy/src/extensions/mirror_extensions.dart';

import 'class_examples.dart';

void main() {
  final result = (ContainerWithCustomGenerics).fromJson(containerWithCustomGenerics);
  // final result = (ContainerWithCustomMap).fromJson(containerWithCustomMap);
  print(result);
}


