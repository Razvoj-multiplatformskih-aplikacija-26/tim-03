import '../center_board.dart';

abstract interface class BoardRepository {
  Future<CenterBoard> board();
}
