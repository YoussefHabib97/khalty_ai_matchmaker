import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies listeners whenever [stream] emits, so `GoRouter` re-checks its
/// redirect when the session changes.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
