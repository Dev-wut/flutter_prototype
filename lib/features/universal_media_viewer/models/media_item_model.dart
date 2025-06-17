import 'dart:typed_data';

import '../../../core/constants/widget_constants.dart';

class MediaItemModel {
  final String url;
  final MediaType type;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final Uint8List? localData;

  MediaItemModel({
    required this.url,
    required this.type,
    this.title,
    this.description,
    this.metadata,
    this.localData,
  });

  // Helper method to check if local data is available
  bool get hasLocalData => localData != null;
}