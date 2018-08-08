# resp_client
A RESP (REdis Serialization Protocol) client for Dart. This package contains 2 libraries. ```resp_client``` implements the Redis serialization protocol. ```resp_commands``` provides an easy to use API for Redis commands.

# 3 Building blocks

There 3 fundamental building block:
* ```RespServerConnection``` - A connection to a RESP server
* ```RespClient``` - A RESP client connected to a RESP server implementing the request/response model and the RESP types
* ```RespCommands``` - Easy to use API of the Redis commands

# Usage

## Initialization

```dart

import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {
  // create a RESP server connection using sockets
  final RespServerConnection server = await connectSocket('localhost');

  // create a RESP client using the server connection
  RespClient client = RespClient(server);

  // create RESP commands using the client
  RespCommands commands = RespCommands(client);

  // ... execute Redis commands

  // close the server connection
  server.close();
}

```

## Use commands

If the command needed is already implemented, just use the `RespCommands` class.

```dart

import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {

  // ... setup connection and client
  
  // create RESP commands using the client
  RespCommands commands = RespCommands(client);

  // execute a command
  final String value = await commands.get('someKey');

  // ... close connection
}

```

## Use low-level API

If the command needed is not implemented, use the low-level API (or create an issue or pull request on GitHub).

```dart

import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {

  // ... setup connection and client
  
  // execute a command
  final RespType result = await client.writeType(RespArray([RespBulkString('GET'), RespBulkString('someKey')]));

  // ... close connection
}

```


