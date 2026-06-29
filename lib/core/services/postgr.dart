import 'package:postgres/postgres.dart';

class DatabaseService {
  static Connection? _connection;

  static Future<Connection> connect() async {
    if (_connection != null) return _connection!;

    _connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'students',
        username: 'MAC',
        password: '1234',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    return _connection!;
  }
}
