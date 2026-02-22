import 'dart:async';

class ExpiringSet<T> {
  final Duration lifetime;
  final Duration checkInterval;
  
  // LinkedHashMap preserves insertion order. 
  // Key = The ID, Value = The time it should expire.
  final Map<T, DateTime> _items = {}; 
  
  Timer? _cleanupTimer;

  ExpiringSet({
    this.lifetime = const Duration(seconds: 5),
    this.checkInterval = const Duration(seconds: 1),
  });

  /// Adds an item. If it already exists, its timer is reset.
  void add(T id) {
    // We remove and re-add to ensure the item moves to the 
    // end of the linked list (keeping the map strictly time-ordered).
    _items.remove(id);
    _items[id] = DateTime.now().add(lifetime);
    
    _startTimerIfNeeded();
  }

  bool contains(T id) => _items.containsKey(id);

  void remove(T id) => _items.remove(id);

  // Cleans up resources when you are done with this set entirely
  void dispose() {
    _cleanupTimer?.cancel();
    _items.clear();
  }

  void _startTimerIfNeeded() {
    // If the timer is already running, do nothing.
    if (_cleanupTimer != null && _cleanupTimer!.isActive) return;

    _cleanupTimer = Timer.periodic(checkInterval, (timer) => _sweep());
  }

  void _sweep() {
    final now = DateTime.now();

    // Iterate until the map is empty or we hit an item that isn't expired yet.
    while (_items.isNotEmpty) {
      // Look at the oldest item (first in the map)
      final oldestId = _items.keys.first;
      final expiryTime = _items[oldestId]!;

      if (now.isAfter(expiryTime)) {
        // It's expired, remove it.
        _items.remove(oldestId);
      } else {
        // Optimization: The oldest item is NOT expired. 
        // Since the map is sorted by time, nothing else is expired either.
        // We can stop working immediately to save CPU.
        break;
      }
    }

    // If the set is empty, stop the timer to save resources.
    if (_items.isEmpty) {
      _cleanupTimer?.cancel();
    }
  }
}
