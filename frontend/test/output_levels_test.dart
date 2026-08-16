import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/scout/output_levels.dart';

/// The answer-length steps the plus menu offers. What matters here is that an
/// unknown value never reaches the backend as one: the ceiling it resolves to
/// decides how much a turn costs.
void main() {
  test('an unknown level falls back to normal', () {
    expect(OutputLevels.normalize('max'), OutputLevels.max);
    expect(OutputLevels.normalize('short'), OutputLevels.short);
    expect(OutputLevels.normalize(''), OutputLevels.normal);
    expect(OutputLevels.normalize('unendlich'), OutputLevels.normal);
  });

  test('every level has its own icon', () {
    final icons = <IconData>{
      for (final level in OutputLevels.all) OutputLevels.iconDataFor(level),
    };
    expect(icons.length, OutputLevels.all.length);
  });

  test('every level is labelled and explained', () {
    for (final level in OutputLevels.all) {
      expect(OutputLevels.labelFor(level), isNotEmpty);
      expect(OutputLevels.labelFor(level), isNot(contains('chatAux.')));
      expect(OutputLevels.hintFor(level), isNotEmpty);
      expect(OutputLevels.hintFor(level), isNot(contains('chatAux.')));
    }
  });
}
