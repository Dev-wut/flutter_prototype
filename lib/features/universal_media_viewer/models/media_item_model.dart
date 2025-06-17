import 'dart:typed_data';

import '../../../core/constants/widget_constants.dart';

class MediaItemModel {
  final String url;
  final Uint8List? localData;
  final MediaType type;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;

  MediaItemModel({
    required this.url,
    required this.type,
    this.title,
    this.description,
    this.metadata,
    this.localData,
  });
}