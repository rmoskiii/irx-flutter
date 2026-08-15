import '../models/scenario.dart';

int _wordCount(String text) {
  return RegExp(r"\b[\w']+\b").allMatches(text).length;
}

Duration readingHoldForText(
  String text, {
  int minMs = 1600,
  int maxMs = 7000,
  int msPerWord = 260,
}) {
  final words = _wordCount(text);
  final millis = (words * msPerWord).clamp(minMs, maxMs);
  return Duration(milliseconds: millis);
}

Duration readingHoldForThread(
  List<ThreadSegment> thread, {
  int minMs = 1600,
  int maxMs = 7000,
  int msPerWord = 230,
}) {
  final text = thread
      .map((segment) => segment.isBubble ? segment.text : segment.narration)
      .whereType<String>()
      .join(' ');
  return readingHoldForText(
    text,
    minMs: minMs,
    maxMs: maxMs,
    msPerWord: msPerWord,
  );
}
