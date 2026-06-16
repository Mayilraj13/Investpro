# InvestPro Real-Time Data Fix

## What Changed

The app previously used direct Yahoo Finance API calls from the Flutter client,
which were unreliable due to browser/CORS restrictions. It silently fell back
to hardcoded mock data — the same prices every time.

Now the app uses a **local Python proxy server** that fetches real market data
via the `yfinance` library (server-side, no CORS issues).

## Quick Start

**Terminal 1 — Data Server (keep running):**
```bash
cd server
python realtime_server.py
# → http://localhost:5000
```

**Terminal 2 — Flutter App:**
```bash
flutter run
```

The Flutter app auto-connects to the server. If the server is not running,
the app shows a orange "using cached data" banner but still works with
the last known data.

## Real-Time Data Flow

```
yfinance (Yahoo Finance API)
    ↓  (server-side, no CORS)
Python Proxy (localhost:5000)
    ↓  (REST JSON over HTTP)
Flutter App (InvestPro)

ApiConfig.provider = 'investpro'
```

## API Endpoints (Python Proxy)

| Endpoint | Description |
|---|---|
| `GET /api/health` | Health check |
| `GET /api/quote/{symbol}` | Stock quote (e.g., RELIANCE, SBIN) |
| `POST /api/quotes` | Multiple quotes (batch) |
| `GET /api/history/{symbol}?period=1mo` | OHLCV chart data |
| `GET /api/search?q=keyword` | Search stocks |
| `GET /api/news` | Market news |
| `GET /api/market-overview` | Nifty 50, Sensex, Bank Nifty |
| `GET /api/default-quotes` | 15 major Indian stocks (batch) |

## What's Fixed

1. **Mock Data → Real-Time Prices**: All 15 default stocks now show live
   prices, changes, and fundamentals from real market data.

2. **Hardcoded Indices → Live**: The SENSEX and BANK NIFTY cards on the
   dashboard now show real values from Yahoo Finance instead of hardcoded
   strings.

3. **Chart Data**: Historical OHLCV data loads from the proxy (1D to 5Y).

4. **Stale Data Indicator**: When the proxy is unreachable, an orange
   banner appears: "Using cached data — real-time server not connected."

5. **Auto-Refresh**: Data refreshes every 30 seconds automatically.

## Files Changed

| File | What |
|---|---|
| `server/realtime_server.py` | **NEW** — Python FastAPI proxy server |
| `lib/core/constants/api_config.dart` | Updated — added 'investpro' provider, localhost:5000 |
| `lib/services/api_service.dart` | Rewritten — simplified with proxy endpoints |
| `lib/data/models/market_models.dart` | Updated — added sensexValue, bankNiftyValue fields |
| `lib/providers/app_providers.dart` | Rewritten — clean data flow with stale detection |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Updated — live SENSEX, BANK NIFTY, stale indicator |

## Requirements

- Python 3.9+
- `pip install fastapi uvicorn yfinance`
- Flutter SDK
- Network connection (for yfinance to fetch data)
