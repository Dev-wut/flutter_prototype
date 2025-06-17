class AssetConstants {
  // ไอคอนแอพ
  static const String appIcon = 'assets/icons/app_icon.png';

  // ภาพ
  static const String splashLogo = 'assets/images/splash_logo.png';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const String emptyState = 'assets/images/empty_state.png';
  static const String errorState = 'assets/images/error_state.png';

  // ไอคอน (SVG)
  static const String iconPath = 'assets/icons';
  static const String homeIcon = '$iconPath/home.svg';
  static const String marketIcon = '$iconPath/market.svg';
  static const String portfolioIcon = '$iconPath/portfolio.svg';
  static const String alertsIcon = '$iconPath/alerts.svg';
  static const String settingsIcon = '$iconPath/settings.svg';

  // แอนิเมชัน
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String errorAnimation = 'assets/animations/error.json';

  // สกุลเงินคริปโต
  static const String cryptoIconsPath = 'assets/icons/crypto';
  static const String btcIcon = '$cryptoIconsPath/btc.png';
  static const String ethIcon = '$cryptoIconsPath/eth.png';
  static const String bnbIcon = '$cryptoIconsPath/bnb.png';
  static const String solIcon = '$cryptoIconsPath/sol.png';
  static const String xrpIcon = '$cryptoIconsPath/xrp.png';

  // ฟังก์ชันสำหรับดึงไอคอนสกุลเงินตาม ID
  static String getCryptoIcon(String id) {
    return '$cryptoIconsPath/$id.png';
  }
}