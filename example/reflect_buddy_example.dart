import 'package:reflect_buddy/src/extensions/mirror_extensions.dart';

import 'class_examples.dart';

void main() {

  // final result = (ContainerWithCustomGenerics).fromJson(containerWithCustomGenerics);
  // final result = (ContainerWithCustomList).fromJson(containerWithCustomList);
  // final result = fromJson<ContainerWithCustomMap>(containerWithCustomMap);
  // final result = containerWithCustomMap.toInstance<ContainerWithCustomMap>();
  final result = (SimpleUser).fromJson(simpleUser);
  // final result = (ContainerWithCustomMap).fromJson(containerWithCustomMap);
  print(result?.toJson());
}


