final class ServerConfig {
  const ServerConfig({required this.host, required this.port, required this.databaseUrl, this.demoPassword});

  factory ServerConfig.fromEnvironment(Map<String, String> environment) => ServerConfig(
    host: environment['HOST'] ?? '127.0.0.1',
    port: int.parse(environment['PORT'] ?? '8080'),
    databaseUrl:
        environment['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL is not set. Copy .env.example to .env in the repository root.')),
    demoPassword: environment['DEMO_PASSWORD'],
  );

  final String host;
  final int port;
  final String databaseUrl;
  final String? demoPassword;
}
