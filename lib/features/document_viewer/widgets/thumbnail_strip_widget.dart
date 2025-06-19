import 'package:flutter/material.dart';
import '../models/document_item_model.dart';

class ThumbnailStripWidget extends StatefulWidget {
  const ThumbnailStripWidget({
    super.key,
    required this.mediaItems,
    required this.currentIndex,
    required this.onThumbnailTap,
    required this.onPrevious,
    required this.onNext,
    this.showThumbnails = true,
  });

  final List<DocumentItemModel> mediaItems;
  final int currentIndex;
  final Function(int index) onThumbnailTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showThumbnails;

  @override
  State<ThumbnailStripWidget> createState() => _ThumbnailStripWidgetState();
}

class _ThumbnailStripWidgetState extends State<ThumbnailStripWidget> {
  late ScrollController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _thumbnailController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentIndex();
    });
  }

  @override
  void didUpdateWidget(ThumbnailStripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrentIndex();
    }
  }

  @override
  void dispose() {
    _thumbnailController.dispose();
    super.dispose();
  }

  void _scrollToCurrentIndex() {
    if (!widget.showThumbnails || widget.mediaItems.length <= 1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_thumbnailController.hasClients) {
        const itemWidth = 76.0; // 60 + 16 margin
        final screenWidth = MediaQuery.of(context).size.width;
        final visibleItems = (screenWidth - 120) / itemWidth; // -120 for prev/next buttons

        // Calculate position to center current item
        final targetPosition = (widget.currentIndex * itemWidth) -
            (visibleItems * itemWidth / 2) +
            (itemWidth / 2);
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

  @override
  Widget build(BuildContext context) {
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
              onPressed: widget.onPrevious,
              icon: Icon(
                Icons.chevron_left,
                color: widget.onPrevious != null ? Colors.white : Colors.grey,
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
                return _buildThumbnailItem(index);
              },
            ),
          ),

          // Next Button
          Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: widget.onNext,
              icon: Icon(
                Icons.chevron_right,
                color: widget.onNext != null ? Colors.white : Colors.grey,
                size: 32,
              ),
              tooltip: 'Next',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailItem(int index) {
    final item = widget.mediaItems[index];
    final isSelected = index == widget.currentIndex;

    // Calculate thumbnail size based on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 120; // minus prev/next buttons
    const maxItems = 6;
    const minItemWidth = 60.0;
    final calculatedWidth = (availableWidth / maxItems).clamp(minItemWidth, 80.0);

    return GestureDetector(
      onTap: () => widget.onThumbnailTap(index),
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
              _buildThumbnailContent(item),
              _buildMediaTypeLabel(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(DocumentItemModel item) {
    if (item.type == DocumentItemType.image) {
      if (item.hasLocalData) {
        return Image.memory(
          item.localData!,
          fit: BoxFit.cover,
          cacheWidth: 80,
          cacheHeight: 80,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorThumbnail();
          },
        );
      } else {
        return Image.network(
          item.url,
          fit: BoxFit.cover,
          cacheWidth: 80,
          cacheHeight: 80,
          headers: const {
            'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingThumbnail();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorThumbnail();
          },
        );
      }
    } else {
      // PDF or other file types
      return Container(
        color: Colors.grey[300],
        child: Icon(
          item.type == DocumentItemType.pdf ? Icons.picture_as_pdf : Icons.video_library,
          size: 24,
        ),
      );
    }
  }

  Widget _buildMediaTypeLabel(DocumentItemModel item) {
    return Positioned(
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
    );
  }

  Widget _buildLoadingThumbnail() {
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
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.error, size: 16),
    );
  }
}