import 'package:reflect_buddy/src/extensions/mirror_extensions.dart';

import 'class_examples.dart';

void main() {
  // final result = (ContainerWithCustomGenerics).fromJson(containerWithCustomGenerics);
  // final result = (ContainerWithCustomList).fromJson(containerWithCustomList);
  final result = (ContainerWithCustomMap).fromJson(containerWithCustomMap);
  // final result = (SimpleUser).fromJson(simpleUser);
  // final result = (ContainerWithCustomMap).fromJson(containerWithCustomMap);
  print(result?.toJson());
  // print(result);
}


