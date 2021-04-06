# resp_client
A RESP (REdis Serialization Protocol) client for Dart. This package contains 3 libraries. `resp_server` implements the connectionn to the server, `resp_client` implements the Redis serialization protocol. `resp_commands` provides implementations of Redis commands in differents levels of convenient from low-level to easy-to-use.

# 3 Building blocks

There 3 fundamental building block:
* **RespServerConnection** - A connection to a RESP server
* **RespClient** - A RESP client connected to a RESP server implementing the request/response model and the RESP types
* **RespCommandsTierN** - Implementation of Redis commands

# Usage

## Initialization and cleanup

```dart

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

  // execute some commands...

  // close connection to the server
  await server.close();
}

```

## Use commands

Not all Redis commands are implemented in all tiers yet. Nevertheless, it is possible to execute very Redis command using tier 0. You can create a command object of every tier using a `RespClient`. It is allowed to create multiple command objects on the same client. Command objects of tier 1 and 2 provides a getter to the underlying tier.

## Tier 0

This is the most basic and flexible tier. You can execute every Redis command using this tier. You have to provide a list of elements. All elements are converted to bulk strings using `toString()`. The result is a `RespType`. It is up to the user to convert the result to a concrete RESP type.

```dart

import 'package:resp_client/resp_server.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {

  // ... setup connection and client
  
  // create commands using the client
  final commands = RespCommandsTier0(client);

  // execute a command
  final result = await commands.execute(['SET', 'myKey', 'myValue', 'NX']);
  print(result.payload);

  // ... close connection
}

```

## Tier 1

Commands of tier 1 provide some convenient on the parameter side. The user no longer has to build the commands from ground up. Instead, the commands are calle in a more Dart-like style. The results is always a `RespType` like in tier 0.

```dart

import 'package:resp_client/resp_server.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

void main(List<String> args) async {

  // ... setup connection and client
  
  // create commands using the client
  final commands = RespCommandsTier1(client);

  // Execute the GET command. You don't have to build the command from ground up.
  // The result is a RespType. This is flexible but you have to convert to the
  // concrete type yourself.
  final result = await commands.get('mKey', 'myValue', mode: SetMode.onlyIfNotExists);
  print(result.toBulkString().payload);

  // ... close connection
}

```

## Tier 2

Commands of tier 2 provide the same convenience on the parameter side as tier 1 commands. Additionally. The result of a command is converted for easy handling.

To convert the result, assumptions are made. As an example get GET command returns a bulk string. Thus, the implementation tries to convert the result from a RespType to a RespBulkString and then return the payload of type String?. But, if a GET command is executed as part of a transaction, the result is a RespSimpleString and the payload has different meaning. 

```dart

void main(List<String> args) async {

  // ... setup connection and client
  
  // create commands using the client
  final commands = RespCommandsTier2(client);

  // Like tier 1 commands but the result is already convert.
  // In this case, result is of type String?.
  final result = await commands.get('mKey', 'myValue', mode: SetMode.onlyIfNotExists);
  print(result)

  // ... close connection
}

```

