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

  await commands.flushAll();

  server.close();
}
