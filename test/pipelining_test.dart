import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:test/test.dart';

import 'test_connection.dart';

void main() {
  late TestConnection connection;
  late RespClient client;
  late RespCommandsTier2 commands;

  setUp(() {
    connection = TestConnection();
    client = RespClient(connection);
    commands = RespCommandsTier2(client);
  });

  tearDown(() {
    connection.close();
  });

  test('all pipelined request complete', () async {
    connection.responseOnRequest(
        RespArray([RespBulkString('SET'), RespBulkString('foo'), RespBulkString('bar')]).serialize(), '+OK\r\n');
    connection.responseOnRequest(
        RespArray([RespBulkString('PEXPIRE'), RespBulkString('foo'), RespBulkString('10000')]).serialize(), ':1\r\n');
    connection.responseOnRequest(
        RespArray([RespBulkString('SET'), RespBulkString('foo'), RespBulkString('bar')]).serialize(), '+OK\r\n');

    await commands.set('foo', 'bar');
    await commands.pexpire('foo', Duration(seconds: 10));
    await commands.set('foo', 'bar');

    connection.assertAllResponsesSent();
  });
}
