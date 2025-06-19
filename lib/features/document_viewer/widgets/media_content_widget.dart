import 'package:flutter/material.dart';
import '../models/document_item_model.dart';
import '../services/document_download_service.dart';
import 'pdf_viewer_widget.dart';

class MediaContentWidget extends StatelessWidget {
  const MediaContentWidget({
    super.key,
    required this.mediaItem,
    required this.index,
    required this.isLoading,
    required this.error,
    required this.currentRetryAttempt,
    required this.onRetry,
    required this.onClose,
    this.showPDFNavigation = true,
    this.showPDFPageInfo = true,
  });

  final DocumentItemModel mediaItem;
  final int index;
  final bool isLoading;
  final String? error;
  final int currentRetryAttempt;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final bool showPDFNavigation;
  final bool showPDFPageInfo;

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading && DocumentDownloadService.downloadingStates[index] == true) {
      return _buildLoadingWidget();
    }

    // Show error state
    if (error != null) {
      return _buildErrorWidget();
    }

    // Show media content
    return _buildMediaContent();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading...'),
          if (currentRetryAttempt > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Retry attempt $currentRetryAttempt/3',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: onClose,
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (mediaItem.type) {
      case DocumentItemType.pdf:
        return _buildPDFContent();
      case DocumentItemType.image:
        return _buildImageContent();
    }
  }

  Widget _buildPDFContent() {
    final localPath = DocumentDownloadService.localPaths[index];

    if (localPath != null) {
      return PDFViewerWidget(
        filePath: localPath,
        showPageInfo: showPDFPageInfo,
        showNavigation: showPDFNavigation,
        onError: (error) {
          // Handle PDF-specific errors if needed
        },
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildImageContent() {
    return InteractiveViewer(
      child: Center(
        child: mediaItem.hasLocalData
            ? Image.memory(
          mediaItem.localData!,
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
          mediaItem.url,
          fit: BoxFit.contain,
          headers: const {
            'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          },
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