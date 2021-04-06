import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart';

void main(List<String> args) async {
  // create a server connection using sockets
  final server = await connectSocket('localhost');

  // create a client using the server connection
  final client = RespClient(server);

  final commands = RespCommandsTier0(client);

  // execute a command
  final result = await commands.execute(['GET', 'myKey', 'NX']);
  print(result.payload);

  // close connection to the server
  await server.close();
}
