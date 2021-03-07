part of resp_client;

final String suffix = '\r\n';

///
/// Base class for all RESP types.
///
abstract class RespType<P> {
  final String prefix;
  final P payload;

  const RespType(this.prefix, this.payload);

  List<int> serialize() {
    return utf8.encode('$prefix$payload$suffix');
  }

  @override
  String toString() {
    return utf8.decode(serialize());
  }
}

///
/// Implementation of a RESP simple string.
///
class RespSimpleString extends RespType<String> {
  const RespSimpleString(String payload) : super('+', payload);
}

///
/// Implementation of a RESP error.
///
class RespError extends RespType<String> {
  const RespError(String payload) : super('-', payload);
}

///
/// Implementation of a RESP integer.
///
class RespInteger extends RespType<int> {
  const RespInteger(int payload) : super(':', payload);
}

///
/// Implementation of a RESP bulk string.
///
class RespBulkString extends RespType<String> {
  static final nullString = utf8.encode('\$-1$suffix');

  const RespBulkString(String payload) : super('\$', payload);

  @override
  List<int> serialize() {
    if (payload != null) {
      final length = utf8.encode(payload).length;
      return utf8.encode('$prefix${length}$suffix$payload$suffix');
    }
    return nullString;
  }
}

///
/// Implementation of a RESP array.
///
class RespArray extends RespType<List<RespType>> {
  static final nullArray = utf8.encode('\*-1$suffix');

  const RespArray(List<RespType> payload) : super('*', payload);

  @override
  List<int> serialize() {
    if (payload != null) {
      return [
        ...utf8.encode('$prefix${payload.length}$suffix'),
        ...payload.expand((element) => element.serialize()),
        ...utf8.encode('$suffix'),
      ];
    }
    return nullArray;
  }
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
