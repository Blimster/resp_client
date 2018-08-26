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

  List<String> _mergeLists(List<String> first, List<String> additionals) {
    final result = <String>[];
    result.addAll(first ?? []);
    result.addAll(additionals ?? []);
    return result;
  }

  Future<RespType> _execCmd(List<Object> elements) async {
    return client.writeArrayOfBulk(elements);
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

  List<RespType> _getArray(RespType type) {
    if (type is RespArray) {
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

  ///
  /// Sends the authentication password to the server. Returns true, if the password matches, otherwise false.
  ///
  Future<bool> auth(String password) async {
    final result = await _execCmd(['AUTH', password]);
    if (result is RespSimpleString) {
      return result.payload == 'OK';
    } else {
      return false;
    }
  }

  ///
  /// Sets field in the hash stored at key to value. If key does not exist, a new key
  /// holding a hash is created. If field already exists in the hash, it is overwritten.
  ///
  /// True, if field is a new field in the hash and value was set. False, if field already
  /// exists in the hash and the value was updated.
  ///
  Future<bool> hset(String key, String field, dynamic value) async {
    final result = _getInteger(await _execCmd(['HSET', key, field, value]));
    return result == 1;
  }

  ///
  /// Sets field in the hash stored at key to value, only if field does not yet exist.
  /// If key does not exist, a new key holding a hash is created. If field already
  /// exists, this operation has no effect.
  ///
  /// True, if field is a new field in the hash and value was set. False, if field already
  /// exists in the hash and no operation was performed.
  ///
  Future<bool> hsetnx(String key, String field, dynamic value) async {
    final result = _getInteger(await _execCmd(['HSETNX', key, field, value]));
    return result == 1;
  }

  ///
  /// Sets the specified fields to their respective values in the hash stored at key. This
  /// command overwrites any specified fields already existing in the hash. If key does
  /// not exist, a new key holding a hash is created.
  ///
  /// True, if the operation was successful.
  ///
  Future<bool> hmset(String key, Map<String, String> keysAndValues) async {
    final params = <String>[];
    keysAndValues.forEach((k, v) {
      params.add(k);
      params.add(v);
    });

    final result = _getSimpleString(await _execCmd(_mergeLists(['HMSET', key], params)));
    return result == 'OK';
  }

  ///
  /// Returns the value associated with field in the hash stored at key.
  ///
  /// The value associated with field, or nil when field is not present in the hash or key
  /// does not exist.
  ///
  Future<String> hget(String key, String field) async {
    return _getBulkString(await _execCmd(['HGET', key, field]));
  }

  ///
  /// Returns all fields and values of the hash stored at key. In the returned value, every
  /// field name is followed by its value, so the length of the reply is twice the size of
  /// the hash.
  ///
  /// Map of fields and their values stored in the hash, or an empty list when key does
  /// not exist.
  ///
  Future<Map<String, String>> hgetall(String key) async {
    final result = _getArray(await _execCmd(['HGETALL', key]));

    final map = <String, String>{};
    for (int i = 0; i < result.length; i += 2) {
      map[_getBulkString(result[i])] = _getBulkString(result[i + 1]);
    }
    return map;
  }

  ///
  /// Returns the values associated with the specified fields in the hash stored at key.
  ///
  /// For every field that does not exist in the hash, a nil value is returned. Because
  /// non-existing keys are treated as empty hashes, running HMGET against a non-existing
  /// key will return a list of nil values.
  ///
  /// A map of values associated with the given fields, in the same order as they are requested.
  ///
  Future<Map<String, String>> hmget(String key, List<String> fields) async {
    final result = _getArray(await _execCmd(_mergeLists(['HMGET', key], fields)));

    final hash = <String, String>{};
    for (int i = 0; i < fields.length; i++) {
      hash[fields[i]] = _getBulkString(result[i]);
    }
    return hash;
  }

  ///
  /// Removes the specified fields from the hash stored at key. Specified fields that do not
  /// exist within this hash are ignored. If key does not exist, it is treated as an empty
  /// hash and this command returns 0.
  ///
  /// The number of fields that were removed from the hash, not including specified but non
  /// existing fields.
  ///
  Future<int> hdel(String key, List<String> fields) async {
    return _getInteger(await _execCmd(_mergeLists(['HDEL', key], fields)));
  }

  ///
  /// Returns if field is an existing field in the hash stored at key.
  ///
  /// True, if the hash contains field. False, if the hash does not contain field, or key
  /// does not exist.
  ///
  Future<bool> hexists(String key, String field) async {
    final result = _getInteger(await _execCmd(['HEXISTS', key, field]));
    return result == 1;
  }

  ///
  /// Returns all field names in the hash stored at key.
  ///
  /// List of fields in the hash, or an empty list when key does not exist.
  ///
  Future<List<String>> hkeys(String key) async {
    final result = _getArray(await _execCmd(['HKEYS', key]));
    return result.map((e) => _getBulkString(e)).toList(growable: false);
  }

  ///
  /// Returns all values in the hash stored at key.
  ///
  /// List of values in the hash, or an empty list when key does not exist.
  ///
  Future<List<String>> hvals(String key) async {
    final result = _getArray(await _execCmd(['HVALS', key]));
    return result.map((e) => _getBulkString(e)).toList(growable: false);
  }
}
