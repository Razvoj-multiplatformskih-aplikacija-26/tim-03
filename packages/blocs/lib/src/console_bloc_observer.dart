import 'package:bloc/bloc.dart';

/// Writes one line when a bloc is created or closed, and one for every transition: the bloc, the event and the new
/// state. The apps turn it on in debug builds; the same lines show in the terminal and in the browser console.
final class ConsoleBlocObserver extends BlocObserver {
  const ConsoleBlocObserver(this.log);

  final void Function(String line) log;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('${bloc.runtimeType} · created');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    log('${bloc.runtimeType} · ${transition.event.runtimeType} → ${transition.nextState}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('${bloc.runtimeType} · error: $error');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    log('${bloc.runtimeType} · closed');
  }
}
