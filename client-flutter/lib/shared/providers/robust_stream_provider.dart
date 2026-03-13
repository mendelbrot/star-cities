import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';

typedef ModelFactory<T> = T Function(Map<String, dynamic> map);

/// A generic notifier that implements a robust "REST -> Subscribe -> REST" fetching strategy.
/// This ensures immediate data availability, real-time updates, and eventual consistency
/// even during websocket connection fluctuations.
abstract class RobustSupabaseNotifier<T, ID> extends AutoDisposeFamilyAsyncNotifier<List<T>, String> {
  String get tableName;
  ModelFactory<T> get factory;
  String get primaryKey => 'id';

  /// Optional: override to provide custom filtering for REST queries.
  PostgrestTransformBuilder<PostgrestList> filter(PostgrestFilterBuilder<PostgrestList> query, String arg) {
    return query;
  }

  /// Optional: override to provide custom filtering for Realtime subscriptions.
  PostgresChangeFilter? getRealtimeFilter(String arg) => null;

  RealtimeChannel? _channel;
  bool _isDisposed = false;

  @override
  Future<List<T>> build(String arg) async {
    ref.onDispose(() {
      _isDisposed = true;
      _channel?.unsubscribe();
    });

    // 1. Initial REST Fetch
    final initialData = await _fetch(arg);
    
    // 2. Subscribe to changes
    _subscribe(arg);

    // 3. Secondary REST Sync (delayed slightly to ensure subscription is active)
    _sync(arg);

    return postProcess(initialData);
  }

  Future<List<T>> _fetch(String arg) async {
    final supabase = ref.read(supabaseClientProvider);
    final baseQuery = supabase.from(tableName).select();
    final query = filter(baseQuery, arg);
    
    final List<dynamic> data = await query;
    return data.map((m) => factory(m as Map<String, dynamic>)).toList();
  }

  void _subscribe(String arg) async {
    if (_isDisposed) return;
    final supabase = ref.read(supabaseClientProvider);
    final channelName = 'robust_${tableName}_$arg';
    
    try {
      // Cleanup old channel if it exists and wait for it
      if (_channel != null) {
        await _channel!.unsubscribe();
      }

      if (_isDisposed) return;

      _channel = supabase.channel(channelName);
      
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tableName,
        filter: getRealtimeFilter(arg),
        callback: (payload) {
          if (_isDisposed) return;
          _handleRealtimeEvent(payload);
        },
      ).subscribe((status, [error]) {
        if (_isDisposed) return;
        
        if (status == RealtimeSubscribeStatus.timedOut || 
            status == RealtimeSubscribeStatus.channelError ||
            error != null) {
          // If timed out, error, or exception, wait a bit and retry the whole cycle
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isDisposed) {
              _retryCycle(arg);
            }
          });
        }
      });
    } catch (e) {
      // If subscription itself throws (e.g. RealtimeSubscribeException), retry later
      if (!_isDisposed) {
        Future.delayed(const Duration(seconds: 10), () => _retryCycle(arg));
      }
    }
  }

  Future<void> _retryCycle(String arg) async {
    if (_isDisposed) return;
    
    try {
      // 1. Fetch fresh data via REST
      final data = await _fetch(arg);
      if (_isDisposed) return;
      state = AsyncValue.data(postProcess(data));

      // 2. Re-subscribe
      _subscribe(arg);

      // 3. Sync again just to be sure
      _sync(arg);
    } catch (e) {
      // If retry fails, wait and try again
      Future.delayed(const Duration(seconds: 10), () => _retryCycle(arg));
    }
  }

  Future<void> _sync(String arg) async {
    // Wait a short moment to allow the subscription to establish
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDisposed) return;

    try {
      final syncData = await _fetch(arg);
      if (_isDisposed) return;

      // Merge sync data into current state
      state = AsyncValue.data(postProcess(_merge(state.value ?? [], syncData)));
    } catch (e) {
      // If sync fails, we don't want to crash, just log or ignore as we have initial data and subscription
    }
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    final currentState = state.value ?? [];
    List<T> newState = List.from(currentState);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final newItem = factory(payload.newRecord);
        final id = getId(newItem);
        // Avoid duplicates if already present from a sync
        if (!newState.any((item) => getId(item) == id)) {
          newState.add(newItem);
        }
        break;
      case PostgresChangeEvent.update:
        final updatedItem = factory(payload.newRecord);
        final id = getId(updatedItem);
        final index = newState.indexWhere((item) => getId(item) == id);
        if (index != -1) {
          newState[index] = updatedItem;
        } else {
          newState.add(updatedItem);
        }
        break;
      case PostgresChangeEvent.delete:
        newState.removeWhere((item) => _getIdFromRecord(item, payload.oldRecord));
        break;
      default:
        break;
    }

    state = AsyncValue.data(postProcess(newState));
  }

  /// Helper to check if an item matches a record ID during deletion.
  bool _getIdFromRecord(T item, Map<String, dynamic> record) {
    // This is a bit tricky since getId is on the model. 
    // If primaryKey is 'id', we compare that.
    if (primaryKey == 'id' && record.containsKey('id')) {
      // We assume ID is the type of the 'id' field
      return getId(item).toString() == record['id'].toString();
    }
    return false;
  }

  List<T> _merge(List<T> current, List<T> incoming) {
    final Map<ID, T> map = {for (var item in current) getId(item): item};
    for (var item in incoming) {
      map[getId(item)] = item;
    }
    return map.values.toList();
  }

  /// Optional: override to provide custom post-processing (sorting, limiting).
  List<T> postProcess(List<T> data) => data;

  /// Must be implemented to extract the ID from a model instance.
  ID getId(T item);
}
