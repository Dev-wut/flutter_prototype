import 'dart:typed_data';

enum DocumentItemType { pdf, image }

class DocumentItemModel {
  final String url;
  final DocumentItemType type;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final Uint8List? localData;

  DocumentItemModel({
    required this.url,
    required this.type,
    this.title,
    this.description,
    this.metadata,
    this.localData,
  });

  // Helper method to check if local data is available
  bool get hasLocalData => localData != null;

  // Helper method to detect media type from URL
  static DocumentItemType detectMediaType(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return DocumentItemType.pdf;
      default:
        return DocumentItemType.image;
    }
  }
}