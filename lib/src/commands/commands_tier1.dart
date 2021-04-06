part of resp_commands;

///
/// The mode when to set a value for a key.
///
enum SetMode {
  onlyIfNotExists,
  onlyIfExists,
}

///
/// The mode how to handle expiration.
///
class ExpireMode {
  final DateTime? timestamp;
  final Duration? time;

  ExpireMode.timestamp(this.timestamp) : time = null;
  ExpireMode.time(this.time) : timestamp = null;
  ExpireMode.keepTtl()
      : timestamp = null,
        time = null;
}

///
/// Where to insert a value.
///
class InsertMode {
  static const before = InsertMode._('BEFORE');
  static const after = InsertMode._('AFTER');

  final String _value;

  const InsertMode._(this._value);
}

///
/// Type of a Redis client.
///
class ClientType {
  static const normal = ClientType._('normal');
  static const master = ClientType._('master');
  static const replica = ClientType._('replica');
  static const pubsub = ClientType._('pubsub');

  final String _value;

  const ClientType._(this._value);
}

///
/// Commands of tier 1 always return a [RespType]. It is up
/// to the consumer to convert the result correctly into the
/// concrete subtype.
///
class RespCommandsTier1 {
  final RespCommandsTier0 tier0;

  RespCommandsTier1(RespClient client) : tier0 = RespCommandsTier0(client);
  RespCommandsTier1.tier0(this.tier0);

  Future<RespType> info([String? section]) async {
    return tier0.execute([
      'INFO',
      if (section != null) section,
    ]);
  }

  Future<RespType> clientList({ClientType? type, List<String> ids = const []}) async {
    return tier0.execute([
      'CLIENT',
      'LIST',
      if (type != null) ...['TYPE', type._value],
      if (ids.isNotEmpty) ...['ID', ...ids],
    ]);
  }

  Future<RespType> select(int index) async {
    return tier0.execute([
      'SELECT',
      index,
    ]);
  }

  Future<RespType> dbsize() async {
    return tier0.execute([
      'DBSIZE',
    ]);
  }

  Future<RespType> auth(String password) async {
    return tier0.execute([
      'AUTH',
      password,
    ]);
  }

  Future<RespType> flushDb({bool? doAsync}) async {
    return tier0.execute([
      'FLUSHDB',
      if (doAsync != null) doAsync ? 'ASYNC' : 'SYNC',
    ]);
  }

  Future<RespType> flushAll({bool? doAsync}) async {
    return tier0.execute([
      'FLUSHALL',
      if (doAsync != null) doAsync ? 'ASYNC' : 'SYNC',
    ]);
  }

  Future<RespType> set(String key, Object value, {ExpireMode? expire, SetMode? mode, bool get = false}) async {
    final expireTime = expire?.time;
    final expireTimestamp = expire?.timestamp;
    return tier0.execute([
      'SET',
      key,
      value,
      if (expireTime != null) ...['PX', '${expireTime.inMilliseconds}'],
      if (expireTimestamp != null) ...['PXAT', '${expireTimestamp.millisecondsSinceEpoch}'],
      if (expire != null && expireTime == null && expireTimestamp == null) 'KEEPTTL',
      if (mode == SetMode.onlyIfNotExists) 'NX',
      if (mode == SetMode.onlyIfExists) 'XX',
      if (get) 'GET',
    ]);
  }

  Future<RespType> get(String key) async {
    return tier0.execute([
      'GET',
      key,
    ]);
  }

  Future<RespType> del(List<String> keys) async {
    return tier0.execute([
      'DEL',
      ...keys,
    ]);
  }

  Future<RespType> exists(List<String> keys) async {
    return tier0.execute([
      'EXISTS',
      ...keys,
    ]);
  }

  Future<RespType> ttl(String key) async {
    return tier0.execute([
      'TTL',
      key,
    ]);
  }

  Future<RespType> pexpire(String key, Duration timeout) async {
    return tier0.execute([
      'PEXPIRE',
      key,
      timeout.inMilliseconds,
    ]);
  }

  Future<RespType> hset(String key, String field, Object value) async {
    return tier0.execute([
      'HSET',
      key,
      field,
      value,
    ]);
  }

  Future<RespType> hsetnx(String key, String field, Object value) async {
    return tier0.execute([
      'HSETNX',
      key,
      field,
      value,
    ]);
  }

  Future<RespType> hmset(String key, Map<String, String> keysAndValues) async {
    return tier0.execute([
      'HMSET',
      key,
      ...keysAndValues.entries.expand((e) => [e.key, e.value]),
    ]);
  }

  Future<RespType> hget(String key, String field) async {
    return tier0.execute([
      'HGET',
      key,
      field,
    ]);
  }

  Future<RespType> hgetall(String key) async {
    return tier0.execute([
      'HGETALL',
      key,
    ]);
  }

  Future<RespType> hmget(String key, List<String> fields) async {
    return tier0.execute([
      'HMGET',
      key,
      ...fields,
    ]);
  }

