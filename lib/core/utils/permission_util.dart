import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class สำหรับจัดการ permissions ในแอปพลิเคชัน Flutter
/// รองรับทั้ง Android และ iOS พร้อมการจัดการ SDK versions ต่างๆ
class PermissionUtil {

  /// ขอสิทธิ์การเข้าถึงพื้นที่จัดเก็บตามแพลตฟอร์มและเวอร์ชัน Android SDK
  /// สำหรับ Android SDK 33+ จะใช้ Permission.photos
  /// สำหรับ Android SDK ต่ำกว่า 33 จะใช้ Permission.storage
  /// สำหรับ iOS จะใช้ Permission.photos
  ///
  /// Returns [PermissionStatus] สถานะของการขอสิทธิ์
  static Future<PermissionStatus> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidStoragePermission();
      } else if (Platform.isIOS) {
        return await _requestIOSStoragePermission();
      } else {
        return PermissionStatus.denied;
      }
    } catch (e) {
      // จัดการ error ที่อาจเกิดขึ้นจากการเข้าถึงข้อมูลแพลตฟอร์ม
      log('Error requesting storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// ขอสิทธิ์การเข้าถึงพื้นที่จัดเก็บสำหรับ Android
  /// จัดการการเปลี่ยนแปลงของ scoped storage ใน Android 13+ (API 33+)
  static Future<PermissionStatus> _requestAndroidStoragePermission() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      final permission = sdkInt >= 33 ? Permission.photos : Permission.storage;

      // ตรวจสอบว่ามีสิทธิ์อยู่แล้วหรือไม่
      if (await permission.isGranted || await permission.isLimited) {
        return PermissionStatus.granted;
      }

      // ตรวจสอบว่าถูกปฏิเสธถาวรหรือไม่
      if (await permission.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }

      // ขอสิทธิ์
      return await permission.request();
    } catch (e) {
      log('Error requesting Android storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// ขอสิทธิ์การเข้าถึงพื้นที่จัดเก็บสำหรับ iOS
  /// ใช้ Permission.photos สำหรับการเข้าถึงรูปภาพและวิดีโอ
  static Future<PermissionStatus> _requestIOSStoragePermission() async {
    try {
      const permission = Permission.photos;

      // ตรวจสอบว่ามีสิทธิ์อยู่แล้วหรือไม่
      if (await permission.isGranted || await permission.isLimited) {
        return PermissionStatus.granted;
      }

      // ตรวจสอบว่าถูกปฏิเสธถาวรหรือไม่
      if (await permission.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }

      // ขอสิทธิ์
      return await permission.request();
    } catch (e) {
      log('Error requesting iOS storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// ขอสิทธิ์การเข้าถึงกล้อง
  /// รองรับทั้ง Android และ iOS
  ///
  /// Returns [PermissionStatus] สถานะของการขอสิทธิ์
  static Future<PermissionStatus> requestCameraPermission() async {
    try {
      const permission = Permission.camera;

      // ตรวจสอบว่ามีสิทธิ์อยู่แล้วหรือไม่
      if (await permission.isGranted || await permission.isLimited) {
        return PermissionStatus.granted;
      }

      // ตรวจสอบว่าถูกปฏิเสธถาวรหรือไม่
      if (await permission.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }

      // ขอสิทธิ์
      return await permission.request();
    } catch (e) {
      log('Error requesting camera permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// ตรวจสอบสิทธิ์การเข้าถึงกล้อง
  ///
  /// Returns [bool] true หากมีสิทธิ์, false หากไม่มีสิทธิ์
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (e) {
      log('Error checking camera permission: $e');
      return false;
    }
  }

  /// ตรวจสอบสิทธิ์การเข้าถึงพื้นที่จัดเก็บ
  /// จัดการแยกตามแพลตฟอร์มและเวอร์ชัน SDK
  ///
  /// Returns [bool] true หากมีสิทธิ์, false หากไม่มีสิทธิ์
  static Future<bool> checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await _checkAndroidStoragePermission();
        return status == PermissionStatus.granted || status == PermissionStatus.limited;
      } else if (Platform.isIOS) {
        final status = await _checkIOSStoragePermission();
        return status == PermissionStatus.granted || status == PermissionStatus.limited;
      } else {
        return false;
      }
    } catch (e) {
      log('Error checking storage permission: $e');
      return false;
    }
  }

  /// ตรวจสอบสิทธิ์การเข้าถึงพื้นที่จัดเก็บสำหรับ Android
  static Future<PermissionStatus> _checkAndroidStoragePermission() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      final permission = sdkInt >= 33 ? Permission.photos : Permission.storage;
      return await permission.status;
    } catch (e) {
      log('Error checking Android storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// ตรวจสอบสิทธิ์การเข้าถึงพื้นที่จัดเก็บสำหรับ iOS
  static Future<PermissionStatus> _checkIOSStoragePermission() async {
    try {
      return await Permission.photos.status;
    } catch (e) {
      log('Error checking iOS storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// เปิดหน้าตั้งค่าแอปเพื่อให้ผู้ใช้เปิดสิทธิ์ด้วยตนเอง
  /// ใช้เมื่อสิทธิ์ถูกปฏิเสธถาวร (permanently denied)
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      log('Error opening app settings: $e');
      return false;
    }
  }

  /// ตรวจสอบว่าสิทธิ์ถูกปฏิเสธถาวรหรือไม่
  ///
  /// [permission] สิทธิ์ที่ต้องการตรวจสอบ
  /// Returns [bool] true หากถูกปฏิเสธถาวร
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    try {
      return await permission.isPermanentlyDenied;
    } catch (e) {
      log('Error checking permanently denied status: $e');
      return false;
    }
  }

  /// Helper method สำหรับแสดงข้อความแจ้งเตือนเมื่อต้องเปิดสิทธิ์
  ///
  /// [permissionType] ประเภทของสิทธิ์ (เช่น "กล้อง", "พื้นที่จัดเก็บ")
  /// Returns [String] ข้อความที่แนะนำให้ผู้ใช้
  static String getPermissionMessage(String permissionType) {
    return 'แอปต้องการสิทธิ์การเข้าถึง$permissionType เพื่อใช้งานฟีเจอร์นี้ '
        'กรุณาไปที่การตั้งค่า > สิทธิ์ เพื่อเปิดสิทธิ์';
  }
}