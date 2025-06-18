import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/widget_constants.dart';
import '../../../core/utils/permission_util.dart';
import '../models/media_item_model.dart';

class UniversalMediaDialogSyncfusion extends StatefulWidget {
  const UniversalMediaDialogSyncfusion({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
    this.showThumbnails = true,
    this.enableSwipe = true,
    this.title,
  });

  final List<MediaItemModel> mediaItems;
  final int initialIndex;
  final bool showThumbnails;
  final bool enableSwipe;
  final String? title;

  // Static helper methods
  static Future<void> showSingle({
    required BuildContext context,
    required String url,
    required MediaType type,
    String? title,
    Uint8List? localData
  }) async {
    final mediaItem = MediaItemModel(
      url: url,
      type: type,
      title: title,
      localData: localData,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: UniversalMediaDialogSyncfusion(
          mediaItems: [mediaItem],
          initialIndex: 0,
          showThumbnails: false,
        ),
      ),
    );
  }

  static Future<void> showMultiple({
    required BuildContext context,
    required List<MediaItemModel> mediaItems,
    int initialIndex = 0,
    String? title,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: UniversalMediaDialogSyncfusion(
          mediaItems: mediaItems,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  static Future<void> showFromUrls({
    required BuildContext context,
    required List<String> urls,
    List<String>? titles,
    int initialIndex = 0,
    String? dialogTitle,
  }) async {
    final mediaItems = urls.asMap().entries.map((entry) {
      final index = entry.key;
      final url = entry.value;
      return MediaItemModel(
        url: url,
        type: _detectMediaType(url),
        title: titles != null && titles.length > index ? titles[index] : null,
      );
    }).toList();

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: UniversalMediaDialogSyncfusion(
          mediaItems: mediaItems,
          initialIndex: initialIndex,
          title: dialogTitle,
        ),
      ),
    );
  }

  static MediaType _detectMediaType(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return MediaType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return MediaType.image;
      default:
        return MediaType.image;
    }
  }

  @override
  State<UniversalMediaDialogSyncfusion> createState() => _UniversalMediaDialogSyncfusionState();
}

