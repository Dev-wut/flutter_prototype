import 'package:flutter/material.dart';

class SizeUtil {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double defaultSize;
  static late Orientation orientation;

  // ตั้งค่าขนาดเริ่มต้น
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;

    // ใช้ความกว้างเป็นฐานในการคำนวณ ขนาดมาตรฐานอ้างอิงคือ 375pt (iPhone)
    defaultSize = orientation == Orientation.landscape
        ? screenHeight * 0.024
        : screenWidth * 0.024;
  }

  // คำนวณขนาดตามจอ
  static double scaleWidth(double size) {
    return (size / 375.0) * screenWidth;
  }

  static double scaleHeight(double size) {
    return (size / 812.0) * screenHeight;
  }

  // สำหรับขนาดทั่วไปที่ควรปรับตามขนาดจอ
  static double scale(double size) {
    return size * defaultSize;
  }

  // ตรวจสอบว่าอุปกรณ์เป็นแท็บเล็ตหรือไม่
  static bool get isTablet {
    final shortestSide = _mediaQueryData.size.shortestSide;
    return shortestSide >= 600;
  }

  // ตรวจสอบโหมดแนวตั้ง/แนวนอน
  static bool get isPortrait {
    return orientation == Orientation.portrait;
  }

  static bool get isLandscape {
    return orientation == Orientation.landscape;
  }

  // ระยะขอบปลอดภัย
  static EdgeInsets get padding {
    return _mediaQueryData.padding;
  }

  static double get topPadding {
    return _mediaQueryData.padding.top;
  }

  static double get bottomPadding {
    return _mediaQueryData.padding.bottom;
  }
}