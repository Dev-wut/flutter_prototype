import 'package:flutter/material.dart';

import '../../core/constants/widget_constants.dart';
import '../../shared/widgets/custom_padding.dart';
import 'models/media_item_model.dart';
import 'widgets/universal_media_dialog.dart';

class UniversalMediaViewer extends StatefulWidget {
  const UniversalMediaViewer({super.key});

  @override
  State<UniversalMediaViewer> createState() => _UniversalMediaViewerState();
}

class _UniversalMediaViewerState extends State<UniversalMediaViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("UniversalMediaViewer")),
      body: SafeArea(
        child: CustomPadding(
          child: Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.showMediaDialog(
                      url: 'https://ontheline.trincoll.edu/images/bookdown/sample-local-pdf.pdf',
                      type: MediaType.pdf,
                      title: 'Document',
                    );
                  },
                  child: Text('PDF Single View'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.showMediaDialog(
                      url: 'https://images.unsplash.com/photo-1749847850294-19c4f59bf3f9?q=80&w=1986&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                      type: MediaType.image,
                      title: 'Document',
                    );
                  },
                  child: Text('Image Single View'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.showMultiple(
                      mediaItems: [
                        MediaItemModel(
                          url: 'https://images.unsplash.com/photo-1744124371841-d2723e438bdf?q=80&w=1976&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                          type: MediaType.image,
                          title: 'Image 1',
                        ),
                        MediaItemModel(
                          url: 'https://ontheline.trincoll.edu/images/bookdown/sample-local-pdf.pdf',
                          type: MediaType.pdf,
                          title: 'Doc 1',
                        ),
                        MediaItemModel(
                          url: 'https://images.unsplash.com/photo-1746469535771-71a672e8719f?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                          type: MediaType.image,
                          title: 'Image 2',
                        ),
                      ],
                      initialIndex: 0,
                    );
                  },
                  child: Text('Multiple Views'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: null,
                  child: Text('Video View Coming Soon'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
