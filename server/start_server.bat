@echo off
REM ============================================================
REM InvestPro - Start Real-Time Data Server
REM ============================================================
REM This script starts the Python data proxy server.
REM Keep this running while you use the InvestPro Flutter app.
REM
REM The Flutter app connects to this server at http://localhost:5000
REM to fetch live stock prices, charts, news, and market indices.
REM
REM Press Ctrl+C to stop the server.
REM ============================================================

echo [InvestPro] Starting real-time data server...
cd /d "%~dp0"
python realtime_server.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to start server.
    echo Make sure Python and required packages are installed:
    echo   pip install fastapi uvicorn yfinance
    pause
)
