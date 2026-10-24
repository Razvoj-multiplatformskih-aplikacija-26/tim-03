/// The data could not be reached: no network, a server error, a timeout. Unlike a [DomainError], it says nothing
/// about the rules, so the screen offers to try again.
final class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}
