// Main export file for Document Viewer package
// Import this file to use all Document Viewer functionality

// Models
export 'models/document_item_model.dart';

// Services
export 'services/document_download_service.dart';

// Widgets
export 'widgets/pdf_viewer_widget.dart';
export 'widgets/thumbnail_strip_widget.dart';
export 'widgets/media_content_widget.dart';

// Dialogs
export 'dialogs/document_viewer_dialog.dart';

// Extensions
export 'extensions/document_viewer_extensions.dart';

/*
Usage Examples:

1. Single Document:
```dart
import 'package:your_app/document_viewer/document_viewer.dart';

// In your widget:
await context.openSingleDocument(
  url: 'https://example.com/file.pdf',
  type: DocumentItemType.pdf,
  title: 'Document Title',
);
```

2. Multiple Document:
```dart
final mediaItems = [
  DocumentItemModel(
    url: 'https://example.com/image1.jpg',
    type: DocumentItemType.image,
    title: 'Image 1',
  ),
  DocumentItemModel(
    url: 'https://example.com/document.pdf',
    type: DocumentItemType.pdf,
    title: 'Document',
  ),
];

await context.openMultipleDocument(
  mediaItems: mediaItems,
  initialIndex: 0,
);
```

3. From URLs:
```dart
final urls = [
  'https://example.com/image1.jpg',
  'https://example.com/document.pdf',
  'https://example.com/image2.png',
];

await context.openMultipleDocumentsByLinks(
  urls: urls,
  titles: ['Image 1', 'Document', 'Image 2'],
);
```

4. With Local Data:
```dart
await context.openSingleDocuments(
  url: '', // Can be empty when using local data
  type: DocumentsItemType.pdf,
  title: 'Local PDF',
  localData: pdfBytes, // Uint8List
);
```
*/