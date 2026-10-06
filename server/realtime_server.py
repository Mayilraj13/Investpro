"""
InvestPro Real-Time Data Proxy Server
======================================
Runs alongside the Flutter app to provide live stock market data.

Primary source: yfinance (wraps Yahoo Finance server-side)
News fallback: Financial RSS feeds (Moneycontrol, Economic Times)
Indices: ^NSEI, ^BSESN, ^NSEBANK via yfinance

Usage:
  uv run python realtime_server.py
  # → Runs on http://localhost:5000
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
import uvicorn
import yfinance as yf
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s %(message)s",
)
logger = logging.getLogger("investpro-server")

# ─── FastAPI App ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="InvestPro Real-Time Data Proxy",
    version="2.0.0",
    description="Real-time Indian stock market data proxy for InvestPro Flutter app",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── In-memory cache ───────────────────────────────────────────────────────────

_cache: dict = {}
_cache_ttl: dict = {}
_cache_stats = {"hits": 0, "misses": 0}


def _cache_get(key: str):
    if key in _cache and key in _cache_ttl:
        if time.time() < _cache_ttl[key]:
            _cache_stats["hits"] += 1
            return _cache[key]
    _cache_stats["misses"] += 1
    return None


def _cache_set(key: str, value, ttl_seconds: int = 30):
    _cache[key] = value
    _cache_ttl[key] = time.time() + ttl_seconds


# ─── Constants ─────────────────────────────────────────────────────────────────

NSE_SYMBOLS = {
    "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK", "SBIN",
    "BHARTIARTL", "HINDUNILVR", "BAJFINANCE", "WIPRO", "ITC",
    "ASIANPAINT", "HCLTECH", "MARUTI", "TATAMOTORS", "NTPC",
    "KOTAKBANK", "LT", "SUNPHARMA", "ONGC", "POWERGRID",
    "TITAN", "ULTRACEMCO", "AXISBANK", "BAJAJFINSV", "ADANIENT",
    "NESTLEIND", "M&M", "TATACONSUM", "BRITANNIA", "DIVISLAB",
    "DRREDDY", "COALINDIA", "HEROMOTOCO", "BPCL", "EICHERMOT",
    "HINDALCO", "TATASTEEL", "JSWSTEEL", "GRASIM", "ADANIPORTS",
    "INDUSINDBK", "CIPLA", "TECHM", "APOLLOHOSP", "BEL",
    "HDFCLIFE", "SBILIFE", "TRENT", "BAJAJ-AUTO", "ICICIPRULI",
    "BANDHANBNK", "DMART", "PIDILITIND", "COLPAL", "HAVELLS",
    "ICICIGI", "SBICARD", "MUTHOOTFIN", "DLF", "ZOMATO",
    "PAYTM", "IRCTC", "IEX", "NYT", "VEDL",
}

DEFAULT_SYMBOLS = [
    "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK",
    "SBIN", "BHARTIARTL", "HINDUNILVR", "BAJFINANCE",
    "WIPRO", "ITC", "ASIANPAINT", "HCLTECH", "MARUTI", "TATAMOTORS",
]

BATCH_SIZE = 5  # yfinance parallel fetch batch
BATCH_DELAY = 0.5  # seconds between batches

INDICES_TICKERS = {
    "NIFTY 50": "^NSEI",
    "SENSEX": "^BSESN",
    "BANK NIFTY": "^NSEBANK",
}

# ─── NSE Ticker Helpers ────────────────────────────────────────────────────────


def _nse_ticker(symbol: str) -> str:
    """Append .NS suffix for NSE-listed Indian stocks unless already has suffix."""
    s = symbol.upper().strip()
    if "." in s:
        return s
    return f"{s}.NS"


def _is_nse_symbol(symbol: str) -> bool:
    """Check if symbol is a known NSE symbol."""
    return symbol.upper().strip().replace(".NS", "") in NSE_SYMBOLS


# ─── Yahoo Finance Helpers ─────────────────────────────────────────────────────


def _yf_ticker(symbol: str, max_retries: int = 2) -> yf.Ticker:
    """Create a yfinance Ticker with retry."""
    ticker_str = _nse_ticker(symbol)
    last_error = None
    for attempt in range(max_retries):
        try:
            ticker = yf.Ticker(ticker_str)
            # Force info fetch to verify ticker works
            _ = ticker.info or {}
            return ticker
        except Exception as e:
            last_error = e
            logger.warning(f"Ticker fetch failed for {ticker_str} (attempt {attempt+1}): {e}")
            if attempt < max_retries - 1:
                time.sleep(1)
    raise HTTPException(status_code=502, detail=f"Failed to fetch data for {symbol}: {last_error}")


def _extract_quote(ticker: yf.Ticker, symbol: str) -> dict:
    """Extract a standardised quote dict from a yfinance Ticker object."""
    try:
        info = ticker.info or {}
    except Exception:
        info = {}

    try:
        hist = ticker.history(period="2d")
    except Exception:
        hist = None

    # Current price — try multiple field names
    price = (
        info.get("currentPrice")
        or info.get("regularMarketPrice")
        or info.get("previousClose", 0)
    )
    prev_close = info.get("previousClose") or info.get("regularMarketPreviousClose", 0)

    if not prev_close and hist is not None and len(hist) >= 2:
        prev_close = float(hist["Close"].iloc[-2])
    elif not prev_close and hist is not None and len(hist) >= 1:
        prev_close = float(hist["Close"].iloc[-1])

    if not prev_close:
        prev_close = price if price else 0

    change = (price - prev_close) if price and prev_close else 0
    change_pct = (change / prev_close * 100) if prev_close else 0

    company_officers = info.get("companyOfficers", [])
    ceo_name = company_officers[0].get("name") if company_officers else info.get("ceo")

    return {
        "symbol": symbol.upper(),
        "name": info.get("longName") or info.get("shortName") or symbol,
        "exchange": info.get("exchange") or info.get("fullExchangeName") or "NSE",
        "sector": info.get("sector") or "",
        "industry": info.get("industry") or "",
        "currentPrice": round(float(price), 2) if price else 0,
        "previousClose": round(float(prev_close), 2) if prev_close else 0,
        "open": round(float(info.get("regularMarketOpen", 0)), 2) if info.get("regularMarketOpen") else None,
        "high": round(float(info.get("regularMarketDayHigh", 0)), 2) if info.get("regularMarketDayHigh") else None,
        "low": round(float(info.get("regularMarketDayLow", 0)), 2) if info.get("regularMarketDayLow") else None,
        "change": round(float(change), 2),
        "changePercent": round(float(change_pct), 2),
        "marketCap": info.get("marketCap") or 0,
        "volume": info.get("regularMarketVolume") or info.get("volume", 0),
        "avgVolume": info.get("averageVolume") or 0,
        "dividendYield": round(float(info.get("dividendYield", 0) * 100), 2) if info.get("dividendYield") else None,
        "peRatio": round(float(info.get("trailingPE", 0)), 2) if info.get("trailingPE") else None,
        "eps": round(float(info.get("trailingEps", 0)), 2) if info.get("trailingEps") else None,
        "pbRatio": round(float(info.get("priceToBook", 0)), 2) if info.get("priceToBook") else None,
        "roe": round(float(info.get("returnOnEquity", 0) * 100), 2) if info.get("returnOnEquity") else None,
        "debtToEquity": round(float(info.get("debtToEquity", 0)), 2) if info.get("debtToEquity") else None,
        "profitMargin": round(float(info.get("profitMargins", 0) * 100), 2) if info.get("profitMargins") else None,
        "revenueGrowth": round(float(info.get("revenueGrowth", 0) * 100), 2) if info.get("revenueGrowth") else None,
        "profitGrowth": None,
        "description": info.get("longBusinessSummary"),
        "ceo": ceo_name,
        "website": info.get("website"),
        "high52Week": round(float(info.get("fiftyTwoWeekHigh", 0)), 2) if info.get("fiftyTwoWeekHigh") else None,
        "low52Week": round(float(info.get("fiftyTwoWeekLow", 0)), 2) if info.get("fiftyTwoWeekLow") else None,
    }


# ─── Market Hours ──────────────────────────────────────────────────────────────


def _is_market_open() -> bool:
    """Check if Indian stock market is approximately open.
    Market hours: 9:15 AM to 3:30 PM IST, Monday-Friday.
    Uses a rough heuristic — does not account for holidays.
    """
    now_utc = datetime.now(timezone.utc)
    # Indian Standard Time = UTC + 5:30
    ist_offset = timedelta(hours=5, minutes=30)
    now_ist = (now_utc + ist_offset).time()

    weekday = now_utc.weekday()
    if weekday >= 5:  # Saturday/Sunday
        return False

    market_open = datetime(2024, 1, 1, 9, 15).time()
    market_close = datetime(2024, 1, 1, 15, 30).time()
    return market_open <= now_ist <= market_close


# ─── RSS News Feed ─────────────────────────────────────────────────────────────


async def _fetch_rss_feed(url: str, source_name: str) -> list[dict]:
    """Fetch and parse an RSS/Atom feed as a list of news items."""
    import xml.etree.ElementTree as ET

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, headers={"User-Agent": "InvestPro/2.0"})
            resp.raise_for_status()

        root = ET.fromstring(resp.text)
        items = []

        # Handle both RSS (<channel><item>) and Atom (namespace) formats
        ns = {"atom": "http://www.w3.org/2005/Atom"}
        channel = root.find("channel")

        for entry in (channel.findall("item") if channel is not None else root.findall("atom:entry", ns)):
            title = ""
            link = ""
            pub_date = datetime.now()

            if channel is not None:
                # RSS format
                title_el = entry.find("title")
                title = title_el.text if title_el is not None else ""

                link_el = entry.find("link")
                link = link_el.text if link_el is not None else ""

                desc_el = entry.find("description")
                summary = desc_el.text if desc_el is not None else title

                pub_el = entry.find("pubDate")
                if pub_el is not None and pub_el.text:
                    try:
                        pub_date = datetime.strptime(pub_el.text[:25], "%a, %d %b %Y %H:%M:%S")
                    except ValueError:
                        pass
            else:
                # Atom format
                title_el = entry.find("atom:title", ns)
                title = title_el.text if title_el is not None else ""

                link_el = entry.find("atom:link", ns)
                link = link_el.attrib.get("href", "") if link_el is not None else ""

                summary_el = entry.find("atom:summary", ns)
                summary = summary_el.text if summary_el is not None else title

                pub_el = entry.find("atom:updated", ns)
                if pub_el is not None and pub_el.text:
                    try:
                        pub_date = datetime.fromisoformat(pub_el.text.replace("Z", "+00:00"))
                    except ValueError:
                        pass

            if not title:
                continue

            import hashlib
            item_id = hashlib.md5((title + str(pub_date.timestamp())).encode()).hexdigest()[:12]

            items.append({
                "id": item_id,
                "title": title.strip(),
                "summary": summary.strip() if isinstance(summary, str) else title.strip(),
                "source": source_name,
                "imageUrl": None,
                "url": link,
                "publishedAt": pub_date.isoformat(),
                "category": "market",
            })

        return items
    except Exception as e:
        logger.warning(f"RSS feed error for {source_name} ({url}): {e}")
        return []


async def _fetch_news_from_rss() -> list[dict]:
    """Fetch market news from financial RSS feeds."""
    feeds = [
        ("https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms", "Economic Times"),
        ("https://www.moneycontrol.com/rss/market.xml", "Moneycontrol"),
        ("https://www.livemint.com/market/feed.xml", "Livemint"),
    ]

    all_items = []
    for url, source in feeds:
        items = await _fetch_rss_feed(url, source)
        all_items.extend(items)

    # Sort by date (newest first) and deduplicate by title
    seen_titles = set()
    unique_items = []
    for item in sorted(all_items, key=lambda x: x.get("publishedAt", ""), reverse=True):
        title_lower = item["title"].strip().lower()
        if title_lower not in seen_titles and len(title_lower) > 10:
            seen_titles.add(title_lower)
            unique_items.append(item)

    return unique_items[:20]


# ─── API Endpoints ────────────────────────────────────────────────────────────


@app.get("/api/health")
async def health():
    """Health check with cache stats."""
    return {
        "status": "ok",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat(),
        "cache": {
            "hits": _cache_stats["hits"],
            "misses": _cache_stats["misses"],
            "entries": len(_cache),
        },
        "marketOpen": _is_market_open(),
    }


@app.get("/api/quote/{symbol:path}")
async def get_quote(symbol: str):
    """Get real-time stock quote for a single symbol.
    Examples: RELIANCE, TCS.NS, SBIN, AAPL
    """
    cache_key = f"quote:{symbol.upper()}"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    try:
        ticker = _yf_ticker(symbol)
        quote = _extract_quote(ticker, symbol)
        _cache_set(cache_key, quote, ttl_seconds=30)
        return quote
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch quote for {symbol}: {e}")
        raise HTTPException(status_code=502, detail=f"Failed to fetch data for {symbol}: {str(e)}")


class QuotesRequest(BaseModel):
    symbols: list[str]


@app.post("/api/quotes")
async def get_quotes(req: QuotesRequest):
    """Get quotes for multiple symbols in parallel.
    Returns a dict mapping symbol -> quote data.
    Fetches in batches of 5 to avoid rate limits.
    """
    symbols = [s.upper().strip() for s in req.symbols]
    results = {}
    failed = []

    async def fetch_one(sym: str):
        cache_key = f"quote:{sym}"
        cached = _cache_get(cache_key)
        if cached:
            results[sym] = cached
            return
        try:
            ticker = _yf_ticker(sym)
            quote = _extract_quote(ticker, sym)
            _cache_set(cache_key, quote, ttl_seconds=30)
            results[sym] = quote
        except Exception as e:
            logger.warning(f"Failed to fetch {sym}: {e}")
            failed.append(sym)

    for i in range(0, len(symbols), BATCH_SIZE):
        batch = symbols[i:i + BATCH_SIZE]
        await asyncio.gather(*[fetch_one(s) for s in batch])
        if i + BATCH_SIZE < len(symbols):
            await asyncio.sleep(BATCH_DELAY)

    return {
        "results": results,
        "failed": failed,
        "total": len(symbols),
        "successful": len(results),
    }


@app.get("/api/history/{symbol:path}")
async def get_history(
    symbol: str,
    period: str = Query("1mo", description="1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, max"),
    interval: str = Query("1d", description="1m, 2m, 5m, 15m, 30m, 60m, 1d, 1wk, 1mo"),
):
    """Get historical OHLCV price data for charting."""
    cache_key = f"hist:{symbol.upper()}:{period}:{interval}"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    period_map = {
        "1d": "1d", "5d": "5d", "1w": "5d", "1W": "5d",
        "1mo": "1mo", "1M": "1mo", "3mo": "3mo", "3M": "3mo",
        "6mo": "6mo", "6M": "6mo", "1y": "1y", "1Y": "1y",
        "2y": "2y", "2Y": "2y", "5y": "5y", "5Y": "5y",
    }

    interval_map = {
        "1m": "1m", "2m": "2m", "5m": "5m", "15m": "15m",
        "30m": "30m", "60m": "60m", "1h": "60m", "1d": "1d",
        "1D": "1d", "1wk": "1wk", "1Wk": "1wk", "1mo": "1mo", "1Mo": "1mo",
    }

    yf_period = period_map.get(period, "1mo")
    yf_interval = interval_map.get(interval, "1d")

    try:
        ticker_str = _nse_ticker(symbol)
        logger.info(f"Fetching history for {symbol} period={yf_period} interval={yf_interval}")
        ticker = yf.Ticker(ticker_str)
        hist = ticker.history(period=yf_period, interval=yf_interval)

        if hist.empty:
            logger.warning(f"No history data for {symbol}")
            return {"symbol": symbol.upper(), "prices": []}

        prices = []
        for idx, row in hist.iterrows():
            ts = int(idx.timestamp()) if hasattr(idx, "timestamp") else int(idx.to_pydatetime().timestamp())
            prices.append({
                "date": idx.isoformat() if hasattr(idx, "isoformat") else str(idx),
                "timestamp": ts,
                "open": round(float(row.get("Open", 0)), 2),
                "high": round(float(row.get("High", 0)), 2),
                "low": round(float(row.get("Low", 0)), 2),
                "close": round(float(row.get("Close", 0)), 2),
                "volume": int(row.get("Volume", 0)),
            })

        result = {"symbol": symbol.upper(), "prices": prices}
        ttl = 600 if yf_interval in ("1d", "1wk", "1mo") else 120
        _cache_set(cache_key, result, ttl_seconds=ttl)
        return result

    except Exception as e:
        logger.error(f"Failed to fetch history for {symbol}: {e}")
        raise HTTPException(status_code=502, detail=str(e))


@app.get("/api/search")
async def search_stocks(q: str = Query("", description="Search keyword")):
    """Search for stocks by name or symbol."""
    if not q or len(q) < 1:
        return {"results": []}

    try:
        logger.info(f"Searching for '{q}'")
        # Try direct ticker lookup first
        ticker_str = _nse_ticker(q) if not q.upper() in ("AAPL", "MSFT", "GOOGL", "AMZN", "META", "TSLA", "NVDA") else q
        try:
            ticker = yf.Ticker(ticker_str)
            info = ticker.info or {}
            if info.get("shortName") or info.get("longName"):
                quote = _extract_quote(ticker, q)
                return {"results": [quote]}
        except Exception:
            pass

        # Use yfinance search
        from yfinance import search as yf_search
        search_results = yf_search.Search(q)
        items = []
        for item in getattr(search_results, "quotes", []) or []:
            sym = item.get("symbol", "").replace(".NS", "").replace(".BO", "")
            sector = item.get("sector") or ""
            items.append({
                "symbol": sym,
                "name": item.get("shortname") or item.get("longname") or sym,
                "exchange": item.get("exchange") or "NSE",
                "sector": sector,
                "industry": item.get("industry") or "",
                "currentPrice": float(item.get("regularMarketPrice", 0) or 0),
                "change": float(item.get("regularMarketChange", 0) or 0),
                "changePercent": float(item.get("regularMarketChangePercent", 0) or 0),
            })

        return {"results": items}
    except Exception as e:
        logger.warning(f"Search failed for '{q}': {e}")
        return {"results": []}


@app.get("/api/news")
async def get_news():
    """Get latest market news from RSS feeds with Yahoo Finance fallback."""
    cache_key = "news_v2"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    news_items = []

    # 1. Try RSS feeds first (richer, Indian-specific)
    try:
        rss_news = await _fetch_news_from_rss()
        if rss_news:
            news_items = rss_news
    except Exception as e:
        logger.warning(f"RSS news fetch failed: {e}")

    # 2. Fallback to Yahoo Finance news if RSS returned nothing
    if not news_items:
        try:
            nsei = yf.Ticker("^NSEI")
            yf_news = getattr(nsei, "news", []) or []
            for item in (yf_news or [])[:15]:
                t = item.get("providerPublishTime", item.get("pubDate", 0))
                if isinstance(t, (int, float)):
                    pub_date = datetime.fromtimestamp(t)
                else:
                    pub_date = datetime.now()
                news_items.append({
                    "id": item.get("uuid", item.get("id", str(int(time.time())))),
                    "title": item.get("title", ""),
                    "summary": item.get("summary", item.get("title", "")),
                    "source": item.get("publisher", "Yahoo Finance"),
                    "imageUrl": None,
                    "url": item.get("link", item.get("url", "")),
                    "publishedAt": pub_date.isoformat(),
                    "category": "market",
                })
        except Exception as e:
            logger.warning(f"Yahoo Finance news fallback failed: {e}")

    result = {"news": news_items}
    _cache_set(cache_key, result, ttl_seconds=300)
    return result


@app.get("/api/market-overview")
async def market_overview():
    """Get Indian market indices: Nifty 50, Sensex, Bank Nifty."""
    cache_key = "market_overview"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    result = {}
    for name, ticker_sym in INDICES_TICKERS.items():
        try:
            ticker = yf.Ticker(ticker_sym)
            info = ticker.info or {}
            hist = ticker.history(period="2d")

            price = info.get("regularMarketPrice") or info.get("previousClose", 0)
            prev_close = info.get("regularMarketPreviousClose") or info.get("previousClose", 0)

            if not prev_close and hist is not None and len(hist) >= 2:
                prev_close = float(hist["Close"].iloc[-2])
            elif not prev_close and hist is not None and len(hist) >= 1:
                prev_close = float(hist["Close"].iloc[-1])

            change = price - prev_close if price and prev_close else 0
            change_pct = (change / prev_close * 100) if prev_close else 0

            result[name] = {
                "currentValue": round(float(price), 2) if price else 0,
                "change": round(float(change), 2),
                "changePercent": round(float(change_pct), 2),
                "dayHigh": round(float(info.get("regularMarketDayHigh", 0)), 2),
                "dayLow": round(float(info.get("regularMarketDayLow", 0)), 2),
                "volume": info.get("regularMarketVolume", 0),
            }
        except Exception as e:
            logger.warning(f"Failed to fetch {name}: {e}")
            result[name] = None

    output = {
        "indices": result,
        "isMarketOpen": _is_market_open(),
        "timestamp": datetime.now().isoformat(),
    }
    _cache_set(cache_key, output, ttl_seconds=30)
    return output


@app.get("/api/default-quotes")
async def default_quotes():
    """Fetch all 15 default Indian stock quotes in parallel batches."""
    cache_key = "default_quotes"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    results = {}

    async def fetch_one(sym: str):
        cache_key_sym = f"quote:{sym}"
        cached_sym = _cache_get(cache_key_sym)
        if cached_sym:
            results[sym] = cached_sym
            return
        try:
            ticker = _yf_ticker(sym)
            quote = _extract_quote(ticker, sym)
            _cache_set(cache_key_sym, quote, ttl_seconds=30)
            results[sym] = quote
        except Exception as e:
            logger.warning(f"Failed to fetch {sym}: {e}")

    for i in range(0, len(DEFAULT_SYMBOLS), BATCH_SIZE):
        batch = DEFAULT_SYMBOLS[i:i + BATCH_SIZE]
        await asyncio.gather(*[fetch_one(s) for s in batch])
        if i + BATCH_SIZE < len(DEFAULT_SYMBOLS):
            await asyncio.sleep(BATCH_DELAY)

    _cache_set(cache_key, results, ttl_seconds=30)
    return {"results": results}


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("""
+----------------------------------------------------------+
|            InvestPro Real-Time Data Server v2            |
|                                                          |
|  Endpoints:                                              |
|    /api/health          -> Health + cache stats          |
|    /api/quote/{symbol}  -> Single stock quote            |
|    /api/quotes          -> Multiple stock quotes (POST)  |
|    /api/history/{sym}   -> Historical OHLCV data         |
|    /api/search?q=       -> Stock search                  |
|    /api/news            -> Market news (RSS + fallback)  |
|    /api/market-overview -> Nifty 50, Sensex, Bank Nifty  |
|    /api/default-quotes  -> 15 predefined Indian stocks    |
|                                                          |
|  Running on http://localhost:5000                        |
+----------------------------------------------------------+
""")
    uvicorn.run(app, host="0.0.0.0", port=5000, log_level="info")
