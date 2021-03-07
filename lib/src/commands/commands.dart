part of resp_commands;

enum SetMode { onlyIfNotExists, onlyIfExists }

class InsertMode {
  static const before = InsertMode._('BEFORE');
  static const after = InsertMode._('AFTER');

  final String _value;

  const InsertMode._(this._value);
}

///
/// Easy to use API for the Redis commands.
///
class RespCommands {
  final RespClient client;

  RespCommands(this.client);

  Future<RespType> _execCmd(List<Object> elements) async {
    return client.writeArrayOfBulk(elements);
  }

  String? _getBulkString(RespType type) {
    if (type is RespBulkString) {
      return type.payload;
    } else if (type is RespArray && type.payload == null) {
      return null; // redis sometimes return a null array to represent a null value
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

  bool _getBool(RespType type) {
    try {
      return _getSimpleString(type) == 'OK';
    } on StateError {
      return false;
    }
  }

  List<RespType>? _getArray(RespType type) {
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
    final bulkString = _getBulkString(result);
    if (bulkString != null) {
      return bulkString.split('\n').where((e) => e.isNotEmpty).toList(growable: false);
    }
    return [];
  }

  ///
  /// Sets a value for the given key. Returns [true], if the value was successfully set. Otherwise, [false] is returned.
  ///
  Future<bool> set(String key, Object value, {Duration? expire, SetMode? mode}) async {
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
  Future<String?> get(String key) async {
    return _getBulkString(await _execCmd(['GET', key]));
  }

  ///
  /// Removes the value for the given [keys]. Returns the number of deleted values.
  ///
  Future<int> del(List<String> keys) async {
    return _getInteger(await _execCmd(['DEL', ...keys]));
  }

  ///
  /// Returns the number of values exists for the given [keys]
  ///
  Future<int> exists(List<String> keys) async {
    return _getInteger(await _execCmd(['EXISTS', ...keys]));
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
  Future<bool> hset(String key, String field, Object value) async {
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
  Future<bool> hsetnx(String key, String field, Object value) async {
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

    final result = _getSimpleString(await _execCmd(['HMSET', key, ...params]));
    return result == 'OK';
  }

  ///
  /// Returns the value associated with field in the hash stored at key.
  ///
  /// The value associated with field, or nil when field is not present in the hash or key
  /// does not exist.
  ///
  Future<String?> hget(String key, String field) async {
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
  Future<Map<String, String?>> hgetall(String key) async {
    final result = _getArray(await _execCmd(['HGETALL', key]));

    if (result != null) {
      final map = <String, String?>{};
      for (var i = 0; i < result.length; i += 2) {
        final key = _getBulkString(result[i]);
        final value = _getBulkString(result[i + 1]);
        if (key != null) {
          map[key] = value;
        }
      }
      return map;
    }
    return {};
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
  Future<Map<String, String?>> hmget(String key, List<String> fields) async {
    final result = _getArray(await _execCmd(['HMGET', key, ...fields]));

    if (result != null) {
      final hash = <String, String?>{};
      for (var i = 0; i < fields.length; i++) {
        hash[fields[i]] = _getBulkString(result[i]);
      }
      return hash;
    }
    return {};
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
    return _getInteger(await _execCmd(['HDEL', key, ...fields]));
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
    if (result != null) {
      return result.map((e) => _getBulkString(e)!).toList(growable: false);
    }
    return [];
  }

  ///
  /// Returns all values in the hash stored at key.
  ///
  /// List of values in the hash, or an empty list when key does not exist.
  ///
  Future<List<String?>> hvals(String key) async {
    final result = _getArray(await _execCmd(['HVALS', key]));
    if (result != null) {
      return result.map((e) => _getBulkString(e)).toList(growable: false);
    }
    return [];
  }

  ///
  /// See https://redis.io/commands/blpop
  ///
  Future<List<String?>> blpop(List<String> keys, int timeout) async {
    final result = _getArray(await _execCmd(['BLPOP', ...keys, timeout]));
    if (result != null) {
      return result.map((e) => _getBulkString(e)).toList(growable: false);
    }
    return [];
  }

  ///
  /// BRPOP is a blocking list pop primitive. It is the blocking version of
  /// RPOP because it blocks the connection when there are no elements to
  /// pop from any of the given lists. An element is popped from the tail
  /// of the first list that is non-empty, with the given keys being checked
  /// in the order that they are given.
  ///
  /// See the BLPOP documentation for the exact semantics, since BRPOP is
  /// identical to BLPOP with the only difference being that it pops elements
  /// from the tail of a list instead of popping from the head.
  ///
  /// Returns specifically:
  ///
  /// A nil multi-bulk when no element could be popped and the timeout expired.
  ///
  /// A two-element multi-bulk with the first element being the name of the key
  /// where an element was popped and the second element being the value of the
  /// popped element.
  ///
  Future<List<String?>> brpop(List<String> keys, int timeout) async {
    final result = _getArray(await _execCmd(['BRPOP', ...keys, timeout]));
    if (result != null) {
      return result.map((e) => _getBulkString(e)).toList(growable: false);
    }
    return [];
  }

  ///
  /// BRPOPLPUSH is the blocking variant of RPOPLPUSH. When source contains
  /// elements, this command behaves exactly like RPOPLPUSH. When used inside
  /// a MULTI/EXEC block, this command behaves exactly like RPOPLPUSH. When
  /// source is empty, Redis will block the connection until another client
  /// pushes to it or until timeout is reached. A timeout of zero can be
  /// used to block indefinitely.
  ///
  /// See RPOPLPUSH for more information.
  ///
  /// Returns the element being popped from source and pushed to destination.
  /// If timeout is reached, a Null reply is returned.
  ///
  Future<String?> brpoplpush(String source, String destination, int timeout) async {
    return _getBulkString(await _execCmd(['BRPOPLPUSH', source, destination, timeout]));
  }

  ///
  /// Returns the element at index index in the list stored at key. The
  /// index is zero-based, so 0 means the first element, 1 the second
  /// element and so on. Negative indices can be used to designate elements
  /// starting at the tail of the list. Here, -1 means the last element,
  /// -2 means the penultimate and so forth.
  ///
  /// When the value at key is not a list, an error is returned.
  ///
  /// Returns the requested element, or nil when index is out of range.
  ///
  Future<String?> lindex(String key, int index) async {
    return _getBulkString(await _execCmd(['LINDEX', key, index]));
  }

  ///
  /// Inserts value in the list stored at key either before or after the
  /// reference value pivot.
  ///
  /// When key does not exist, it is considered an empty list and no
  /// operation is performed.
  ///
  /// An error is returned when key exists but does not hold a list value.
  ///
  /// Returns the length of the list after the insert operation, or -1
  /// when the value pivot was not found.
  ///
  Future<int> linsert(String key, InsertMode insertMode, Object pivot, Object value) async {
    return _getInteger(await _execCmd(['LINSERT', key, insertMode._value, pivot, value]));
  }

  ///
  /// Returns the length of the list stored at key. If key does not exist,
  /// it is interpreted as an empty list and 0 is returned. An error is
  /// returned when the value stored at key is not a list.
  ///
  /// Returns the length of the list at key.
  ///
  Future<int> llen(String key) async {
    return _getInteger(await _execCmd(['LLEN', key]));
  }

  ///
  /// Removes and returns the first element of the list stored at key.
  ///
  /// Returns the value of the first element, or nil when key does not exist.
  ///
  Future<String?> lpop(String key) async {
    return _getBulkString(await _execCmd(['LPOP', key]));
  }

  ///
  /// Insert all the specified values at the head of the list stored at key.
  /// If key does not exist, it is created as empty list before performing
  /// the push operations. When key holds a value that is not a list, an
  /// error is returned.
  ///
  /// It is possible to push multiple elements using a single command call
  /// just specifying multiple arguments at the end of the command. Elements
  /// are inserted one after the other to the head of the list, from the
  /// leftmost element to the rightmost element. So for instance the command
  /// LPUSH mylist a b c will result into a list containing c as first
  /// element, b as second element and a as third element.
  ///
  /// Returns the length of the list after the push operations.
  ///
  Future<int> lpush(String key, List<Object> values) async {
    return _getInteger(await _execCmd(['LPUSH', key, ...values]));
  }

  ///
  /// Inserts value at the head of the list stored at key, only if key
  /// already exists and holds a list. In contrary to LPUSH, no operation
  /// will be performed when key does not yet exist.
  ///
  Future<int> lpushx(String key, List<Object> values) async {
    return _getInteger(await _execCmd(['LPUSHX', key, ...values]));
  }

  ///
  /// Returns the specified elements of the list stored at key. The offsets
  /// start and stop are zero-based indexes, with 0 being the first element
  /// of the list (the head of the list), 1 being the next element and so on.
  ///
  /// These offsets can also be negative numbers indicating offsets starting
  /// at the end of the list. For example, -1 is the last element of the list,
  /// -2 the penultimate, and so on.
  ///
  /// Note that if you have a list of numbers from 0 to 100, LRANGE list 0 10
  /// will return 11 elements, that is, the rightmost item is included. This
  /// is not be consistent with behavior of range-related functions in the Dart
  /// programming language.
  ///
  /// Out of range indexes will not produce an error. If start is larger than
  /// the end of the list, an empty list is returned. If stop is larger than
  /// the actual end of the list, Redis will treat it like the last element of
  /// the list.
  ///
  /// Returns list of elements in the specified range.
  ///
  Future<List<String?>> lrange(String key, int start, int stop) async {
    final result = _getArray(await _execCmd(['LRANGE', key, start, stop]));
    if (result != null) {
      return result.map((e) => _getBulkString(e)).toList(growable: false);
    }
    return [];
  }

  ///
  /// Time complexity: O(N) where N is the length of the list.
  ///
  /// Removes the first count occurrences of elements equal to value from
  /// the list stored at key. The count argument influences the operation
  /// in the following ways:
  ///
  /// count > 0: Remove elements equal to value moving from head to tail.
  ///
  /// count < 0: Remove elements equal to value moving from tail to head.
  ///
  /// count = 0: Remove all elements equal to value.
  ///
  /// For example, LREM list -2 "hello" will remove the last two occurrences
  /// of "hello" in the list stored at list.
  ///
  /// Note that non-existing keys are treated like empty lists, so when key
  /// does not exist, the command will always return 0.
  ///
  /// Returns the number of removed elements.
  ///
  Future<int> lrem(String key, int count, Object value) async {
    return _getInteger(await _execCmd(['LREM', key, count, value]));
  }

  ///
  /// Sets the list element at index to value. For more information on the index argument, see LINDEX.
  ///
  /// False is returned for out of range indexes.
  ///
  Future<bool> lset(String key, int index, Object value) async {
    return _getBool(await _execCmd(['LSET', key, index, value]));
  }

  ///
  /// Trim an existing list so that it will contain only the specified range of elements specified.
  /// Both start and stop are zero-based indexes, where 0 is the first element of the list (the head),
  /// 1 the next element and so on.
  ///
  /// For example: LTRIM foobar 0 2 will modify the list stored at foobar so that only the first
  /// three elements of the list will remain.
  ///
  /// start and end can also be negative numbers indicating offsets from the end of the list,
  /// where -1 is the last element of the list, -2 the penultimate element and so on.
  ///
  /// Out of range indexes will not produce an error: if start is larger than the end of the list,
  /// or start > end, the result will be an empty list (which causes key to be removed). If end
  /// is larger than the end of the list, Redis will treat it like the last element of the list.
  ///
  /// A common use of LTRIM is together with LPUSH / RPUSH. For example:
  ///
  /// LPUSH mylist someelement
  ///
  /// LTRIM mylist 0 99
  ///
  /// This pair of commands will push a new element on the list, while making sure that the list
  /// will not grow larger than 100 elements. This is very useful when using Redis to store logs
  /// for example. It is important to note that when used in this way LTRIM is an O(1) operation
  /// because in the average case just one element is removed from the tail of the list.
  ///
  Future<void> ltrim(String key, int start, int stop) async {
    _getSimpleString(await _execCmd(['LTRIM', key, start, stop]));
    return null;
  }

  ///
  /// Removes and returns the last element of the list stored at key.
  ///
  /// Returns the value of the last element, or nil when key does not exist.
  ///
  Future<String?> rpop(String key) async {
    return _getBulkString(await _execCmd(['RPOP', key]));
  }

  ///
  /// Atomically returns and removes the last element (tail) of the list stored at source,
  /// and pushes the element at the first element (head) of the list stored at destination.
  ///
  /// For example: consider source holding the list a,b,c, and destination holding the
  /// list x,y,z. Executing RPOPLPUSH results in source holding a,b and destination holding c,x,y,z.
  ///
  /// If source does not exist, the value nil is returned and no operation is performed.
  /// If source and destination are the same, the operation is equivalent to removing the
  /// last element from the list and pushing it as first element of the list, so it can
  /// be considered as a list rotation command.
  ///
  /// Returns the element being popped and pushed.
  ///
  Future<String?> rpoplpush(String source, String destination) async {
    return _getBulkString(await _execCmd(['RPOPLPUSH', source, destination]));
  }

  ///
  /// Insert all the specified values at the tail of the list stored at key.
  /// If key does not exist, it is created as empty list before performing
  /// the push operation. When key holds a value that is not a list, an
  /// error is returned.
  ///
  /// It is possible to push multiple elements using a single command call
  /// just specifying multiple arguments at the end of the command. Elements
  /// are inserted one after the other to the tail of the list, from the
  /// leftmost element to the rightmost element. So for instance the command
  /// RPUSH mylist a b c will result into a list containing a as first
  /// element, b as second element and c as third element.
  ///
  /// Returns the length of the list after the push operation.
  ///
  Future<int> rpush(String key, List<Object> values) async {
    return _getInteger(await _execCmd(['RPUSH', key, ...values]));
  }

  ///
  /// Inserts value at the tail of the list stored at key, only if key already
  /// exists and holds a list. In contrary to RPUSH, no operation will be
  /// performed when key does not yet exist.
  ///
  /// Returns the length of the list after the push operation.
  ///
  Future<int> rpushx(String key, List<Object> values) async {
    return _getInteger(await _execCmd(['RPUSHX', key, ...values]));
  }

  ///
  /// The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN
  /// are used in order to incrementally iterate over a collection of elements.
  ///
  /// See https://redis.io/commands/scan for more detailed documentation.
  ///
  Future<ScanResult> scan(int cursor, {String? pattern, int? count}) async {
    final result = _getArray(await _execCmd([
      'SCAN',
      '$cursor',
      if (pattern != null) ...['MATCH', pattern],
      if (count != null) ...['COUNT', count],
    ]));
    return ScanResult._(result);
  }

  ///
  /// Return the number of keys in the currently-selected database.
  ///
  Future<int> dbsize() async {
    return _getInteger(await _execCmd(['DBSIZE']));
  }

  ///
  /// The INFO command returns information and statistics
  /// about the server in a format that is simple to parse
  /// by computers and easy to read by humans.
  ///
  /// The optional parameter can be used to select a
  /// specific section of information:
  /// server: General information about the Redis server
  /// clients: Client connections section
  /// memory: Memory consumption related information
  /// persistence: RDB and AOF related information
  /// stats: General statistics
  /// replication: Master/replica replication information
  /// cpu: CPU consumption statistics
  /// commandstats: Redis command statistics
  /// cluster: Redis Cluster section
  /// modules: Modules section
  /// keyspace: Database related statistics
  /// modules: Module related sections
  /// errorstats: Redis error statistics
  ///
  /// It can also take the following values:
  /// all: Return all sections (excluding module generated ones)
  /// default: Return only the default set of sections
  /// everything: Includes all and modules
  ///
  /// When no parameter is provided, the default option is
  /// assumed.
  ///
  /// Returns as a collection of text lines.
  ///
  /// Lines can contain a section name (starting with a
  /// # character) or a property. All the properties are in
  /// the form of field:value terminated by \r\n.
  Future<String?> info([String? section]) async {
    return _getBulkString(await _execCmd(['INFO', if (section != null) section]));
  }

  ///
  /// Increments the number stored at key by one. If the
  /// key does not exist, it is set to 0 before performing
  /// the operation. An error is returned if the key
  /// contains a value of the wrong type or contains a
  /// string that can not be represented as integer. This
  /// operation is limited to 64 bit signed integers.
  ///
  /// Note: this is a string operation because Redis does
  /// not have a dedicated integer type. The string stored
  /// at the key is interpreted as a base-10 64 bit signed
  /// integer to execute the operation.
  ///
  /// Redis stores integers in their integer
  /// representation, so for string values that actually
  /// hold an integer, there is no overhead for storing the
  /// string representation of the integer.
  ///
  /// Returns the value of key after the increment.
  ///
  Future<int> incr(String key) async {
    return _getInteger(await _execCmd(['INCR', key]));
  }

  ///
  /// Increments the number stored at key by increment. If
  /// the key does not exist, it is set to 0 before
  /// performing the operation. An error is returned if the
  /// key contains a value of the wrong type or contains a
  /// string that can not be represented as integer. This
  /// operation is limited to 64 bit signed integers.
  ///
  /// See [incr] for extra information on increment/
  /// decrement operations.
  ///
  /// Returns he value of key after the increment.
  ///
  Future<int> incrby(String key, int increment) async {
    return _getInteger(await _execCmd(['INCRBY', key, '$increment']));
  }

  ///
  /// Decrements the number stored at key by one. If the
  /// key does not exist, it is set to 0 before performing
  /// the operation. An error is returned if the key
  /// contains a value of the wrong type or contains a
  /// string that can not be represented as integer. This
  /// operation is limited to 64 bit signed integers.
  ///
  /// See [incr] for extra information on increment/
  /// decrement operations.
  ///
  /// Returns the value of key after the decrement.
  ///
  Future<int> decr(String key) async {
    return _getInteger(await _execCmd(['DECR', key]));
  }

  ///
  /// Decrements the number stored at key by decrement. If
  /// the key does not exist, it is set to 0 before
  /// performing the operation. An error is returned if the
  /// key contains a value of the wrong type or contains a
  /// string that can not be represented as integer. This
  /// operation is limited to 64 bit signed integers.
  ///
  /// See [incr] for extra information on increment/
  /// decrement operations.
  ///
  /// Returns the value of key after the decrement.
  ///
  Future<int> decrby(String key, int decrement) async {
    return _getInteger(await _execCmd(['DECRBY', key, '$decrement']));
  }

  ///
  /// Posts a message to the given channel.
  ///
  /// Returns the number of clients that received the message.
  ///
  Future<int> publish(String channel, Object message) async {
    return _getInteger(await _execCmd(['PUBLISH', channel, message]));
  }

  ///
  /// Subscribes the client to the specified channels.
  ///
  /// Once the client enters the subscribed state it is not supposed to
  /// issue any other commands, except for additional SUBSCRIBE,
  /// PSUBSCRIBE, UNSUBSCRIBE and PUNSUBSCRIBE commands.
  ///
  Future<void> subscribe(List<String> channels) async {
    await _execCmd(['SUBSCRIBE', ...channels]);
  }

  ///
  /// Unsubscribes the client from the given channels, or from all of them
  /// if none is given.
  ///
  /// When no channels are specified, the client is unsubscribed from all
  /// the previously subscribed channels. In this case, a message for every
  /// unsubscribed channel will be sent to the client.
  ///
  Future<void> unsubscribe(Iterable<String> channels) async {
    await _execCmd(['UNSUBSCRIBE', ...channels]);
  }
}

///
/// The result of a scan operation.
///
class ScanResult {
  int _cursor = 0;
  List<String> _keys = [];

  ScanResult._(List<RespType>? result) {
    if (result != null && result.length == 2) {
      final element1 = result[0] as RespBulkString;
      final payload1 = element1.payload;
      if (payload1 != null) {
        _cursor = int.parse(payload1);
      }

      final element2 = result[1] as RespArray;
      final payload2 = element2.payload;
      if (payload2 != null) {
        _keys = payload2.cast<RespBulkString>().map((e) => e.payload!).toList(growable: false);
      }
    }
  }

  int get cursor => _cursor;

  List<String> get keys => _keys;

  ///
  /// Returns true, if there more elements (cursor != 0).
  ///
  bool get hasMoreElements => _cursor != 0;

  @override
  String toString() => 'ScanResult{cursor: $_cursor, keys: $_keys}';
}
