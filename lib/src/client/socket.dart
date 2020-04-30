part of resp_client;

class _SocketRespServer implements RespServerConnection {
  final Socket socket;

  _SocketRespServer(this.socket);

  @override
  IOSink get outputSink {
    return socket;
  }

  @override
  Stream<List<int>> get inputStream {
    return socket;
  }

  @override
  Future<void> close() async {
    await socket.flush();
    return socket.close();
  }
}

///
/// Creates a server connection using a socket.
///
Future<RespServerConnection> connectSocket(String host, {int port = 6379, Duration timeout}) async {
  final socket = await Socket.connect(host, port, timeout: timeout);
  return _SocketRespServer(socket);
}
