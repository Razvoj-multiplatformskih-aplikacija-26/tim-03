import 'package:domain/domain.dart';

abstract interface class CenterRepository {
  Future<OpeningHours> openingHours();
}
