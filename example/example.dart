import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {
  // create a RESP server connection using sockets
  final RespServerConnection server = await connectSocket('localhost');

  // create a RESP client using the server connection
  RespClient client = RespClient(server);

  // create RESP commands using the client
  RespCommands commands = RespCommands(client);

  final clientList = await commands.clientList();
  print(clientList);

  await commands.select(1);

  final set = await commands.set('test', 'foobar', expire: Duration(seconds: 10));
  print(set);

  final exists = await commands.exists(['test']);
  print(exists);

  final ttl = await commands.ttl('test');
  print(ttl);

  final get = await commands.get('test');
  print(get);

  final del = await commands.del(['test']);
  print(del);

  print('--- hash operations ---');

  final hset1 = await commands.hset('hsh', 'f1', 'foo');
  print(hset1);

  final hset2 = await commands.hset('hsh', 'f2', 'bar');
  print(hset2);

  final hsetnx1 = await commands.hsetnx('hsh', 'f3', 'baz');
  print(hsetnx1);

  final hsetnx2 = await commands.hsetnx('hsh', 'f3', 'baz');
  print(hsetnx2);

  final hmset = await commands.hmset('hsh', { 'f4': 'v1', 'f5': 'v2' });
  print(hmset);

  final hexists = await commands.hexists('hsh', 'f1');
  print(hexists);

  print(await commands.hget('hsh', 'f2'));

  print(await commands.hmget('hsh', ['f1', 'f2']));

  print(await commands.hgetall('hsh'));

  print(await commands.hkeys('hsh'));

  print(await commands.hvals('hsh'));

  print(await commands.hdel('hsh', ['f1', 'f3']));

  print(await commands.hgetall('hsh'));


  await commands.flushAll();

  server.close();
}
