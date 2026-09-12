import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scenario.dart';

/// A saved run, written at day boundaries only.
///
/// Deliberately minimal. It stores the raw state the server needs to resolve a
/// node, and nothing the server can work out for itself: derived bands are
/// recomputed on every read, and the node itself is re-resolved rather than
/// stored rendered. What is persisted is the run, not the screen.
class RunSnapshot {
  /// Format version of THIS record. Bumped when the shape below changes.
  /// A snapshot with an unknown version is discarded rather than guessed at.
  static const int currentVersion = 1;

  final int snapshotVersion;

  /// Version of the authored content at the time of writing. Compared on
  /// resume; a mismatch retires the run. See [RunStore.read].
  final int contentRevision;

  final String scenarioId;

  /// The NEXT day's opening node — not the node that closed the last day.
  /// Resuming therefore opens on the new day, which is the only reading that
  /// makes "come back tomorrow" mean anything.
  final String nodeId;

  /// The day [nodeId] opens. Display and diagnostics only; the server decides
  /// what the node actually is.
  final int? day;

  /// Opaque and verbatim, including derived bands. The server recomputes the
  /// bands regardless, so storing them costs nothing and filtering them would
  /// risk dropping a key the engine needs.
  final Map<String, dynamic> state;

  final StatDelta runningTotal;
  final List<TurnBreakdown> breakdown;
  final DateTime startedAt;
  final DateTime updatedAt;

  const RunSnapshot({
    required this.snapshotVersion,
    required this.contentRevision,
    required this.scenarioId,
    required this.nodeId,
    required this.state,
    required this.runningTotal,
    required this.breakdown,
    required this.startedAt,
    required this.updatedAt,
    this.day,
  });

  factory RunSnapshot.fromJson(Map<String, dynamic> json) {
    return RunSnapshot(
      snapshotVersion: json['snapshotVersion'] as int? ?? 0,
      contentRevision: json['contentRevision'] as int? ?? 0,
      scenarioId: json['scenarioId'] as String,
      nodeId: json['nodeId'] as String,
      day: json['day'] as int?,
      state: Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      runningTotal:
          StatDelta.fromJson(json['runningTotal'] as Map<String, dynamic>),
      breakdown: (json['breakdown'] as List? ?? const [])
          .map((t) => TurnBreakdown.fromJson(t as Map<String, dynamic>))
          .toList(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'snapshotVersion': snapshotVersion,
        'contentRevision': contentRevision,
        'scenarioId': scenarioId,
        'nodeId': nodeId,
        if (day != null) 'day': day,
        'state': state,
        'runningTotal': runningTotal.toJson(),
        'breakdown': breakdown.map((t) => t.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Why a stored run could not be resumed. Surfaced so the caller can say
/// something true to the player instead of failing silently.
enum RunDiscardReason {
  /// Written by a build whose record shape this one cannot read.
  unknownFormat,

  /// The scenario has been re-authored since. Resuming would run saved state
  /// against content it was never written for, and the failure would be
  /// invisible: conditions on removed keys simply stop matching.
  contentChanged,

  /// Present but unreadable.
  corrupt,
}

class RunReadResult {
  final RunSnapshot? snapshot;
  final RunDiscardReason? discarded;

  const RunReadResult.found(this.snapshot) : discarded = null;
  const RunReadResult.none()
      : snapshot = null,
        discarded = null;
  const RunReadResult.discarded(this.discarded) : snapshot = null;

  bool get hasRun => snapshot != null;
}

/// One saved run per scenario. Replay overwrites; there are no save slots.
///
/// This is the only run persistence in the app. [AppState] keeps the
/// cross-scenario stat pool under its own key with its own lifecycle and is
/// deliberately not stored here.
class RunStore {
  static String _key(String scenarioId) => 'run:$scenarioId';

  /// Reads the run for [scenarioId], validating it against the content the
  /// server is currently serving.
  ///
  /// [currentContentRevision] must come from the live scenario payload, not
  /// from the snapshot. A run whose content has moved on is discarded rather
  /// than resumed — see [RunDiscardReason.contentChanged].
  static Future<RunReadResult> read(
    String scenarioId, {
    required int currentContentRevision,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scenarioId));
    if (raw == null) return const RunReadResult.none();

    RunSnapshot snapshot;
    try {
      snapshot = RunSnapshot.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear(scenarioId);
      return const RunReadResult.discarded(RunDiscardReason.corrupt);
    }

    if (snapshot.snapshotVersion != RunSnapshot.currentVersion) {
      await clear(scenarioId);
      return const RunReadResult.discarded(RunDiscardReason.unknownFormat);
    }

    if (snapshot.contentRevision != currentContentRevision) {
      await clear(scenarioId);
      return const RunReadResult.discarded(RunDiscardReason.contentChanged);
    }

    return RunReadResult.found(snapshot);
  }

  static Future<void> write(RunSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(snapshot.scenarioId), jsonEncode(snapshot.toJson()));
  }

  static Future<void> clear(String scenarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(scenarioId));
  }
}