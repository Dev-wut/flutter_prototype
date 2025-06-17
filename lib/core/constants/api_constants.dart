class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  // Endpoints
  static const String coins = '/coins';
  static const String markets = '/coins/markets';
  static const String coinDetail = '/coins/{id}';
  static const String chart = '/coins/{id}/market_chart';

  // Parameters
  static const String currencyParam = 'vs_currency';
  static const String idsParam = 'ids';
  static const String orderParam = 'order';
  static const String perPageParam = 'per_page';
  static const String pageParam = 'page';
  static const String sparklineParam = 'sparkline';
  static const String priceChangeParam = 'price_change_percentage';
  static const String daysParam = 'days';
  static const String intervalParam = 'interval';

  // Default Values
  static const String defaultCurrency = 'usd';
  static const String marketCapDesc = 'market_cap_desc';
  static const int defaultPerPage = 100;
  static const int defaultPage = 1;
}