List<T> sampleEvenly<T>(List<T> values, {required int maxItems}) {
  if (maxItems < 2) {
    throw ArgumentError.value(maxItems, 'maxItems', 'Must be at least 2.');
  }
  if (values.length <= maxItems) {
    return List<T>.unmodifiable(values);
  }

  final sampled = <T>[values.first];
  final stride = (values.length - 1) / (maxItems - 1);
  for (var index = 1; index < maxItems - 1; index++) {
    sampled.add(values[(index * stride).round()]);
  }
  sampled.add(values.last);
  return List<T>.unmodifiable(sampled);
}
