import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:resp_client/resp_client.dart';

class TestConnection implements RespServerConnection {
  final StreamController<List<int>> _in = StreamController<List<int>>();
  final StreamController<List<int>> _out = StreamController<List<int>>();
  List<int> _buffer = [];
  final _expectations = <_RequestResponse>[];

  TestConnection() {
    _in.stream.listen((List<int> data) {
      _buffer.addAll(data);
      if (_expectations.isNotEmpty) {
        if (_expectations.first.response is String) {
          if (ListEquality<int>()
              .equals(_buffer.sublist(0, _expectations.first.request.length), _expectations.first.request)) {
            _buffer = _buffer.sublist(_expectations.first.request.length);
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

  void responseOnRequest(List<int> request, Object response) {
    _expectations.add(_RequestResponse(request, response));
  }

  void assertAllResponsesSent() {
    if (_expectations.isNotEmpty) {
      throw AssertionError('expected no more pending responses, but found ${_expectations.length}!');
    }
  }
}

class _RequestResponse {
  final List<int> request;
  final Object response;

  _RequestResponse(this.request, this.response);
}
