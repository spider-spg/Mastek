class OfflineQueue {
  final List<Map<String, dynamic>> _pending = <Map<String, dynamic>>[];

  void enqueue(Map<String, dynamic> payload) {
    _pending.add(payload);
  }

  List<Map<String, dynamic>> drain() {
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();
    return items;
  }
}