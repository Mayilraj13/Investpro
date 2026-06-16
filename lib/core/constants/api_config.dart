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

  /// Base URL for the InvestPro local proxy server.
  static const String baseUrl = 'http://localhost:5000/api';

  /// Timeout for real-time data requests (seconds).
  static const int apiTimeoutSeconds = 15;

  /// Auto-refresh interval when market is open (seconds).
  static const int refreshIntervalSeconds = 30;
}
