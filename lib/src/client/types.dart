part of resp_client;

final String suffix = '\r\n';

///
/// Base class for all RESP types.
///
abstract class RespType<P> {
  final String prefix;
  final P? _payload;

  const RespType(this.prefix, this._payload);

  P get payload => _payload as P;

  String serialize() {
    return '$prefix$payload$suffix';
  }

  @override
  String toString() {
    return serialize();
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
class RespBulkString extends RespType<String?> {
  static final nullString = '\$-1' + suffix;

  const RespBulkString(String? payload) : super('\$', payload);

  @override
  String serialize() {
    final pl = payload;
    if (pl != null) {
      return '$prefix${pl.length}$suffix$pl$suffix';
    }
    return nullString;
  }
}

///
/// Implementation of a RESP array.
///
class RespArray extends RespType<List<RespType>?> {
  static final nullArray = '\*-1' + suffix;

  const RespArray(List<RespType>? payload) : super('*', payload);

  @override
  String serialize() {
    final pl = payload;
    if (pl != null) {
      return '$prefix${pl.length}$suffix${pl.map((e) => e.serialize()).join('')}$suffix';
    }
    return nullArray;
  }
}

Future<RespType> _deserializeRespType(_StreamReader _streamReader) async {
  final typePrefix = await _streamReader.takeOne();
  switch (typePrefix) {
    case 0x2b: // simple string
      final payload = String.fromCharCodes(await _streamReader.takeWhile((data) => data != 0x0d));
      await _streamReader.takeCount(2);
      return RespSimpleString(payload);
    case 0x2d: // error
      final payload = String.fromCharCodes(await _streamReader.takeWhile((data) => data != 0x0d));
      await _streamReader.takeCount(2);
      return RespError(payload);
    case 0x3a: // integer
      final payload = int.parse(String.fromCharCodes(await _streamReader.takeWhile((data) => data != 0x0d)));
      await _streamReader.takeCount(2);
      return RespInteger(payload);
    case 0x24: // bulk string
      final length = int.parse(String.fromCharCodes(await _streamReader.takeWhile((data) => data != 0x0d)));
      await _streamReader.takeCount(2);
      if (length == -1) {
        return RespBulkString(null);
      }
      final payload = String.fromCharCodes(await _streamReader.takeCount(length));
      await _streamReader.takeCount(2);
      return RespBulkString(payload);
    case 0x2a: // array
      final count = int.parse(String.fromCharCodes(await _streamReader.takeWhile((data) => data != 0x0d)));
      await _streamReader.takeCount(2);
      if (count == -1) {
        return RespArray(null);
      }
      final elements = <RespType>[];
      for (var i = 0; i < count; i++) {
        elements.add(await _deserializeRespType(_streamReader));
      }
      return RespArray(elements);
    default:
      throw StateError('unexpected character: $typePrefix');
  }
}
