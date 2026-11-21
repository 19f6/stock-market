# Mock Market — real-time stock-market simulator

A Flutter app that simulates trading on a live market, plus the mock data
server it talks to.

> **Note on "resources":** the brief mentions a provided mock-data server in
> `resources/`. That folder was not present in this repo, so `server/` contains
> a drop-in replacement with the same role: real-time quotes over WebSocket and
> historical OHLC over REST. If you have the official server, point the app at it
> with `--dart-define=API_HOST=... --dart-define=API_PORT=...` — the client only
> depends on the small contract documented below.

## Layout

```
server/   Node.js mock data server (REST + WebSocket)
app/      Flutter client (BLoC state management)
```

## Running

### 1. Start the data server

```bash
cd server
npm install
npm start          # http://localhost:8080  +  ws://localhost:8080
```

It builds a synthetic daily history for 20 stocks from their IPO date to today,
then streams **6 price ticks per second** for every symbol.

### 2. Run the app

```bash
cd app
flutter pub get
flutter run                     # localhost is reachable from iOS simulator
# physical device / another host:
flutter run --dart-define=API_HOST=192.168.1.20
```

## The 20 monitored stocks

AAPL, MSFT, GOOGL, AMZN, NVDA, META, TSLA, BRK.B, JPM, V, JNJ, WMT, PG, MA, HD,
DIS, KO, NFLX, AMD, INTC.

## Features → where they live

| Requirement | Implementation |
|---|---|
| Login / Signup (separate route) | `/login` · `ui/pages/login_page.dart` · `AuthBloc` · `AuthRepository` (salted sha256, session in SharedPreferences) |
| Authorization | `ui/router.dart` redirect guard — unauthenticated users can only reach `/login` |
| $1,000,000 on signup | `PortfolioRepository` / `Portfolio.initial()` |
| Wallet (holdings + quantities + live portfolio) | `/wallet` · `ui/pages/wallet_page.dart` |
| Historical data page | `/stock/:symbol` · `_HistoryTable` (OHLC + volume) |
| Historical charts | `ui/widgets/price_chart.dart` (`fl_chart`), range selector 1M–MAX |
| Buy / sell / hold | `ui/widgets/trade_sheet.dart` · `PortfolioBloc` · `PortfolioRepository` |
| Real-time data ≥ 5×/sec | `MarketSocket` → `MarketRepository` → `MarketBloc` (server ticks at 6 Hz) |
| Custom real-time widgets | `PriceFlash` (flash on tick), `Sparkline` (rolling live line) |
| Data since IPO / last year | `GET /stocks/:symbol/history?range=1y|max` |
| State management | **BLoC** throughout (`flutter_bloc`) |

## Server API contract

| Method | Path | Returns |
|---|---|---|
| GET | `/stocks` | array of quotes `{symbol,name,sector,ipo,price,prevClose,change,changePct}` |
| GET | `/stocks/:symbol` | one quote |
| GET | `/stocks/:symbol/history?range=1m\|3m\|6m\|1y\|5y\|max` | `{symbol,range,candles:[{t,open,high,low,close,volume}]}` |
| WS | `/` | `{type:'snapshot',ts,quotes:[...]}` on connect, then `{type:'tick',ts,quotes:[{symbol,price,change,changePct}]}` ~6×/sec |

## Tests

```bash
cd app && flutter test
```

Covers auth (signup, duplicate rejection, bad password) and trading (starting
balance, buy/sell math, insufficient funds, overselling).
