part of resp_commands;

///
/// The most basic form of a RESP command.
///
class RespCommandsTier0 {
  final RespClient client;

  RespCommandsTier0(this.client);

  ///
  /// Writes an array of bulk strings to the [outputSink]
  /// of the underlying server connection and reads back
  /// the RESP type of the response.
  ///
  /// All elements of [elements] are converted to bulk
  /// strings by using to Object.toString().
  ///
  Future<RespType> execute(List<Object?> elements) async {
    return client.writeType(RespArray(elements.map((e) => RespBulkString(e?.toString())).toList(growable: false)));
  }
}
