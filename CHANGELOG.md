# Changelog

## 0.2.0

- Added pedantic linter rules
- Enabled strict type checks
- Added `incr`, `incrby`, `decr`, `decrby` commands.
- BREAKING CHANGE: responses from redis are now considered as UTF-8 encoded (`resp_client` already encodes commands as UTF-8).

## 0.1.7+1

- Improved pub.dev score˚

## 0.1.7

- Added SCAN command

## 0.1.6

- Bugfix: RespClient hangs when pipelining commands

## 0.1.5

- Added list commands (LPUSH, LPOP, etc.)

## 0.1.4

- Added hash commands (HSET, HGET, etc.)

## 0.1.3

- Added AUTH command

## 0.1.2

- Bugfix: Fixed handling of null bulk strings and arrays in deserialization.
- Added SELECT, FLUSHDB and FLUSHALL commands.
- Cleaned up dependencies.
- Changed Dart SDK constraint to Dart 2 stable. 

## 0.1.1

- Added PEXPIRE command. 

## 0.1.0

- Initial version
