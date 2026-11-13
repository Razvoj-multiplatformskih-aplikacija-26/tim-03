import 'package:domain/domain.dart';

import 'ports/center_repository.dart';

final class GetOpeningHours {
  const GetOpeningHours({required this.center});

  final CenterRepository center;

  Future<OpeningHours> call() => center.openingHours();
}