  Future<RespType> hdel(String key, List<String> fields) async {
    return tier0.execute([
      'HDEL',
      key,
      ...fields,
    ]);
  }

  Future<RespType> hexists(String key, String field) async {
    return tier0.execute([
      'HEXISTS',
      key,
      field,
    ]);
  }

  Future<RespType> hkeys(String key) async {
    return tier0.execute([
      'HKEYS',
      key,
    ]);
  }

  Future<RespType> hvals(String key) async {
    return tier0.execute([
      'HVALS',
      key,
    ]);
  }

  Future<RespType> blpop(List<String> keys, int timeout) async {
    return tier0.execute([
      'BLPOP',
      ...keys,
      timeout,
    ]);
  }

  Future<RespType> brpop(List<String> keys, int timeout) async {
    return tier0.execute([
      'BRPOP',
      ...keys,
      timeout,
    ]);
  }

  Future<RespType> brpoplpush(String source, String destination, int timeout) async {
    return tier0.execute([
      'BRPOPLPUSH',
      source,
      destination,
      timeout,
    ]);
  }

  Future<RespType> lindex(String key, int index) async {
    return tier0.execute([
      'LINDEX',
      key,
      index,
    ]);
  }

  Future<RespType> linsert(String key, InsertMode insertMode, Object pivot, Object value) async {
    return tier0.execute([
      'LINSERT',
      key,
      insertMode._value,
      pivot,
      value,
    ]);
  }

  Future<RespType> llen(String key) async {
    return tier0.execute([
      'LLEN',
      key,
    ]);
  }

  Future<RespType> lpop(String key) async {
    return tier0.execute([
      'LPOP',
      key,
    ]);
  }

  Future<RespType> lpush(String key, List<Object> values) async {
    return tier0.execute([
      'LPUSH',
      key,
      ...values,
    ]);
  }

  Future<RespType> lpushx(String key, List<Object> values) async {
    return tier0.execute([
      'LPUSHX',
      key,
      ...values,
    ]);
  }

  Future<RespType> lrange(String key, int start, int stop) async {
    return tier0.execute([
      'LRANGE',
      key,
      start,
      stop,
    ]);
  }

  Future<RespType> lrem(String key, int count, Object value) async {
    return tier0.execute([
      'LREM',
      key,
      count,
      value,
    ]);
  }

  Future<RespType> lset(String key, int index, Object value) async {
    return tier0.execute([
      'LSET',
      key,
      index,
      value,
    ]);
  }

  Future<RespType> ltrim(String key, int start, int stop) async {
    return tier0.execute([
      'LTRIM',
      key,
      start,
      stop,
    ]);
  }

  Future<RespType> rpop(String key) async {
    return tier0.execute([
      'RPOP',
      key,
    ]);
  }

  Future<RespType> rpoplpush(String source, String destination) async {
    return tier0.execute([
      'RPOPLPUSH',
      source,
      destination,
    ]);
  }

  Future<RespType> rpush(String key, List<Object> values) async {
    return tier0.execute([
      'RPUSH',
      key,
      ...values,
    ]);
  }

  Future<RespType> rpushx(String key, List<Object> values) async {
    return tier0.execute([
      'RPUSHX',
      key,
      ...values,
    ]);
  }

  Future<RespType> incr(String key) async {
    return tier0.execute([
      'INCR',
      key,
    ]);
  }

  Future<RespType> incrby(String key, int increment) async {
    return tier0.execute([
      'INCRBY',
      key,
      '$increment',
    ]);
  }

  Future<RespType> decr(String key) async {
    return tier0.execute([
      'DECR',
      key,
    ]);
  }

  Future<RespType> decrby(String key, int decrement) async {
    return tier0.execute([
      'DECRBY',
      key,
      '$decrement',
    ]);
  }

  Future<RespType> scan(int cursor, {String? pattern, int? count}) async {
    return tier0.execute([
      'SCAN',
      '$cursor',
      if (pattern != null) ...['MATCH', pattern],
      if (count != null) ...['COUNT', count],
    ]);
  }

  Future<RespType> publish(String channel, Object message) async {
    return tier0.execute([
      'PUBLISH',
      channel,
      message,
    ]);
  }

  Future<RespType> subscribe(List<String> channels) async {
    return tier0.execute([
      'SUBSCRIBE',
      ...channels,
    ]);
  }

  Future<RespType> unsubscribe(Iterable<String> channels) async {
    return tier0.execute([
      'UNSUBSCRIBE',
      ...channels,
    ]);
  }

  Future<RespType> multi() async {
    return tier0.execute([
      'MULTI',
    ]);
  }

  Future<RespType> exec() async {
    return tier0.execute([
      'EXEC',
    ]);
  }

  Future<RespType> discard() async {
    return tier0.execute([
      'DISCARD',
    ]);
  }

  Future<RespType> watch(List<String> keys) async {
    return tier0.execute([
      'WATCH',
      ...keys,
    ]);
  }

  Future<RespType> unwatch() async {
    return tier0.execute([
      'UNWATCH',
    ]);
  }
}
