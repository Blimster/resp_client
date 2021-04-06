part of resp_client;

///
/// The client for a RESP server.
///
class RespClient {
  final RespServerConnection _connection;
  final StreamReader _streamReader;
  final Queue<Completer> _pendingResponses = Queue();
  bool _isProccessingResponse = false;

  RespClient(this._connection) : _streamReader = StreamReader(_connection.inputStream);

  ///
  /// Writes a RESP type to the server using the
  /// [outputSink] of the underlying server connection and
  /// reads back the RESP type of the response using the
  /// [inputStream] of the underlying server connection.
  ///
  Future<RespType> writeType(RespType data) {
    final completer = Completer<RespType>();
    _pendingResponses.add(completer);
    _connection.outputSink.add(data.serialize());
    _processResponse(false);
    return completer.future;
  }

  Stream<RespType> subscribe() {
    final controller = StreamController<RespType>();
    deserializeRespType(_streamReader).then((response) {
      controller.add(response);
    });
    return controller.stream;
  }

  void _processResponse(bool selfCall) {
    if (_isProccessingResponse == false || selfCall) {
      if (_pendingResponses.isNotEmpty) {
        _isProccessingResponse = true;
        final c = _pendingResponses.removeFirst();
        deserializeRespType(_streamReader).then((response) {
          c.complete(response);
          _processResponse(true);
        });
      } else {
        _isProccessingResponse = false;
      }
    }
  }
}
