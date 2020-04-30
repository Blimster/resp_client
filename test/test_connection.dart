import 'dart:async';
import 'dart:convert';

import 'package:resp_client/resp_client.dart';

class TestConnection implements RespServerConnection {
  final StreamController<List<int>> _in = StreamController<List<int>>();
  final StreamController<List<int>> _out = StreamController<List<int>>();
  String _buffer = '';
  final _expectations = <_RequestResponse>[];

  TestConnection() {
    _in.stream.listen((List<int> data) {
      final decoded = utf8.decode(data);
      _buffer = _buffer + decoded;
      if (_expectations.isNotEmpty) {
        if (_expectations.first.response is String) {
          if (_buffer.startsWith(_expectations.first.request)) {
            _buffer = _buffer.substring(_expectations.first.request.length);
            _out.add(utf8.encode(_expectations.first.response as String));
          }
        } else {
          _out.addError(_expectations.first.response);
        }
        _expectations.removeAt(0);
      }
    });
  }

  @override
  Stream<List<int>> get inputStream => _out.stream;

  @override
  StreamSink<List<int>> get outputSink => _in.sink;

  @override
  Future<void> close() {
    _in.close();
    _out.close();
    return Future.value(null);
  }

  void responseOnRequest(String request, Object response) {
    _expectations.add(_RequestResponse(request, response));
  }

  void assertAllResponsesSent() {
    if (_expectations.isNotEmpty) {
      throw AssertionError('expected no more pending responses, but found ${_expectations.length}!');
    }
  }
}

class _RequestResponse {
  final String request;
  final Object response;

  _RequestResponse(this.request, this.response);
}
