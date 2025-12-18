import 'dart:async';
import 'package:flutter/foundation.dart';

/// Esta clase convierte un Stream (como el de Supabase Auth) en un Listenable
/// que GoRouter puede escuchar para redirigir al usuario en tiempo real.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}