import 'package:go_router/go_router.dart';

import '../../features/document_viewer/document_page.dart';
import '../../features/home/home_page.dart';
import '../../features/universal_media_viewer/universal_media_viewer.dart';

enum AppRoutes {
  initial(name: 'initial', path: '/initial'),
  universalMediaViewer(
    name: 'universalMediaViewer',
    path: '/universalMediaViewer',
  ),
  mediaViewer(name: 'mediaViewer', path: '/mediaViewer');

  final String name;
  final String path;

  const AppRoutes({required this.name, required this.path});
}

final class RouteConfig {
  static GoRouter get router => _routes;

  static final _routes = GoRouter(
    initialLocation: AppRoutes.initial.path,
    routes: [
      GoRoute(
        name: AppRoutes.initial.name,
        path: AppRoutes.initial.path,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: AppRoutes.universalMediaViewer.name,
        path: AppRoutes.universalMediaViewer.path,
        builder: (context, state) => const UniversalMediaViewer(),
      ),
      GoRoute(
        name: AppRoutes.mediaViewer.name,
        path: AppRoutes.mediaViewer.path,
        builder: (context, state) => const DocumentPage(),
      ),
    ],
  );
}
