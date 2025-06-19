import 'package:flutter/material.dart';
import 'package:flutter_prototype/core/config/route_config.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/custom_padding.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    final featureList = <String, String>{
      AppRoutes.universalMediaViewer.name : "Universal Media Viewer",
      AppRoutes.mediaViewer.name : "Media Viewer",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Prototype'),
      ),
      body: Column(
        children: [
          Text(
            'Welcome, Flutter Prototype!',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: CustomPadding(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: featureList.length,
                  itemBuilder: (context, index) {
                    final entry = featureList.entries.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.pushNamed(entry.key);
                        },
                        child: Text(entry.value),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}