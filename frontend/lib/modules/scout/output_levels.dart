import 'package:flutter/material.dart';

import './chat_aux_strings.dart';

/// How long an answer may get.
///
/// Three coarse steps rather than a token field: what a user knows is whether
/// they want it short or want the whole thing, not how many tokens that is. The
/// backend turns the step into a ceiling per turn, because the real limit also
/// depends on how much of the context window the conversation already fills.
class OutputLevels {
  OutputLevels._();

  static const String short = 'short';
  static const String normal = 'normal';
  static const String max = 'max';

  static const List<String> all = [short, normal, max];

  static String normalize(String value) => all.contains(value) ? value : normal;

  static IconData iconDataFor(String level) {
    switch (level) {
      case short:
        return Icons.short_text;
      case max:
        return Icons.article_outlined;
      default:
        return Icons.notes;
    }
  }

  static String labelFor(String level) =>
      tr('chatAux.output.level.${normalize(level)}');

  static String hintFor(String level) =>
      tr('chatAux.output.hint.${normalize(level)}');
}
