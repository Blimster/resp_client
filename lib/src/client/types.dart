part of resp_client;

const String suffix = '\r\n';

///
/// Base class for all RESP types.
///
abstract class RespType<P> {
  final String prefix;
  final P payload;

  const RespType._(this.prefix, this.payload);

  ///
  /// Serializes this type to RESP.
  ///
  List<int> serialize() {
    return utf8.encode('$prefix$payload$suffix');
  }

  @override
  String toString() {
    return utf8.decode(serialize());
  }

  ///
  /// The name of the concrete type.
  ///
  String get typeName;

  ///
  /// Calls one of the given handlers based on the
  /// concrete type. Returns [true] if a handler for
  /// the concrete type was provided, otherwise [false]
  /// is returned. If the handler throws an error while
  /// executing, the error is raised to the caller of
  /// this method.
  ///
  T handleAs<T>({
    T Function(RespSimpleString)? simple,
    T Function(RespBulkString)? bulk,
    T Function(RespInteger)? integer,
    T Function(RespArray)? array,
    T Function(RespError)? error,
  }) {
    if (isSimpleString && simple != null) {
      return simple(toSimpleString());
    } else if (isBulkString && bulk != null) {
      return bulk(toBulkString());
    } else if (isInteger && integer != null) {
      return integer(toInteger());
    } else if (isArray && array != null) {
      return array(toArray());
    } else if (isError && error != null) {
      return error(toError());
    }
    throw ArgumentError('No handler provided for type $typeName!');
  }

  ///
  /// Converts this type to a simple string. Throws a
  /// [StateError] if this is not a simple string.
  ///
  RespSimpleString toSimpleString() => throw StateError('${toString()} is not a simple string!');

  ///
  /// Converts this type to a bulk string. Throws a
  /// [StateError] if this is not a bulk string.
  ///
  RespBulkString toBulkString() => throw StateError('${toString()} is not a bulk string!');

  ///
  /// Converts this type to an integer. Throws a
  /// [StateError] if this is not an integer.
  ///
  RespInteger toInteger() => throw StateError('${toString()} is not an integer!');

  ///
  /// Converts this type to an array. Throws a
  /// [StateError] if this is not an array.
  ///
  RespArray toArray() => throw StateError('${toString()} is not an array!');

  ///
  /// Converts this type to an error. Throws a
  /// [StateError] if this is not an error.
  ///
  RespError toError() => throw StateError('${toString()} is not an error!');

  ///
  /// Return [true] if this type is a simple string.
  ///
  bool get isSimpleString => false;

  ///
  /// Return [true] if this type is a bulk string.
  ///
  bool get isBulkString => false;

  ///
  /// Return [true] if this type is an integer.
  ///
  bool get isInteger => false;

  ///
  /// Return [true] if this type is an array.
  ///
  bool get isArray => false;

  ///
  /// Return [true] if this type is an error.
  ///
  bool get isError => false;
}

///
/// Implementation of a RESP simple string.
///
class RespSimpleString extends RespType<String> {
  const RespSimpleString(String payload) : super._('+', payload);

  @override
  RespSimpleString toSimpleString() => this;

  @override
  bool get isSimpleString => true;

  @override
  String get typeName => 'simple string';
}

///
/// Implementation of a RESP bulk string.
///
class RespBulkString extends RespType<String?> {
  static final nullString = utf8.encode('\$-1$suffix');

  const RespBulkString(String? payload) : super._('\$', payload);

  @override
  List<int> serialize() {
    final pl = payload;
    if (pl != null) {
      final length = utf8.encode(pl).length;
      return utf8.encode('$prefix${length}$suffix$pl$suffix');
    }
    return nullString;
  }

  @override
  RespBulkString toBulkString() => this;

  @override
  bool get isBulkString => true;

  @override
  String get typeName => 'bulk string';
}

///
/// Implementation of a RESP integer.
///
class RespInteger extends RespType<int> {
  const RespInteger(int payload) : super._(':', payload);

  @override
  RespInteger toInteger() => this;

  @override
  bool get isInteger => true;

  @override
  String get typeName => 'integer';
}

///
/// Implementation of a RESP array.
///
class RespArray extends RespType<List<RespType>?> {
  static final nullArray = utf8.encode('\*-1$suffix');

  const RespArray(List<RespType>? payload) : super._('*', payload);

  @override
  List<int> serialize() {
    final pl = payload;
    if (pl != null) {
      return [
        ...utf8.encode('$prefix${pl.length}$suffix'),
        ...pl.expand((element) => element.serialize()),
        ...utf8.encode('$suffix'),
      ];
    }
    return nullArray;
  }

  @override
  RespArray toArray() => this;

  @override
  bool get isArray => true;

  @override
  String get typeName => 'array';
}

///
/// Implementation of a RESP error.
///
class RespError extends RespType<String> {
  const RespError(String payload) : super._('-', payload);

  @override
  RespError toError() => this;

  @override
  bool get isError => true;

  @override
  String get typeName => 'error';
}

Future<RespType> deserializeRespType(StreamReader streamReader) async {
  final typePrefix = await streamReader.takeOne();
  switch (typePrefix) {
    case 0x2b: // simple string
      final payload = utf8.decode(await streamReader.takeWhile((data) => data != 0x0d));
      await streamReader.takeCount(2);
      return RespSimpleString(payload);
    case 0x2d: // error
      final payload = utf8.decode(await streamReader.takeWhile((data) => data != 0x0d));
      await streamReader.takeCount(2);
      return RespError(payload);
    case 0x3a: // integer
      final payload = int.parse(utf8.decode(await streamReader.takeWhile((data) => data != 0x0d)));
      await streamReader.takeCount(2);
      return RespInteger(payload);
    case 0x24: // bulk string
      final length = int.parse(utf8.decode(await streamReader.takeWhile((data) => data != 0x0d)));
      await streamReader.takeCount(2);
      if (length == -1) {
        return RespBulkString(null);
      }
      final payload = utf8.decode(await streamReader.takeCount(length));
      await streamReader.takeCount(2);
      return RespBulkString(payload);
    case 0x2a: // array
      final count = int.parse(utf8.decode(await streamReader.takeWhile((data) => data != 0x0d)));
      await streamReader.takeCount(2);
      if (count == -1) {
        return RespArray(null);
      }
      final elements = <RespType>[];
      for (var i = 0; i < count; i++) {
        elements.add(await deserializeRespType(streamReader));
      }
      return RespArray(elements);
    default:
      throw StateError('unexpected character: $typePrefix');
  }
}
