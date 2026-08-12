import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scenario.dart';

/// Thin wrapper around the irl-backend HTTP API. Swap [baseUrl] via
/// --dart-define=API_BASE_URL=... when deploying somewhere other than
/// localhost.
class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:4000',
            );

  /// Fetches the opening node for a scenario. [scenarioId] is optional -
  /// omit it to get the backend's default, or pass one (e.g. from the dev
  /// picker) to jump straight into a specific scenario.
  Future<Scenario> fetchTodayScenario({String? scenarioId}) async {
    final uri = Uri.parse('$baseUrl/api/scenarios/today').replace(
      queryParameters: scenarioId != null ? {'scenarioId': scenarioId} : null,
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException('Could not load scenario (${response.statusCode}).');
    }
    return Scenario.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Dev/testing convenience: every scenario currently on disk.
  Future<List<ScenarioSummary>> fetchScenarioList() async {
    final uri = Uri.parse('$baseUrl/api/scenarios/list');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException('Could not load scenario list (${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as List;
    return body.map((s) => ScenarioSummary.fromJson(s as Map<String, dynamic>)).toList();
  }

  /// [runningTotal] is what the player has accumulated so far THIS
  /// playthrough (unclamped, summed client-side) - the backend stays
  /// stateless and only needs it to pick the right outcome tier on a
  /// terminal turn.
  Future<TurnResult> submitChoice({
    required String scenarioId,
    required String nodeId,
    required String choiceId,
    required StatDelta runningTotal,
    String? testerId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/scenarios/respond');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'scenarioId': scenarioId,
        'nodeId': nodeId,
        'choiceId': choiceId,
        'runningTotal': runningTotal.toJson(),
        'testerId': testerId,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException('Could not submit your response (${response.statusCode}).');
    }
    return TurnResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}