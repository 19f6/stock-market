// The 20 stocks monitored by the app.
//   basePrice ~ price around IPO; target ~ desired "today" price (history is
//   rescaled so the simulated series ends near this value and looks plausible).
module.exports = [
  { symbol: 'AAPL', name: 'Apple Inc.', sector: 'Technology', ipo: '1980-12-12', basePrice: 0.5, target: 230, drift: 0.00045, vol: 0.018 },
  { symbol: 'MSFT', name: 'Microsoft Corp.', sector: 'Technology', ipo: '1986-03-13', basePrice: 0.1, target: 430, drift: 0.00050, vol: 0.017 },
  { symbol: 'GOOGL', name: 'Alphabet Inc.', sector: 'Communication Services', ipo: '2004-08-19', basePrice: 50, target: 175, drift: 0.00040, vol: 0.019 },
  { symbol: 'AMZN', name: 'Amazon.com Inc.', sector: 'Consumer Discretionary', ipo: '1997-05-15', basePrice: 1.5, target: 185, drift: 0.00055, vol: 0.023 },
  { symbol: 'NVDA', name: 'NVIDIA Corp.', sector: 'Technology', ipo: '1999-01-22', basePrice: 1.5, target: 125, drift: 0.00070, vol: 0.032 },
  { symbol: 'META', name: 'Meta Platforms Inc.', sector: 'Communication Services', ipo: '2012-05-18', basePrice: 38, target: 560, drift: 0.00042, vol: 0.026 },
  { symbol: 'TSLA', name: 'Tesla Inc.', sector: 'Consumer Discretionary', ipo: '2010-06-29', basePrice: 1.3, target: 250, drift: 0.00065, vol: 0.041 },
  { symbol: 'BRK.B', name: 'Berkshire Hathaway Inc.', sector: 'Financials', ipo: '1996-05-09', basePrice: 20, target: 460, drift: 0.00030, vol: 0.011 },
  { symbol: 'JPM', name: 'JPMorgan Chase & Co.', sector: 'Financials', ipo: '1980-03-17', basePrice: 5, target: 220, drift: 0.00028, vol: 0.016 },
  { symbol: 'V', name: 'Visa Inc.', sector: 'Financials', ipo: '2008-03-19', basePrice: 11, target: 290, drift: 0.00045, vol: 0.015 },
  { symbol: 'JNJ', name: 'Johnson & Johnson', sector: 'Health Care', ipo: '1970-01-02', basePrice: 1, target: 155, drift: 0.00025, vol: 0.010 },
  { symbol: 'WMT', name: 'Walmart Inc.', sector: 'Consumer Staples', ipo: '1972-08-25', basePrice: 0.06, target: 75, drift: 0.00030, vol: 0.012 },
  { symbol: 'PG', name: 'Procter & Gamble Co.', sector: 'Consumer Staples', ipo: '1970-01-02', basePrice: 1, target: 165, drift: 0.00024, vol: 0.010 },
  { symbol: 'MA', name: 'Mastercard Inc.', sector: 'Financials', ipo: '2006-05-25', basePrice: 4, target: 480, drift: 0.00048, vol: 0.016 },
  { symbol: 'HD', name: 'The Home Depot Inc.', sector: 'Consumer Discretionary', ipo: '1981-09-22', basePrice: 0.2, target: 400, drift: 0.00035, vol: 0.015 },
  { symbol: 'DIS', name: 'The Walt Disney Co.', sector: 'Communication Services', ipo: '1970-01-02', basePrice: 1, target: 95, drift: 0.00022, vol: 0.017 },
  { symbol: 'KO', name: 'The Coca-Cola Co.', sector: 'Consumer Staples', ipo: '1970-01-02', basePrice: 1.5, target: 70, drift: 0.00020, vol: 0.009 },
  { symbol: 'NFLX', name: 'Netflix Inc.', sector: 'Communication Services', ipo: '2002-05-23', basePrice: 1.2, target: 700, drift: 0.00060, vol: 0.033 },
  { symbol: 'AMD', name: 'Advanced Micro Devices Inc.', sector: 'Technology', ipo: '1972-09-27', basePrice: 3, target: 160, drift: 0.00040, vol: 0.035 },
  { symbol: 'INTC', name: 'Intel Corp.', sector: 'Technology', ipo: '1971-10-13', basePrice: 0.5, target: 30, drift: 0.00018, vol: 0.019 },
];
