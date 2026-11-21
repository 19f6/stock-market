'use strict';
/*
 * Mock real-time stock-market data server.
 *
 * REST (http://localhost:8080):
 *   GET /health                      -> { ok: true }
 *   GET /stocks                      -> [{ symbol, name, sector, ipo, price, prevClose, change, changePct }]
 *   GET /stocks/:symbol              -> single quote (same shape as above)
 *   GET /stocks/:symbol/history?range=1m|3m|6m|1y|5y|max
 *                                    -> { symbol, range, candles: [{ t, open, high, low, close, volume }] }
 *
 * WebSocket (ws://localhost:8080):
 *   On connect the server sends a "snapshot" frame, then "tick" frames ~6x/second.
 *     { type: 'snapshot', ts, quotes: [ ...quote ] }
 *     { type: 'tick', ts, quotes: [ { symbol, price, change, changePct } ] }
 */

const http = require('http');
const { WebSocketServer } = require('ws');
const STOCKS = require('./stocks');

const PORT = process.env.PORT || 8080;
const TICKS_PER_SECOND = 6;
const DAY_MS = 24 * 60 * 60 * 1000;

// ---------------------------------------------------------------------------
// Seeded PRNG so history is stable across restarts within a run.
// ---------------------------------------------------------------------------
function mulberry32(seed) {
  return function () {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
function gauss(rand) {
  let u = 0, v = 0;
  while (u === 0) u = rand();
  while (v === 0) v = rand();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}

// ---------------------------------------------------------------------------
// Build daily history from IPO date to today for each stock.
// ---------------------------------------------------------------------------
const HISTORY = {};  // symbol -> daily  [{ t, open, high, low, close, volume }]
const INTRADAY = {}; // symbol -> 5-min  [{ t, open, high, low, close, volume }]
const STATE = {};    // symbol -> { price, prevClose }

function hashSeed(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function buildHistory(stock) {
  const rand = mulberry32(hashSeed(stock.symbol));
  const start = new Date(stock.ipo + 'T00:00:00Z').getTime();
  const today = new Date();
  const end = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
  const candles = [];
  let price = stock.basePrice;
  for (let t = start; t <= end; t += DAY_MS) {
    const day = new Date(t).getUTCDay();
    if (day === 0 || day === 6) continue; // skip weekends
    const open = price;
    const shock = stock.drift + stock.vol * gauss(rand);
    let close = open * Math.exp(shock);
    if (close < 0.01) close = 0.01;
    const hi = Math.max(open, close) * (1 + Math.abs(stock.vol * gauss(rand)) * 0.5);
    const lo = Math.min(open, close) * (1 - Math.abs(stock.vol * gauss(rand)) * 0.5);
    const volume = Math.round((5e6 + rand() * 5e7) * (1 + stock.vol * 5));
    candles.push({
      t,
      open: round2(open),
      high: round2(Math.max(hi, open, close)),
      low: round2(Math.max(0.01, Math.min(lo, open, close))),
      close: round2(close),
      volume,
    });
    price = close;
  }
  // Rescale the whole series so it ends near the desired "today" price.
  if (stock.target && candles.length) {
    const scale = stock.target / candles[candles.length - 1].close;
    for (const c of candles) {
      c.open = round2(c.open * scale);
      c.high = round2(c.high * scale);
      c.low = round2(c.low * scale);
      c.close = round2(c.close * scale);
    }
  }
  HISTORY[stock.symbol] = candles;
  const last = candles[candles.length - 1];
  const prev = candles[candles.length - 2] || last;
  STATE[stock.symbol] = { price: last.close, prevClose: prev.close, symbol: stock.symbol };
  buildIntraday(stock, prev.close, last.close);
}

// Fine-grained (5-minute) bars for the last 7 days, so the app can show a
// "day" and "week" slice. Walks from the prior daily close to the latest one.
const INTRADAY_DAYS = 7;
const STEP_MS = 5 * 60 * 1000;
function buildIntraday(stock, fromPrice, toPrice) {
  const rand = mulberry32(hashSeed(stock.symbol + ':id'));
  const now = Date.now();
  const start = now - INTRADAY_DAYS * DAY_MS;
  const n = Math.floor((now - start) / STEP_MS);
  const bars = [];
  let price = fromPrice;
  for (let i = 0; i < n; i++) {
    const t = start + i * STEP_MS;
    const open = price;
    // small random step, gently pulled toward the target close by the end
    const progress = i / n;
    const target = fromPrice + (toPrice - fromPrice) * progress;
    const pull = Math.log(target / open) * 0.05;
    let close = open * Math.exp(stock.vol * 0.12 * gauss(rand) + pull);
    if (close < 0.01) close = 0.01;
    const hi = Math.max(open, close) * (1 + Math.abs(stock.vol * 0.08 * gauss(rand)));
    const lo = Math.min(open, close) * (1 - Math.abs(stock.vol * 0.08 * gauss(rand)));
    bars.push({
      t,
      open: round2(open),
      high: round2(Math.max(hi, open, close)),
      low: round2(Math.max(0.01, Math.min(lo, open, close))),
      close: round2(close),
      volume: Math.round(2e5 + rand() * 2e6),
    });
    price = close;
  }
  INTRADAY[stock.symbol] = bars;
}

function round2(n) { return Math.round(n * 100) / 100; }

STOCKS.forEach(buildHistory);
console.log(`Built history for ${STOCKS.length} stocks.`);

// ---------------------------------------------------------------------------
// Real-time tick engine: random walk from the last known price.
// ---------------------------------------------------------------------------
const tickRand = mulberry32(Date.now() & 0xffffffff);

function tick() {
  for (const s of STOCKS) {
    const st = STATE[s.symbol];
    // Mean-reverting random walk around prevClose so intraday % stays realistic.
    const pull = Math.log(st.prevClose / st.price) * 0.002;
    const step = s.vol * 0.05 * gauss(tickRand) + pull;
    let next = st.price * Math.exp(step);
    if (next < 0.01) next = 0.01;
    st.price = round2(next);
  }
}

function quote(symbol) {
  const s = STOCKS.find((x) => x.symbol === symbol);
  const st = STATE[symbol];
  const change = round2(st.price - st.prevClose);
  const changePct = round2((change / st.prevClose) * 100);
  return {
    symbol,
    name: s.name,
    sector: s.sector,
    ipo: s.ipo,
    price: st.price,
    prevClose: round2(st.prevClose),
    change,
    changePct,
  };
}

function allQuotes() { return STOCKS.map((s) => quote(s.symbol)); }

function lightTick() {
  return STOCKS.map((s) => {
    const q = quote(s.symbol);
    return { symbol: q.symbol, price: q.price, change: q.change, changePct: q.changePct };
  });
}

// ---------------------------------------------------------------------------
// HTTP server
// ---------------------------------------------------------------------------
function send(res, code, body) {
  res.writeHead(code, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': '*',
  });
  res.end(JSON.stringify(body));
}

const RANGE_DAYS = { '1m': 30, '3m': 90, '6m': 182, '1y': 365, '5y': 365 * 5, max: Infinity };
// Intraday ranges are served from the 5-minute series instead of daily bars.
const INTRADAY_RANGE_DAYS = { '1d': 1, '1w': 7 };

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const parts = url.pathname.split('/').filter(Boolean);

  if (req.method === 'OPTIONS') return send(res, 204, {});

  if (parts.length === 1 && parts[0] === 'health') return send(res, 200, { ok: true });

  if (parts[0] === 'stocks' && parts.length === 1) return send(res, 200, allQuotes());

  if (parts[0] === 'stocks' && parts.length === 2) {
    const sym = decodeURIComponent(parts[1]);
    if (!STATE[sym]) return send(res, 404, { error: 'unknown symbol' });
    return send(res, 200, quote(sym));
  }

  if (parts[0] === 'stocks' && parts.length === 3 && parts[2] === 'history') {
    const sym = decodeURIComponent(parts[1]);
    if (!HISTORY[sym]) return send(res, 404, { error: 'unknown symbol' });
    const range = (url.searchParams.get('range') || '1y').toLowerCase();
    const intradayDays = INTRADAY_RANGE_DAYS[range];
    const all = intradayDays ? (INTRADAY[sym] || []) : HISTORY[sym];
    const days = intradayDays ?? RANGE_DAYS[range] ?? 365;
    const cutoff = Date.now() - days * DAY_MS;
    const candles = days === Infinity ? all : all.filter((c) => c.t >= cutoff);
    // downsample very long series so payloads stay reasonable
    const step = Math.ceil(candles.length / 1500) || 1;
    const out = step > 1 ? candles.filter((_, i) => i % step === 0) : candles;
    return send(res, 200, { symbol: sym, range, candles: out });
  }

  return send(res, 404, { error: 'not found' });
});

// ---------------------------------------------------------------------------
// WebSocket server
// ---------------------------------------------------------------------------
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'snapshot', ts: Date.now(), quotes: allQuotes() }));
});

setInterval(() => {
  tick();
  const payload = JSON.stringify({ type: 'tick', ts: Date.now(), quotes: lightTick() });
  for (const client of wss.clients) {
    if (client.readyState === 1) client.send(payload);
  }
}, Math.round(1000 / TICKS_PER_SECOND));

server.listen(PORT, () => {
  console.log(`Mock stock server on http://localhost:${PORT}  (ws://localhost:${PORT})`);
  console.log(`Streaming ${TICKS_PER_SECOND} ticks/sec for: ${STOCKS.map((s) => s.symbol).join(', ')}`);
});
