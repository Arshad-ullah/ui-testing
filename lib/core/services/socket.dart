import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;

  static void init() {
    socket = IO.io(
      'http://localhost:8000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected: ${socket.id}');
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected');
    });
  }
}
