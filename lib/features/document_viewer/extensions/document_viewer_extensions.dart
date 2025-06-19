import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../dialogs/document_viewer_dialog.dart';
import '../models/document_item_model.dart';

// Extension for easy usage
extension BuildContextExtension on BuildContext {
  Future<void> openSingleDocument({
    required String url,
    DocumentItemType? type,
    String? title,
    Uint8List? localData,
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    await DocumentViewerDialog.showSingle(
      context: this,
      url: url,
      type: type ?? DocumentItemModel.detectMediaType(url),
      title: title,
      localData: localData,
      showPDFNavigation: showPDFNavigation,
      showPDFPageInfo: showPDFPageInfo,
    );
  }

  Future<void> openMultipleDocument({
    required List<DocumentItemModel> mediaItems,
    int initialIndex = 0,
    String? title,
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    await DocumentViewerDialog.showMultiple(
      context: this,
      mediaItems: mediaItems,
      initialIndex: initialIndex,
      title: title,
      showPDFNavigation: showPDFNavigation,
      showPDFPageInfo: showPDFPageInfo,
    );
  }

  Future<void> openMultipleDocumentByLinks({
    required List<String> urls,
    List<String>? titles,
    int initialIndex = 0,
    String? title,
    bool showPDFNavigation = true,
    bool showPDFPageInfo = true,
  }) async {
    await DocumentViewerDialog.showFromUrls(
      context: this,
      urls: urls,
      titles: titles,
      initialIndex: initialIndex,
      dialogTitle: title,
      showPDFNavigation: showPDFNavigation,
      showPDFPageInfo: showPDFPageInfo,
    );
  }
}