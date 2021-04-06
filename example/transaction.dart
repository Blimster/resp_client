import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart';

void main(List<String> args) async {
  // create a server connection using sockets
  final server = await connectSocket('localhost');

  // create a client using the server connection
  final client = RespClient(server);

  // create commands of tier 2 using the client
  final commands = RespCommandsTier2(client);

  // start the transaction
  await commands.multi();

  // execute commands on tier 1 because in transaction mode
  // the commands always return a simple string 'QUEUED',
  // but the tier 2 set command tries to convert the result
  // to a bulk string (the behaviour in 'normal' mode).
  print(await commands.tier1.set('foo', 'bar'));
  print(await commands.tier1.get('foo'));

  // execute all queued commands
  final result = await commands.exec();
  result.payload?.forEach((e) => print(e.payload));

  // close connection to the server
  await server.close();
}
