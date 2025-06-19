import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerWidget extends StatefulWidget {
  const PDFViewerWidget({
    super.key,
    required this.filePath,
    this.showPageInfo = true,
    this.showNavigation = true,
    this.onPageChanged,
    this.onError,
  });

  final String filePath;
  final bool showPageInfo;
  final bool showNavigation;
  final Function(int currentPage, int totalPages)? onPageChanged;
  final Function(String error)? onError;

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  int _currentPDFPage = 1;
  int _totalPDFPages = 0;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF Viewer
        PDFView(
          filePath: widget.filePath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
          onRender: (pages) {
            setState(() {
              _totalPDFPages = pages ?? 0;
            });
            if (widget.onPageChanged != null) {
              widget.onPageChanged!(_currentPDFPage, _totalPDFPages);
            }
          },
          onViewCreated: (PDFViewController pdfViewController) {
            _pdfViewController = pdfViewController;
          },
          onPageChanged: (page, total) {
            setState(() {
              _currentPDFPage = (page ?? 0) + 1; // PDF pages start from 0
              _totalPDFPages = total ?? 0;
            });
            if (widget.onPageChanged != null) {
              widget.onPageChanged!(_currentPDFPage, _totalPDFPages);
            }
          },
          onError: (error) {
            if (widget.onError != null) {
              widget.onError!('PDF Error: $error');
            }
          },
          onPageError: (page, error) {
            if (widget.onError != null) {
              widget.onError!('PDF Page $page Error: $error');
            }
          },
        ),

        // PDF Page Info
        if (widget.showPageInfo && _totalPDFPages > 0)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$_currentPDFPage / $_totalPDFPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // PDF Navigation Controls
        if (widget.showNavigation && _totalPDFPages > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _currentPDFPage > 1 ? _previousPDFPage : null,
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: _currentPDFPage > 1 ? Colors.white : Colors.grey,
                    ),
                    tooltip: 'Previous Page',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_currentPDFPage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: _currentPDFPage < _totalPDFPages ? _nextPDFPage : null,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _currentPDFPage < _totalPDFPages ? Colors.white : Colors.grey,
                    ),
                    tooltip: 'Next Page',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _previousPDFPage() {
    if (_pdfViewController != null && _currentPDFPage > 1) {
      _pdfViewController!.setPage(_currentPDFPage - 2); // PDF pages start from 0
    }
  }

  void _nextPDFPage() {
    if (_pdfViewController != null && _currentPDFPage < _totalPDFPages) {
      _pdfViewController!.setPage(_currentPDFPage); // PDF pages start from 0
    }
  }

  // Public methods to control PDF externally
  void goToPage(int page) {
    if (_pdfViewController != null && page >= 1 && page <= _totalPDFPages) {
      _pdfViewController!.setPage(page - 1); // PDF pages start from 0
    }
  }

  void nextPage() => _nextPDFPage();
  void previousPage() => _previousPDFPage();

  // Getters
  int get currentPage => _currentPDFPage;
  int get totalPages => _totalPDFPages;
  bool get hasMultiplePages => _totalPDFPages > 1;
}