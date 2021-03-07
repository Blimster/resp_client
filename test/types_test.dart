import 'dart:async';

import 'package:resp_client/resp_client.dart';
import 'package:test/test.dart';

void main() {
  StreamController<List<int>> streamController;
  StreamReader streamReader;

  setUp(() {
    streamController = StreamController();
    streamReader = StreamReader(streamController.stream);
  });

  test('tests (de)serialize of a simple string', () async {
    final simpleString = RespSimpleString('abcØØhehe');
    streamController.add(simpleString.serialize());
    final result = await deserializeRespType(streamReader);
    expect(result.payload, equals('abcØØhehe'));
  });

  test('tests (de)serialize of a bulk string', () async {
    final simpleString = RespBulkString('abcØØhehe');
    streamController.add(simpleString.serialize());
    final result = await deserializeRespType(streamReader);
    expect(result.payload, equals('abcØØhehe'));
  });

  test('tests (de)serialize of an error', () async {
    final simpleString = RespError('abcØØhehe');
    streamController.add(simpleString.serialize());
    final result = await deserializeRespType(streamReader);
    expect(result.payload, equals('abcØØhehe'));
  });

  test('tests (de)serialize of an integer', () async {
    final simpleString = RespInteger(1910);
    streamController.add(simpleString.serialize());
    final result = await deserializeRespType(streamReader);
    expect(result.payload, equals(1910));
  });

  test('tests (de)serialize of an array', () async {
    final simpleString = RespArray([
      RespInteger(1910),
      RespBulkString('bülk'),
      RespSimpleString('simple'),
      RespError('error'),
    ]);
    streamController.add(simpleString.serialize());
    final result = await deserializeRespType(streamReader) as RespArray;
    expect(result.payload, hasLength(4));
    expect(result.payload[0].payload, equals(1910));
    expect(result.payload[1].payload, equals('bülk'));
    expect(result.payload[2].payload, equals('simple'));
    expect(result.payload[3].payload, equals('error'));
  });
}
