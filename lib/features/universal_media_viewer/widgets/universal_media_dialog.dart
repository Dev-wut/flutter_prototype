import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/widget_constants.dart';
import '../../../core/utils/permission_util.dart';
import '../models/media_item_model.dart';

class UniversalMediaDialog extends StatefulWidget {
  const UniversalMediaDialog({
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
  }) async {
    final mediaItem = MediaItemModel(url: url, type: type, title: title);

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: UniversalMediaDialog(
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
        child: UniversalMediaDialog(
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
        child: UniversalMediaDialog(
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
  State<UniversalMediaDialog> createState() => _UniversalMediaDialogState();
}

class _UniversalMediaDialogState extends State<UniversalMediaDialog> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  Map<int, String?> _localPaths = {};
  Map<int, bool> _downloadingStates = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadCurrentFile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _preloadCurrentFile() async {
    if (widget.mediaItems[_currentIndex].type == MediaType.pdf) {
      await _downloadPDF(_currentIndex);
    }
  }

  Future<void> _downloadPDF(int index) async {
    if (_downloadingStates[index] == true) return;

    setState(() {
      _downloadingStates[index] = true;
      _isLoading = true;
    });

    try {
      final url = widget.mediaItems[index].url;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_pdf_$index.pdf');
        await file.writeAsBytes(bytes);

        setState(() {
          _localPaths[index] = file.path;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
      });
    } finally {
      setState(() {
        _downloadingStates[index] = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    final currentItem = widget.mediaItems[_currentIndex];

    // Request storage permission
    PermissionStatus storagePermission = await PermissionUtil.requestStoragePermission();
    if (storagePermission.isGranted) {
      try {
        final response = await http.get(Uri.parse(currentItem.url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getExternalStorageDirectory();
          final fileName =
              currentItem.title ??
              'download_${DateTime.now().millisecondsSinceEpoch}';
          final extension = currentItem.url.split('.').last;
          final file = File('${dir!.path}/$fileName.$extension');

          await file.writeAsBytes(bytes);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Downloaded to ${file.path}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _copyLink() async {
    final currentItem = widget.mediaItems[_currentIndex];
    await Clipboard.setData(ClipboardData(text: currentItem.url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Preload PDF if needed
    if (widget.mediaItems[index].type == MediaType.pdf &&
        _localPaths[index] == null) {
      _downloadPDF(index);
    }
  }

  Widget _buildCurrentMedia() {
    final currentItem = widget.mediaItems[_currentIndex];

    if (_isLoading && _downloadingStates[_currentIndex] == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _preloadCurrentFile();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (currentItem.type) {
      case MediaType.pdf:
        final localPath = _localPaths[_currentIndex];
        if (localPath != null) {
          return PDFView(
            filePath: localPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: false,
            onError: (error) {
              setState(() {
                _error = error.toString();
              });
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      case MediaType.image:
        return InteractiveViewer(
          child: Center(
            child: Image.network(
              currentItem.url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          final item = widget.mediaItems[index];
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
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
                      Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[300],
                        child: Icon(
                          item.type == MediaType.pdf
                              ? Icons.picture_as_pdf
                              : Icons.video_library,
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
                          item.type.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
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
    );
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
              currentItem.title ?? 'Media Viewer',
              style: const TextStyle(fontSize: 16),
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
                    itemBuilder: (context, index) {
                      // Only build current page to avoid loading all PDFs at once
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
extension BuildContextExtension on BuildContext {
  Future<void> showMediaDialog({
    required String url,
    MediaType? type,
    String? title,
  }) async {
    await UniversalMediaDialog.showSingle(
      context: this,
      url: url,
      type: type ?? UniversalMediaDialog._detectMediaType(url),
      title: title,
    );
  }


  Future<void> showMultiple({
    required List<MediaItemModel> mediaItems,
    int initialIndex = 0,
    String? title,
  }) async {
    await UniversalMediaDialog.showMultiple(
      context: this,
      mediaItems: mediaItems,
      initialIndex: initialIndex,
      title: title,
    );
  }

  Future<void> showMediaGallery({
    required List<String> urls,
    List<String>? titles,
    int initialIndex = 0,
    String? title,
  }) async {
    await UniversalMediaDialog.showFromUrls(
      context: this,
      urls: urls,
      titles: titles,
      initialIndex: initialIndex,
      dialogTitle: title,
    );
  }
}