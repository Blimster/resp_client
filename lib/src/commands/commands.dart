part of resp_commands;

enum SetMode { onlyIfNotExists, onlyIfExists }

///
/// Easy to use API for the Redis commands.
///
class RespCommands {
  final RespClient client;

  RespCommands(this.client);

  List<String> _merge(String first, List<String> additionals) {
    final result = [first];
    result.addAll(additionals);
    return result;
  }

  Future<RespType> _execCmd(List<Object> elements) async {
    return client.writeType(RespArray(elements.map((e) => RespBulkString(e != null ? '$e' : null)).toList(growable: false)));
  }

  String _getBulkString(RespType type) {
    if (type is RespBulkString) {
      return type.payload;
    } else if (type is RespError) {
      throw StateError('error message from server: ${type.payload}');
    }
    throw StateError('unexpected return type: ${type.runtimeType}');
  }

  String _getSimpleString(RespType type) {
    if (type is RespSimpleString) {
      return type.payload;
    } else if (type is RespError) {
      throw StateError('error message from server: ${type.payload}');
    }
    throw StateError('unexpected return type: ${type.runtimeType}');
  }

  int _getInteger(RespType type) {
    if (type is RespInteger) {
      return type.payload;
    } else if (type is RespError) {
      throw StateError('error message from server: ${type.payload}');
    }
    throw StateError('unexpected return type: ${type.runtimeType}');
  }

  ///
  /// Returns a list of connected clients.
  ///
  Future<List<String>> clientList() async {
    final result = await _execCmd(['CLIENT', 'LIST']);
    return _getBulkString(result).split('\n').where((e) => e != null && e.isNotEmpty).toList(growable: false);
  }

  ///
  /// Sets a value for the given key. Returns [true], if the value was successfully set. Otherwise, [false] is returned.
  ///
  Future<bool> set(String key, dynamic value, {Duration expire, SetMode mode}) async {
    final cmd = ['SET', key, value];

    if (expire != null) {
      cmd.addAll(['PX', '${expire.inMilliseconds}']);
    }

    if (mode == SetMode.onlyIfNotExists) {
      cmd.add('NX');
    } else if (mode == SetMode.onlyIfExists) {
      cmd.add('XX');
    }

    final result = await _execCmd(cmd);
    return _getSimpleString(result) == 'OK';
  }

  ///
  /// Returns the value for the given [key]. If no value if present for the key, [null] is returned.
  ///
  Future<String> get(String key) async {
    return _getBulkString(await _execCmd(['GET', key]));
  }

  ///
  /// Removes the value for the given [keys]. Returns the number of deleted values.
  ///
  Future<int> del(List<String> keys) async {
    return _getInteger(await _execCmd(_merge('DEL', keys)));
  }

  ///
  /// Returns the number of values exists for the given [keys]
  ///
  Future<int> exists(List<String> keys) async {
    return _getInteger(await _execCmd(_merge('EXISTS', keys)));
  }

  ///
  /// Return the ttl of the given [key] in seconds. Returns [-1], if the key has no ttl. Returns [-2], if the key does not exists.
  ///
  Future<int> ttl(String key) async {
    return _getInteger(await _execCmd(['TTL', key]));
  }

  ///
  /// Sets the timeout for the given [key]. Returns [true], if the timeout was successfully set. Otherwise, [false] is returned.
  ///
  Future<bool> pexpire(String key, Duration timeout) async {
    return _getInteger(await _execCmd(['PEXPIRE', key, timeout.inMilliseconds])) == 1;
  }

  ///
  /// Selects the Redis logical database. Completes with no value, if the command was successful.
  ///
  Future<void> select(int index) async {
    _getSimpleString(await _execCmd(['SELECT', index])) == 'OK';
    return null;
  }

  ///
  /// Flushes the currently selected database. Completes with no value, if the command was successful.
  ///
  Future<void> flushDb({bool doAsync = false}) async {
    _getSimpleString(await _execCmd(doAsync ? ['FLUSHDB', 'ASYNC'] : ['FLUSHDB'])) == 'OK';
    return null;
  }

  ///
  /// Flushes all databases. Completes with no value, if the command was successful.
  ///
  Future<void> flushAll({bool doAsync = false}) async {
    _getSimpleString(await _execCmd(doAsync ? ['FLUSHALL', 'ASYNC'] : ['FLUSHDB'])) == 'OK';
    return null;
  }

}
