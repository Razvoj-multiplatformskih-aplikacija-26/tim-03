import 'package:domain/domain.dart';

/// How many times an action decides again when someone changed the order in the meantime.
const saveAttempts = 3;

/// Runs [attempt] again while the repository answers [OrderChanged]. Every attempt reads fresh data,
/// so the domain decides on what is stored now and a late client gets the domain's answer.
Future<Result<ServiceOrder>> retryOnChange(Future<Result<ServiceOrder>> Function() attempt) async {
  for (var count = 1; ; count++) {
    final result = await attempt();
    if (result.errorOrNull is! OrderChanged || count == saveAttempts) return result;
  }
}
