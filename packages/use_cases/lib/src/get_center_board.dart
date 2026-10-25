import 'center_board.dart';
import 'ports/board_repository.dart';

final class GetCenterBoard {
  const GetCenterBoard({required this.boards});

  final BoardRepository boards;

  Future<CenterBoard> call() => boards.board();
}
