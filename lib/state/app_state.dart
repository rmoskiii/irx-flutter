import 'package:flutter/foundation.dart';
import '../models/scenario.dart';

/// Cumulative player stats, held in memory only for the MVP - no local
/// persistence yet. This is intentional: the backend's results log is the
/// source of truth for "did they come back tomorrow," this is purely for
/// the current session's UI.
class AppState extends ChangeNotifier {
  int savvy = 50;
  int integrity = 50;
  int streetSmarts = 50;

  void applyResult(StatDelta delta) {
    savvy = (savvy + delta.savvy).clamp(0, 100);
    integrity = (integrity + delta.integrity).clamp(0, 100);
    streetSmarts = (streetSmarts + delta.streetSmarts).clamp(0, 100);
    notifyListeners();
  }
}
