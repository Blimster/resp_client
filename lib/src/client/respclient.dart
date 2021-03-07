part of resp_client;

///
/// A connection to a RESP server. It has to provide an [outputSink] and an [inputStream]. The [outputSink] is used by [RespClient] to write requests to the
/// server. The [inputStream] is used by [RespClient] to read responses from the server.
///
abstract class RespServerConnection {
  StreamSink<List<int>> get outputSink;

  Stream<List<int>> get inputStream;

  Future<void> close();
}

///
/// A client of a RESP server.
///
class RespClient {
  final RespServerConnection _connection;
  final StreamReader _streamReader;
  final Queue<Completer> _pendingResponses = Queue();
  bool _isProccessingResponse = false;

  RespClient(this._connection) : _streamReader = StreamReader(_connection.inputStream);

  ///
  /// Writes a RESP type to the server using the [outputSink] of the underlying server connection and reads back the RESP type of the response using the
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

  ///
  /// Writes a RESP array of bulk strings to the [outputSink] of the underlying server connection and reads back the RESP type of the response using the
  /// [inputStream] of the underlying server connection.
  ///
  /// All elements of [elements] are converted to bulk strings by using to Object.toString().
  ///
  Future<RespType> writeArrayOfBulk(List<Object> elements) async {
    return writeType(RespArray(elements.map((e) => RespBulkString('$e')).toList(growable: false)));
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
