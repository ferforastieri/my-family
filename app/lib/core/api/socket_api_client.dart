import '../socket/socket_client.dart';

class SocketApiClient {
  const SocketApiClient(this.socket);

  final SocketClient socket;

  Future<T> query<T>(String event, [Object? payload]) {
    return socket.emitAck<T>(event, payload);
  }

  Future<T> mutate<T>(String event, [Object? payload]) {
    return socket.emitAck<T>(event, payload);
  }
}
