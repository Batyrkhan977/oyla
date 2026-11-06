import 'package:flutter/services.dart';

class OmirMedia {
  static const channel = MethodChannel('omirai/media');
  static Future<void> note(int note, {int milliseconds = 350}) =>
      channel.invokeMethod('note', {'midi': note, 'ms': milliseconds});
  static Future<String?> recognize(String language) =>
      channel.invokeMethod<String>('recognize', {'language': language});
}

/// Conservative forward-only matching. Unknown speech never completes a text.
int spokenPosition(String text, String speech, int start) {
  final words = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  final heard = words
      .allMatches(speech.toLowerCase())
      .map((m) => m.group(0)!)
      .toList();
  final remaining = words
      .allMatches(text.toLowerCase(), start)
      .take(80)
      .toList();
  var best = start;
  for (var i = 0; i < remaining.length; i++) {
    var matched = 0;
    for (var j = 0; j < heard.length && i + j < remaining.length; j++) {
      if (remaining[i + j].group(0) != heard[j]) break;
      matched++;
    }
    if (matched >= 2) {
      final end = remaining[i + matched - 1].end;
      if (end > best) best = end;
    }
  }
  return best;
}
