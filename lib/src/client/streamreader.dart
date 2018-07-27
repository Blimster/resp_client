part of resp_client;

class _StreamReader {
  final buffer = Queue<int>();
  final listeners = Queue<StreamController<void>>();

  _StreamReader(Stream<List<int>> stream) {
    stream.listen(onData);
  }

  void onData(List<int> data) {
    buffer.addAll(data);
    if (listeners.isNotEmpty) {
      listeners.first.add(null);
    }
  }

  Future<List<int>> takeCount(int count) {
    final listener = StreamController<int>();
    listeners.add(listener);
    final completer = Completer<List<int>>();

    final buffer = List<int>();
    final subscription = listener.stream.listen(null);

    subscription.onData((_) {
      while (buffer.length < count && this.buffer.isNotEmpty) {
        buffer.add(this.buffer.removeFirst());
      }
      if (buffer.length == count) {
        subscription.cancel();
        listeners.remove(listener);
        completer.complete(buffer);
      }
    });
    listener.add(null);

    return completer.future;
  }

  Future<int> takeOne() async {
    final data = await takeCount(1);
    return data[0];
  }

  Future<List<int>> takeWhile(bool predicate(int)) {
    final listener = StreamController<int>();
    listeners.add(listener);
    final completer = Completer<List<int>>();

    final buffer = List<int>();
    final subscription = listener.stream.listen(null);
    subscription.onData((_) {
      while (this.buffer.isNotEmpty && predicate(this.buffer.first)) {
        buffer.add(this.buffer.removeFirst());
      }
      if (this.buffer.isNotEmpty && !predicate(this.buffer.first)) {
        subscription.cancel();
        listeners.remove(listener);
        completer.complete(buffer);
      }
    });
    listener.add(null);

    return completer.future;
  }
}
