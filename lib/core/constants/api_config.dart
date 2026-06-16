import 'dart:io' show Platform;

/// API configuration for InvestPro.
///
/// The app uses a local Python proxy server (server/realtime_server.py)
/// that wraps yfinance for reliable real-time Indian market data.
///
/// To start the proxy:
///   cd server && python realtime_server.py
///   # -> API available at http://localhost:5000
///
/// When the proxy is unreachable, the app gracefully shows a
/// stale-data warning banner and keeps the last known data.
class ApiConfig {
  ApiConfig._();

  /// Override host for the proxy server.
  ///
  /// Set this before accessing [baseUrl] to use a custom IP/host.
  /// Useful for physical Android devices on the same network.
  ///
  /// Example: ApiConfig.baseHostOverride = '192.168.1.100';
  static String? baseHostOverride;

  /// The host address for the local proxy server.
  ///
  /// Detection order:
  ///   1. [baseHostOverride] (user-set, e.g. host machine's LAN IP)
  ///   2. `10.0.2.2` when running on Android emulator
  ///   3. `localhost` for desktop/iOS simulator/web
  static String get _host {
    if (baseHostOverride != null) return baseHostOverride!;
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return 'localhost';
  }

  /// Base URL for the InvestPro local proxy server.
  static String get baseUrl => 'http://$_host:5000/api';

  /// Timeout for real-time data requests (seconds).
  static const int apiTimeoutSeconds = 15;

  /// Auto-refresh interval when market is open (seconds).
  static const int refreshIntervalSeconds = 30;
}