class _UniversalMediaDialogSyncfusionState extends State<UniversalMediaDialogSyncfusion> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  int _currentRetryAttempt = 0;
  final Map<int, Uint8List?> _pdfBytes = {};
  final Map<int, bool> _downloadingStates = {};

  // Syncfusion PDF Controllers
  final Map<int, PdfViewerController> _pdfControllers = {};

  // Performance optimizations
  final Map<int, bool> _preloadingStates = {};
  final Set<int> _preloadedIndexes = {};
  Timer? _preloadTimer;

  // Thumbnail ListView Controller
  late ScrollController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailController = ScrollController();

    // Initialize PDF controllers
    for (int i = 0; i < widget.mediaItems.length; i++) {
      if (widget.mediaItems[i].type == MediaType.pdf) {
        _pdfControllers[i] = PdfViewerController();
      }
    }

    // Force initial memory cleanup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });

    _preloadCurrentFile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    _preloadTimer?.cancel();

    // Dispose PDF controllers
    for (final controller in _pdfControllers.values) {
      controller.dispose();
    }

    _cleanupTempFiles();
    super.dispose();
  }

  // Cleanup memory และ cache
  Future<void> _cleanupTempFiles() async {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear PDF bytes from memory
      _pdfBytes.clear();

      // Force garbage collection
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          SystemChannels.platform.invokeMethod('System.gc');
        } catch (e) {
          // Ignore if not available
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  Future<void> _preloadCurrentFile() async {
    final currentItem = widget.mediaItems[_currentIndex];

    if (currentItem.hasLocalData && currentItem.type == MediaType.pdf) {
      setState(() {
        _pdfBytes[_currentIndex] = currentItem.localData;
      });
    } else if (currentItem.type == MediaType.pdf) {
      await _downloadPDFWithRetry(_currentIndex);
    }
  }

  Future<void> _downloadPDF(int index) async {
    if (_downloadingStates[index] == true) return;

    setState(() {
      _downloadingStates[index] = true;
      _isLoading = true;
      _error = null;
    });

    try {
      if (!await _checkNetworkConnection()) {
        throw const SocketException('No internet connection. Please check your network settings.');
      }

      final url = widget.mediaItems[index].url;

      final response = await http.get(
        Uri.parse(url),
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
        setState(() {
          _pdfBytes[index] = response.bodyBytes;
          _currentRetryAttempt = 0;
        });
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _downloadingStates[index] = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    final currentItem = widget.mediaItems[_currentIndex];

    try {
      PermissionStatus storagePermission = await PermissionUtil.requestStoragePermission();
      if (!storagePermission.isGranted) {
        _showSnackBar('Storage permission denied');
        return;
      }

      Uint8List bytes;

      if (currentItem.hasLocalData) {
        bytes = currentItem.localData!;
      } else if (currentItem.type == MediaType.pdf && _pdfBytes[_currentIndex] != null) {
        bytes = _pdfBytes[_currentIndex]!;
      } else {
        if (!await _checkNetworkConnection()) {
          throw const SocketException('No internet connection');
        }

        final response = await http.get(Uri.parse(currentItem.url)).timeout(
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

      final fileName = _sanitizeFileName(currentItem.title ?? 'download_${DateTime.now().millisecondsSinceEpoch}');
      final extension = currentItem.url.split('.').last;
      final file = File('${dir.path}/$fileName.$extension');
      await file.writeAsBytes(bytes);

      _showSnackBar('Downloaded to ${file.path}');
    } catch (e) {
      _showSnackBar('Download failed: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _copyLink() async {
    final currentItem = widget.mediaItems[_currentIndex];
    await Clipboard.setData(ClipboardData(text: currentItem.url));
    _showSnackBar('Link copied to clipboard');
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _error = null;
      _currentRetryAttempt = 0;
    });

    // Clear image cache เมื่อเปลี่ยนหน้า
    PaintingBinding.instance.imageCache.clear();

    final currentItem = widget.mediaItems[index];
    if (currentItem.type == MediaType.pdf && _pdfBytes[index] == null) {
      if (currentItem.hasLocalData) {
        setState(() {
          _pdfBytes[index] = currentItem.localData;
        });
      } else {
        _downloadPDFWithRetry(index);
      }
    }

    _schedulePreloading(index);
    _scrollThumbnailToIndex(index);
  }

  void _scrollThumbnailToIndex(int index) {
    if (!widget.showThumbnails || widget.mediaItems.length <= 1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_thumbnailController.hasClients) {
        const itemWidth = 76.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final visibleItems = (screenWidth - 120) / itemWidth;

        final targetPosition = (index * itemWidth) - (visibleItems * itemWidth / 2) + (itemWidth / 2);
        final maxScroll = _thumbnailController.position.maxScrollExtent;
        final clampedPosition = targetPosition.clamp(0.0, maxScroll);

        _thumbnailController.animateTo(
          clampedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _schedulePreloading(int currentIndex) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(milliseconds: 500), () {
      _preloadAdjacentPages(currentIndex);
    });
  }

  Future<void> _preloadAdjacentPages(int currentIndex) async {
    // โหลดแค่หน้าถัดไป เพื่อลด memory usage
    final nextIndex = currentIndex + 1;

    if (nextIndex < widget.mediaItems.length &&
        !_preloadedIndexes.contains(nextIndex) &&
        _downloadingStates[nextIndex] != true &&
        _pdfBytes[nextIndex] == null) {

      final item = widget.mediaItems[nextIndex];
      if (item.type == MediaType.pdf && !item.hasLocalData) {
        _preloadedIndexes.add(nextIndex);
        _preloadPDF(nextIndex);
      }
    }
  }

  Future<void> _preloadPDF(int index) async {
    if (_preloadingStates[index] == true) return;

    _preloadingStates[index] = true;

    try {
      if (!await _checkNetworkConnection()) return;

      final url = widget.mediaItems[index].url;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _pdfBytes[index] = response.bodyBytes;
      }
    } catch (e) {
      // Ignore preload errors
    } finally {
      _preloadingStates[index] = false;
    }
  }

  Widget _buildCurrentMedia() {
    final currentItem = widget.mediaItems[_currentIndex];

    if (_isLoading && _downloadingStates[_currentIndex] == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading...'),
            if (_currentRetryAttempt > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Retry attempt $_currentRetryAttempt/3',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _currentRetryAttempt = 0;
                      });
                      _preloadCurrentFile();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    switch (currentItem.type) {
      case MediaType.pdf:
        final pdfBytes = _pdfBytes[_currentIndex];
        if (pdfBytes != null) {
          return Container(
            // RepaintBoundary สำหรับ performance
            child: RepaintBoundary(
              child: SfPdfViewer.memory(
                pdfBytes,
                controller: _pdfControllers[_currentIndex],
                // Performance settings
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                enableHyperlinkNavigation: false,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                // Callbacks สำหรับ memory management
                onPageChanged: (PdfPageChangedDetails details) {
                  // Clear cache เมื่อเปลี่ยนหน้าใน PDF
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    PaintingBinding.instance.imageCache.clear();
                  });
                },
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  // PDF loaded successfully
                },
                onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                  setState(() {
                    _error = 'Failed to load PDF: ${details.error}';
                  });
                },
                onZoomLevelChanged: (PdfZoomDetails details) {
                  // Handle zoom changes
                },
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }

      case MediaType.image:
        return InteractiveViewer(
          child: Center(
            child: currentItem.hasLocalData
                ? Image.memory(
              currentItem.localData!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Failed to load local image'),
                    ],
                  ),
                );
              },
            )
                : Image.network(
              currentItem.url,
              fit: BoxFit.contain,
              headers: const {
                'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Failed to load image'),
                    ],
                  ),
                );
              },
            ),
          ),
        );
    }
  }

  Widget _buildThumbnailStrip() {
    if (!widget.showThumbnails || widget.mediaItems.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      color: Colors.black54,
      child: Row(
        children: [
          // Previous Button
          Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: _currentIndex > 0 ? _previousPage : null,
              icon: Icon(
                Icons.chevron_left,
                color: _currentIndex > 0 ? Colors.white : Colors.grey,
                size: 32,
              ),
              tooltip: 'Previous',
            ),
          ),

          // Thumbnail ListView
          Expanded(
            child: ListView.builder(
              controller: _thumbnailController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.mediaItems.length,
              cacheExtent: 200,
              itemBuilder: (context, index) {
                final item = widget.mediaItems[index];
                final isSelected = index == _currentIndex;

                final screenWidth = MediaQuery.of(context).size.width;
                final availableWidth = screenWidth - 120;
                final maxItems = 6;
                final minItemWidth = 60.0;
                final calculatedWidth = (availableWidth / maxItems).clamp(minItemWidth, 80.0);

                return GestureDetector(
                  onTap: () => _goToPage(index),
                  child: Container(
                    width: calculatedWidth,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.type == MediaType.image)
                            item.hasLocalData
                                ? Image.memory(
                              item.localData!,
                              fit: BoxFit.cover,
                              cacheWidth: 80,
                              cacheHeight: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, size: 16),
                                );
                              },
                            )
                                : Image.network(
                              item.url,
                              fit: BoxFit.cover,
                              cacheWidth: 80,
                              cacheHeight: 80,
                              headers: const {
                                'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, size: 16),
                                );
                              },
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              child: Icon(
                                item.type == MediaType.pdf ? Icons.picture_as_pdf : Icons.video_library,
                                size: 24,
                              ),
                            ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.type.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Next Button
          Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: _currentIndex < widget.mediaItems.length - 1 ? _nextPage : null,
              icon: Icon(
                Icons.chevron_right,
                color: _currentIndex < widget.mediaItems.length - 1 ? Colors.white : Colors.grey,
                size: 32,
              ),
              tooltip: 'Next',
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.mediaItems.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _checkNetworkConnection() async {
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

  Future<void> _downloadPDFWithRetry(int index, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        setState(() {
          _currentRetryAttempt = attempt;
        });

        await _downloadPDF(index);
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          setState(() {
            _error = 'Failed after $maxRetries attempts:\n${_getErrorMessage(e)}';
            _downloadingStates[index] = false;
            _isLoading = false;
            _currentRetryAttempt = 0;
          });
        } else {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  String _getErrorMessage(dynamic error) {
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

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.mediaItems[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentItem.title ?? 'Media Viewer (Syncfusion)',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.mediaItems.length > 1)
              Text(
                '${_currentIndex + 1} of ${widget.mediaItems.length}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _copyLink,
            tooltip: 'Copy Link',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.enableSwipe && widget.mediaItems.length > 1
                ? PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.mediaItems.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == _currentIndex) {
                  return _buildCurrentMedia();
                } else {
                  return Container();
                }
              },
            )
                : _buildCurrentMedia(),
          ),
          _buildThumbnailStrip(),
        ],
      ),
    );
  }
}

// Extension for easy usage
extension BuildContextExtensionSyncfusion on BuildContext {
  Future<void> showMediaDialogSyncfusion({
    required String url,
    MediaType? type,
    String? title,
    Uint8List? localData,
  }) async {
    await UniversalMediaDialogSyncfusion.showSingle(
      context: this,
      url: url,
      type: type ?? UniversalMediaDialogSyncfusion._detectMediaType(url),
      title: title,
      localData: localData,
    );
  }

  Future<void> showMultipleSyncfusion({
    required List<MediaItemModel> mediaItems,
    int initialIndex = 0,
    String? title,
  }) async {
    await UniversalMediaDialogSyncfusion.showMultiple(
      context: this,
      mediaItems: mediaItems,
      initialIndex: initialIndex,
      title: title,
    );
  }

  Future<void> showMediaGallerySyncfusion({
    required List<String> urls,
    List<String>? titles,
    int initialIndex = 0,
    String? title,
  }) async {
    await UniversalMediaDialogSyncfusion.showFromUrls(
      context: this,
      urls: urls,
      titles: titles,
      initialIndex: initialIndex,
      dialogTitle: title,
    );
  }
}