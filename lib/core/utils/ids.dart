import 'dart:math';

final _random = Random.secure();

/// A random hex identifier (32 characters by default), for local records
/// such as photos.
String newId([int bytes = 16]) => List.generate(
  bytes,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
