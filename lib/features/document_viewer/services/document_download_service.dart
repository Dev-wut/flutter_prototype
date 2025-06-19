import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/permission_util.dart';
import '../models/document_item_model.dart';

class DocumentDownloadService {
  static final Map<int, String?> _localPaths = {};
  static final Map<int, bool> _downloadingStates = {};
  static final Map<int, bool> _preloadingStates = {};
  static final Set<int> _preloadedIndexes = {};

  // Getters for external access
  static Map<int, String?> get localPaths => _localPaths;
  static Map<int, bool> get downloadingStates => _downloadingStates;

  // Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final dir = await getTemporaryDirectory();
      final tempFiles = await dir.list().where((file) =>
      file.path.contains('temp_pdf_') && file.path.endsWith('.pdf')
      ).toList();

      for (final file in tempFiles) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // Save PDF from local data
  static Future<void> savePDFFromLocalData(
      int index,
      DocumentItemModel item,
      Function(VoidCallback) setState,
      ) async {
    if (_downloadingStates[index] == true || !item.hasLocalData) return;

    setState(() {
      _downloadingStates[index] = true;
    });

    try {
      final localData = item.localData!;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_pdf_local_$index.pdf');
      await file.writeAsBytes(localData);

      _localPaths[index] = file.path;
    } catch (e) {
      throw Exception('Failed to save local PDF: $e');
    } finally {
      setState(() {
        _downloadingStates[index] = false;
      });
    }
  }

  // Download PDF with retry mechanism
  static Future<void> downloadPDFWithRetry(
      int index,
      DocumentItemModel item,
      Function(VoidCallback) setState, {
        int maxRetries = 3,
      }) async {
    int currentRetryAttempt = 0;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        setState(() {
          currentRetryAttempt = attempt;
        });

        await _downloadPDF(index, item, setState);
        return; // Success
      } catch (e) {
        if (attempt == maxRetries) {
          // Max retries reached
          setState(() {
            _downloadingStates[index] = false;
            currentRetryAttempt = 0;
          });
          throw Exception('Failed after $maxRetries attempts:\n${_getErrorMessage(e)}');
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  // Internal download method
  static Future<void> _downloadPDF(
      int index,
      DocumentItemModel item,
      Function(VoidCallback) setState,
      ) async {
    if (_downloadingStates[index] == true) return;

    setState(() {
      _downloadingStates[index] = true;
    });

    try {
      // Check network connection
      if (!await _checkNetworkConnection()) {
        throw const SocketException('No internet connection. Please check your network settings.');
      }

      final response = await http.get(
        Uri.parse(item.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Connection timeout after 30 seconds',
          const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_pdf_$index.pdf');
        await file.writeAsBytes(bytes);

        _localPaths[index] = file.path;
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _downloadingStates[index] = false;
      });
    }
  }

  // Background preloading for smooth navigation
  static Future<void> preloadPDF(int index, DocumentItemModel item) async {
    if (_preloadingStates[index] == true ||
        _preloadedIndexes.contains(index) ||
        _localPaths[index] != null) return;

    _preloadingStates[index] = true;
    _preloadedIndexes.add(index);

    try {
      if (!await _checkNetworkConnection()) return;

      final response = await http.get(
        Uri.parse(item.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_pdf_preload_$index.pdf');
        await file.writeAsBytes(bytes);

        _localPaths[index] = file.path;
      }
    } catch (e) {
      // Ignore preload errors
    } finally {
      _preloadingStates[index] = false;
    }
  }

  // Download file to external storage
  static Future<void> downloadFileToStorage(
      DocumentItemModel item,
      BuildContext context,
      ) async {
    try {
      // Request storage permission
      PermissionStatus storagePermission = await PermissionUtil.requestStoragePermission();
      if (!storagePermission.isGranted && context.mounted) {
        _showSnackBar(context, 'Storage permission denied');
        return;
      }

      Uint8List bytes;

      // Use local data first if available
      if (item.hasLocalData) {
        bytes = item.localData!;
      } else {
        if (!await _checkNetworkConnection()) {
          throw const SocketException('No internet connection');
        }

        final response = await http.get(Uri.parse(item.url)).timeout(
          const Duration(seconds: 60),
        );

        if (response.statusCode != 200) {
          throw HttpException('Failed to download file: HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('Cannot access external storage');
      }

      final fileName = _sanitizeFileName(item.title ?? 'download_${DateTime.now().millisecondsSinceEpoch}');
      final extension = item.url.split('.').last;
      final file = File('${dir.path}/$fileName.$extension');
      await file.writeAsBytes(bytes);

      _showSnackBar(context, 'Downloaded to ${file.path}');
    } catch (e) {
      _showSnackBar(context, 'Download failed: $e');
    }
  }

  // Copy link to clipboard
  static Future<void> copyLink(DocumentItemModel item, BuildContext context) async {
    if (item.url.isEmpty) {
      _showWarningSnackBar(context, 'ไม่มีลิงก์สำหรับคัดลอก');
      return;
    }
    await Clipboard.setData(ClipboardData(text: item.url));
    _showSnackBar(context, 'คัดลอกลิงก์ไปยังคลิปบอร์ดเรียบร้อย');
  }

  // Helper methods
  static Future<bool> _checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error is TimeoutException) {
      return 'Connection timeout. Please try again.';
    } else if (error is HttpException) {
      return 'Server error: ${error.message}';
    } else {
      return error.toString();
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    // Messages.info(message).show(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  static void _showWarningSnackBar(BuildContext context, String message) {
    // Messages.warn(message).show(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Clear all cached data
  static void clearCache() {
    _localPaths.clear();
    _downloadingStates.clear();
    _preloadingStates.clear();
    _preloadedIndexes.clear();
  }
}