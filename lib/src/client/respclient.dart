part of resp_client;

///
/// A connection to a RESP server. It has to provide an [outputSink] and an [inputStream]. The [outputSink] is used by [RespClient] to write requests to the
/// server. The [inputStream] is used by [RespClient] to read responses from the server.
///
abstract class RespServerConnection {
  IOSink get outputSink;

  Stream<List<int>> get inputStream;

  Future<void> close();
}

///
/// A client of a RESP server.
///
class RespClient {
  final RespServerConnection _connection;
  final _StreamReader _streamReader;

  RespClient(this._connection) : _streamReader = _StreamReader(_connection.inputStream);

  ///
  /// Writes a RESP type to the server using the [outputSink] of the underlying server connection and reads back the RESP type of the response using the
  /// [inputStream] of the underlying server connection.
  ///
  Future<RespType> writeType(RespType data) {
    _connection.outputSink.write(data.serialize());
    return _deserializeRespType(_streamReader);
  }
}
