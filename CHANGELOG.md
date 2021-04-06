# Changelog

## 1.2.0

- BREAKING CHANGE: C'tor of `RespType` is no longer public.
- BREAKING CHANGE: Class `RespCommands` is removed. Use `RespCommandsTier2` instead.
- BREAKING CHANGE: Return type of `RespCommandsTier0.set()` is now `SetResult` instead of `bool`.
- BREAKING CHANGE: Moved function `connectSocket` and interface `RespServerConnection` to library `resp_server`;
- BREAKING CHANGE: Removed `RespClient.writeArrayOfBulk()`, Use `RespCommandsTier0.execute()` instead.
- Added some convenient methods of `RespType`.
- Added `multi`, `exec`, `discard`, `watch` and `unwatch` commands.

## 1.1.1

- Added `dbsize` and `info` commands.
- Fixed UTF-8 decoding issue.
- Fixed issue in command `scan` when using a pattern.
- Add getters for `cursor` and `keys` to class `ScanResult`.

## 1.1.0

- Added `incr`, `incrby`, `decr`, `decrby` commands.
- BREAKING CHANGE: responses from redis are now considered as UTF-8 encoded (`resp_client` already encodes commands as UTF-8). 

## 1.0.0

- Stable null safety release.

## 1.0.0-nullsafety.0

- BREAKING CHANGE: migrated to null safety
- Added pedantic linter rules
- Enabled strict type checks

## 0.1.7+1

- Improved pub.dev score

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
