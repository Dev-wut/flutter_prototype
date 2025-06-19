import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/document_item_model.dart';
import '../services/document_download_service.dart';
import '../widgets/media_content_widget.dart';
import '../widgets/thumbnail_strip_widget.dart';

class DocumentViewerDialog extends StatefulWidget {
  const DocumentViewerDialog({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
    this.showThumbnails = true,
    this.enableSwipe = true,
    this.title,
    this.showPDFNavigation = true,
    this.showPDFPageInfo = true,
  });

  final List<DocumentItemModel> mediaItems;
  final int initialIndex;
  final bool showThumbnails;
  final bool enableSwipe;
  final String? title;
  final bool showPDFNavigation;
  final bool showPDFPageInfo;

  // Static helper methods
  static Future<void> showSingle({
    required BuildContext context,
    required String url,
    required DocumentItemType type,
    String? title,
    Uint8List? localData,
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    final mediaItem = DocumentItemModel(
      url: url,
      type: type,
      title: title,
      localData: localData,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: DocumentViewerDialog(
          mediaItems: [mediaItem],
          initialIndex: 0,
          showThumbnails: false,
          showPDFNavigation: showPDFNavigation,
          showPDFPageInfo: showPDFPageInfo,
        ),
      ),
    );
  }

  static Future<void> showMultiple({
    required BuildContext context,
    required List<DocumentItemModel> mediaItems,
    int initialIndex = 0,
    String? title,
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: DocumentViewerDialog(
          mediaItems: mediaItems,
          initialIndex: initialIndex,
          title: title,
          showPDFNavigation: showPDFNavigation,
          showPDFPageInfo: showPDFPageInfo,
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
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    final mediaItems = urls.asMap().entries.map((entry) {
      final index = entry.key;
      final url = entry.value;
      return DocumentItemModel(
        url: url,
        type: DocumentItemModel.detectMediaType(url),
        title: titles != null && titles.length > index ? titles[index] : null,
      );
    }).toList();

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: DocumentViewerDialog(
          mediaItems: mediaItems,
          initialIndex: initialIndex,
          title: dialogTitle,
          showPDFNavigation: showPDFNavigation,
          showPDFPageInfo: showPDFPageInfo,
        ),
      ),
    );
  }

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  int _currentRetryAttempt = 0;

  // Performance optimizations
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    _setInitialOrientation();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadCurrentFile();
  }

  @override
  void dispose() {
    _disposeInitialOrientation();
    _pageController.dispose();
    _preloadTimer?.cancel();
    DocumentDownloadService.cleanupTempFiles();
    super.dispose();
  }

  Future<void> _setInitialOrientation() async {
    // Set orientation preferences if needed
    // Commented out to allow all orientations
  }

  Future<void> _disposeInitialOrientation() async {
    // Reset orientation preferences if needed
    // Commented out to maintain flexibility
  }

  Future<void> _preloadCurrentFile() async {
    final currentItem = widget.mediaItems[_currentIndex];

    if (currentItem.hasLocalData && currentItem.type == DocumentItemType.pdf) {
      await _savePDFFromLocalData(_currentIndex);
    } else if (currentItem.type == DocumentItemType.pdf) {
      await _downloadPDFWithRetry(_currentIndex);
    }
  }

  Future<void> _savePDFFromLocalData(int index) async {
    try {
      await DocumentDownloadService.savePDFFromLocalData(
        index,
        widget.mediaItems[index],
        setState,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPDFWithRetry(int index) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await DocumentDownloadService.downloadPDFWithRetry(
        index,
        widget.mediaItems[index],
        (callback) => setState(callback),
      );

      setState(() {
        _isLoading = false;
        _currentRetryAttempt = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _currentRetryAttempt = 0;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _error = null;
      _currentRetryAttempt = 0;
    });

    // Clear image cache when changing pages
    PaintingBinding.instance.imageCache.clear();

    final currentItem = widget.mediaItems[index];
    if (currentItem.type == DocumentItemType.pdf &&
        DocumentDownloadService.localPaths[index] == null) {
      if (currentItem.hasLocalData) {
        _savePDFFromLocalData(index);
      } else {
        _downloadPDFWithRetry(index);
      }
    }

    // Preload adjacent pages
    _schedulePreloading(index);
  }

  void _schedulePreloading(int currentIndex) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(milliseconds: 500), () {
      _preloadAdjacentPages(currentIndex);
    });
  }

  Future<void> _preloadAdjacentPages(int currentIndex) async {
    final preloadIndexes = <int>[];

    // Preload previous page
    if (currentIndex > 0) {
      preloadIndexes.add(currentIndex - 1);
    }

    // Preload next page
    if (currentIndex < widget.mediaItems.length - 1) {
      preloadIndexes.add(currentIndex + 1);
    }

    for (final index in preloadIndexes) {
      final item = widget.mediaItems[index];
      if (item.type == DocumentItemType.pdf &&
          !item.hasLocalData &&
          DocumentDownloadService.localPaths[index] == null) {
        DocumentDownloadService.preloadPDF(index, item);
      }
    }
  }

  // Navigation methods
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

  void _handleRetry() {
    setState(() {
      _error = null;
      _currentRetryAttempt = 0;
    });
    _preloadCurrentFile();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.mediaItems[_currentIndex];

    return Scaffold(
      // backgroundColor: AppThemeData.white,
      backgroundColor: Colors.black,
      appBar: AppBar(
        // backgroundColor: AppThemeData.deepOrange,
        // foregroundColor: AppThemeData.white,
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentItem.title ?? 'Media Viewer',
              // style: TextStyle(fontSize: SizeUtil.sp(20)),
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.mediaItems.length > 1)
              Text(
                '${_currentIndex + 1} of ${widget.mediaItems.length}',
                // style: TextStyle(fontSize: SizeUtil.sp(18), color: Colors.white70),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => DocumentDownloadService.copyLink(currentItem, context),
            tooltip: 'คัดลอกลิงก์',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => DocumentDownloadService.downloadFileToStorage(
              currentItem,
              context,
            ),
            tooltip: 'ดาวน์โหลด',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'ปิด',
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
                      // Only build current page for performance
                      if (index == _currentIndex) {
                        return MediaContentWidget(
                          mediaItem: currentItem,
                          index: _currentIndex,
                          isLoading: _isLoading,
                          error: _error,
                          currentRetryAttempt: _currentRetryAttempt,
                          onRetry: _handleRetry,
                          onClose: () => Navigator.of(context).pop(),
                          showPDFNavigation: widget.showPDFNavigation,
                          showPDFPageInfo: widget.showPDFPageInfo,
                        );
                      } else {
                        return Container();
                      }
                    },
                  )
                : MediaContentWidget(
                    mediaItem: currentItem,
                    index: _currentIndex,
                    isLoading: _isLoading,
                    error: _error,
                    currentRetryAttempt: _currentRetryAttempt,
                    onRetry: _handleRetry,
                    onClose: () => Navigator.of(context).pop(),
                    showPDFNavigation: widget.showPDFNavigation,
                    showPDFPageInfo: widget.showPDFPageInfo,
                  ),
          ),
          ThumbnailStripWidget(
            mediaItems: widget.mediaItems,
            currentIndex: _currentIndex,
            onThumbnailTap: _goToPage,
            onPrevious: _currentIndex > 0 ? _previousPage : null,
            onNext: _currentIndex < widget.mediaItems.length - 1
                ? _nextPage
                : null,
            showThumbnails: widget.showThumbnails,
          ),
        ],
      ),
    );
  }
}
