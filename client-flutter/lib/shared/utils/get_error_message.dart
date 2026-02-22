import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String getErrorMessage(Object error) {
  return switch (error) {
    // Explicitly use 'String msg' (not 'var') to force non-nullable matching
    PlatformException(message: String msg) ||
    SocketException(message: String msg) ||
    HttpException(message: String msg) ||
    FormatException(message: String msg) ||
    TimeoutException(message: String msg) ||
    AuthException(message: String msg) ||
    PostgrestException(message: String msg) ||
    StorageException(message: String msg)
        // We still check isNotEmpty, but we don't need to check != null anymore
        when msg.isNotEmpty =>
      msg,

    // Handle plain strings
    String msg => msg,

    // Default fallback
    _ => error.toString(),
  };
}
