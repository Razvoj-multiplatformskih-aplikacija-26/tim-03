import '../center_board.dart';

/// Port to the center's overview for staff. In KT1 the backoffice has its own fake implementation in memory; from KT2
/// an HTTP adapter asks the server. A method that cannot reach the data throws a [RepositoryException].
abstract interface class BoardRepository {
  Future<CenterBoard> board();
}
