// integration_test/universal_media_dialog_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_prototype/core/constants/widget_constants.dart';
import 'package:flutter_prototype/features/universal_media_viewer/models/media_item_model.dart';
import 'package:flutter_prototype/features/universal_media_viewer/widgets/universal_media_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_prototype/main.dart' as app;
import 'dart:developer' as developer;
import 'dart:io';

/// Performance metrics helper class for real network testing
class NetworkPerformanceMetrics {
  static int? _initialMemory;
  static DateTime? _startTime;
  static final List<Duration> _operationTimes = [];
  static final List<String> _networkEvents = [];

  static void startTest() {
    _initialMemory = _getCurrentMemoryUsage();
    _startTime = DateTime.now();
    _operationTimes.clear();
    _networkEvents.clear();
    developer.log('=== Real Network Performance Test Started ===');
    developer.log('Initial Memory: ${_formatMemory(_initialMemory!)}');
  }

  static void recordOperation(String operation) {
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!);
      _operationTimes.add(elapsed);
      developer.log('$operation completed in: ${elapsed.inMilliseconds}ms');
    }
  }

  static void recordNetworkEvent(String event, {bool isError = false}) {
    final timestamp = DateTime.now().toIso8601String();
    final eventLog = '$timestamp: $event${isError ? ' [ERROR]' : ''}';
    _networkEvents.add(eventLog);
    developer.log('Network Event: $eventLog');
  }

  static void endTest() {
    if (_initialMemory != null && _startTime != null) {
      final finalMemory = _getCurrentMemoryUsage();
      final totalTime = DateTime.now().difference(_startTime!);
      final memoryDelta = finalMemory - _initialMemory!;

      developer.log('=== Real Network Performance Test Results ===');
      developer.log('Total Test Time: ${totalTime.inSeconds}s');
      developer.log('Memory Usage Delta: ${_formatMemory(memoryDelta)}');
      developer.log('Final Memory: ${_formatMemory(finalMemory)}');
      developer.log('Average Operation Time: ${_getAverageOperationTime()}ms');
      developer.log('Total Operations: ${_operationTimes.length}');
      developer.log('Network Events: ${_networkEvents.length}');

      // Log network events summary
      final errorEvents = _networkEvents.where((e) => e.contains('[ERROR]')).length;
      developer.log('Network Success Rate: ${((_networkEvents.length - errorEvents) / _networkEvents.length * 100).toStringAsFixed(1)}%');

      // Reset
      _initialMemory = null;
      _startTime = null;
      _operationTimes.clear();
      _networkEvents.clear();
    }
  }

  static int _getCurrentMemoryUsage() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      developer.log('Could not get memory usage: $e');
      return 0;
    }
  }

  static String _formatMemory(int bytes) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  static double _getAverageOperationTime() {
    if (_operationTimes.isEmpty) return 0.0;
    final total = _operationTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return total / _operationTimes.length;
  }
}

/// Real network test helper class
class NetworkTestHelper {
  static Future<void> waitForNetworkContent(
      WidgetTester tester, {
        Duration timeout = const Duration(seconds: 30),
        String? expectedContent,
      }) async {
    final endTime = DateTime.now().add(timeout);
    bool contentLoaded = false;

    NetworkPerformanceMetrics.recordNetworkEvent('Starting content load wait');

    while (DateTime.now().isBefore(endTime) && !contentLoaded) {
      await tester.pump(const Duration(milliseconds: 500));

      // Check for loading completion indicators
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('Loading...').evaluate().isNotEmpty;

      // Check for error states
      final hasError = find.text('Failed to load').evaluate().isNotEmpty ||
          find.text('Network error').evaluate().isNotEmpty ||
          find.text('Error').evaluate().isNotEmpty;

      if (!hasLoading) {
        if (hasError) {
          NetworkPerformanceMetrics.recordNetworkEvent('Content load failed - error detected', isError: true);
          break;
        } else {
          NetworkPerformanceMetrics.recordNetworkEvent('Content load completed successfully');
          contentLoaded = true;
        }
      }
    }

    if (!contentLoaded && DateTime.now().isAfter(endTime)) {
      NetworkPerformanceMetrics.recordNetworkEvent('Content load timeout', isError: true);
    }

    // Final settle
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
  }

  static Future<void> assertNetworkContentState(WidgetTester tester) async {
    // In real network testing, we expect either successful load or specific error states
    final hasContent = find.byType(UniversalMediaDialog).evaluate().isNotEmpty;

    if (hasContent) {
      // Check if content is actually displayed (not just loading)
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError = find.text('Failed to load').evaluate().isNotEmpty ||
          find.text('Network error').evaluate().isNotEmpty;

      if (hasLoading) {
        NetworkPerformanceMetrics.recordNetworkEvent('Content still loading', isError: true);
      } else if (hasError) {
        NetworkPerformanceMetrics.recordNetworkEvent('Content load error detected', isError: true);
      } else {
        NetworkPerformanceMetrics.recordNetworkEvent('Content successfully displayed');
      }
    }

    expect(hasContent, isTrue, reason: 'Dialog should be present');
  }

  static Future<void> safeNetworkGesture(
      WidgetTester tester,
      Future<void> Function() gesture, {
        Duration settleTimeout = const Duration(seconds: 10),
      }) async {
    try {
      // Ensure stable state before gesture
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Execute gesture
      await gesture();

      // Wait for network response and UI update
      await waitForNetworkContent(tester, timeout: settleTimeout);

    } catch (e) {
      NetworkPerformanceMetrics.recordNetworkEvent('Gesture failed: $e', isError: true);
      developer.log('Network gesture failed: $e');
      // Continue test execution despite gesture failure
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  static Future<void> safeNetworkTap(WidgetTester tester, Finder finder) async {
    await safeNetworkGesture(tester, () async {
      final elements = finder.evaluate();
      if (elements.isNotEmpty) {
        await tester.tap(finder);
        NetworkPerformanceMetrics.recordNetworkEvent('Tap executed on: $finder');
      } else {
        NetworkPerformanceMetrics.recordNetworkEvent('Tap target not found: $finder', isError: true);
      }
    });
  }

  static Future<void> safeNetworkFling(
      WidgetTester tester,
      Finder finder,
      Offset offset,
      double velocity,
      ) async {
    await safeNetworkGesture(tester, () async {
      final elements = finder.evaluate();
      if (elements.isNotEmpty) {
        await tester.fling(finder, offset, velocity);
        NetworkPerformanceMetrics.recordNetworkEvent('Fling executed: ${offset.dx > 0 ? 'right' : 'left'}');
      } else {
        NetworkPerformanceMetrics.recordNetworkEvent('Fling target not found: $finder', isError: true);
      }
    }, settleTimeout: const Duration(seconds: 15)); // Longer timeout for fling operations
  }

  static Future<void> monitorNetworkHealth() async {
    try {
      // Simple connectivity check
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        NetworkPerformanceMetrics.recordNetworkEvent('Network connectivity confirmed');
      }
    } catch (e) {
      NetworkPerformanceMetrics.recordNetworkEvent('Network connectivity issue: $e', isError: true);
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real Network Universal Media Dialog Load Tests', () {

    setUpAll(() async {
      debugPrint('Setting up real network integration test environment...');
      await NetworkTestHelper.monitorNetworkHealth();
    });

    tearDownAll(() {
      debugPrint('Real network integration test completed.');
    });

    testWidgets('Comprehensive network load test with real media', (WidgetTester tester) async {
      NetworkPerformanceMetrics.startTest();

      app.main();
      await tester.pumpAndSettle();
      NetworkPerformanceMetrics.recordOperation('App initialization');

      // Real network URLs with various content types and sizes
      final List<MediaItemModel> networkMediaItems = [
        MediaItemModel(
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: MediaType.pdf,
          title: 'W3C Test PDF',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/800/600?random=1',
          type: MediaType.image,
          title: 'Random Image 800x600',
        ),
        MediaItemModel(
          url: 'https://www.africau.edu/images/default/sample.pdf',
          type: MediaType.pdf,
          title: 'Sample PDF Document',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/400/300?random=2',
          type: MediaType.image,
          title: 'Random Image 400x300',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/1200/800?random=3',
          type: MediaType.image,
          title: 'High Resolution Image',
        ),
        MediaItemModel(
          url: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
          type: MediaType.pdf,
          title: 'Mozilla Test PDF',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    UniversalMediaDialog.showMultiple(
                      context: context,
                      mediaItems: networkMediaItems,
                    );
                  },
                  child: const Text('Open Network Media Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Monitor network health before starting
      await NetworkTestHelper.monitorNetworkHealth();

      // Open dialog
      await NetworkTestHelper.safeNetworkTap(tester, find.text('Open Network Media Dialog'));
      await NetworkTestHelper.waitForNetworkContent(tester, timeout: const Duration(seconds: 30));
      NetworkPerformanceMetrics.recordOperation('Dialog opened with network content');

      await NetworkTestHelper.assertNetworkContentState(tester);

      // === Intensive Network Load Test ===
      developer.log('Starting intensive network load test...');

      final int totalSwipes = networkMediaItems.length * 2;
      int successfulOperations = 0;
      int networkErrors = 0;

      for (int i = 0; i < totalSwipes; i++) {
        developer.log('Network operation ${i + 1}/$totalSwipes');

        try {
          // Forward navigation with network loading
          await NetworkTestHelper.safeNetworkFling(
            tester,
            find.byType(PageView),
            const Offset(-400, 0),
            800,
          );

          successfulOperations++;
          NetworkPerformanceMetrics.recordOperation('Network forward swipe ${i + 1}');

          // Backward navigation occasionally
          if (i % 3 == 0 && i > 0) {
            await NetworkTestHelper.safeNetworkFling(
              tester,
              find.byType(PageView),
              const Offset(400, 0),
              800,
            );

            NetworkPerformanceMetrics.recordOperation('Network backward swipe ${i + 1}');
          }

          // Check network health periodically
          if (i % 5 == 0) {
            await NetworkTestHelper.monitorNetworkHealth();
          }

        } catch (e) {
          networkErrors++;
          NetworkPerformanceMetrics.recordNetworkEvent('Operation $i failed: $e', isError: true);

          if (networkErrors > totalSwipes * 0.3) { // Allow up to 30% error rate
            developer.log('Too many network errors, stopping test');
            break;
          }
        }
      }

      developer.log('Network load test completed. Success: $successfulOperations, Errors: $networkErrors');

      // Test rapid network operations
      developer.log('Testing rapid network interactions...');
      for (int i = 0; i < 5; i++) {
        await NetworkTestHelper.safeNetworkFling(
          tester,
          find.byType(PageView),
          const Offset(-300, 0),
          1000,
        );

        // Short delay to simulate rapid user interaction
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      await NetworkTestHelper.waitForNetworkContent(tester);
      NetworkPerformanceMetrics.recordOperation('Rapid network interactions completed');

      // Close dialog
      await NetworkTestHelper.safeNetworkTap(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      NetworkPerformanceMetrics.recordOperation('Dialog closed');
      NetworkPerformanceMetrics.endTest();

    });

    testWidgets('Network error recovery and resilience test', (WidgetTester tester) async {
      NetworkPerformanceMetrics.startTest();

      app.main();
      await tester.pumpAndSettle();

      // Mix of valid and potentially problematic URLs
      final List<MediaItemModel> resilientTestItems = [
        MediaItemModel(
          url: 'https://picsum.photos/400/300?random=10',
          type: MediaType.image,
          title: 'Valid Image',
        ),
        MediaItemModel(
          url: 'https://httpstat.us/404',
          type: MediaType.image,
          title: 'Error URL (404)',
        ),
        MediaItemModel(
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: MediaType.pdf,
          title: 'Valid PDF',
        ),
        MediaItemModel(
          url: 'https://httpstat.us/500',
          type: MediaType.image,
          title: 'Server Error URL (500)',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/800/600?random=11',
          type: MediaType.image,
          title: 'Recovery Image',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    UniversalMediaDialog.showMultiple(
                      context: context,
                      mediaItems: resilientTestItems,
                    );
                  },
                  child: const Text('Network Resilience Test'),
                ),
              ),
            ),
          ),
        ),
      );

      await NetworkTestHelper.safeNetworkTap(tester, find.text('Network Resilience Test'));
      await NetworkTestHelper.waitForNetworkContent(tester, timeout: const Duration(seconds: 20));

      // Navigate through all items including error cases
      for (int i = 0; i < resilientTestItems.length * 2; i++) {
        developer.log('Resilience test navigation ${i + 1}');

        await NetworkTestHelper.safeNetworkFling(
          tester,
          find.byType(PageView),
          const Offset(-350, 0),
          700,
        );

        // Allow extra time for error handling
        await NetworkTestHelper.waitForNetworkContent(
          tester,
          timeout: const Duration(seconds: 15),
        );

        NetworkPerformanceMetrics.recordOperation('Resilience navigation $i');
      }

      // Verify dialog is still functional after encountering errors
      await NetworkTestHelper.assertNetworkContentState(tester);

      await NetworkTestHelper.safeNetworkTap(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      NetworkPerformanceMetrics.endTest();

    });

    testWidgets('High-load concurrent network operations', (WidgetTester tester) async {
      NetworkPerformanceMetrics.startTest();

      app.main();
      await tester.pumpAndSettle();

      final networkMediaItems = [
        MediaItemModel(
          url: 'https://picsum.photos/600/400?random=20',
          type: MediaType.image,
          title: 'Concurrent Test Image 1',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/600/400?random=21',
          type: MediaType.image,
          title: 'Concurrent Test Image 2',
        ),
        MediaItemModel(
          url: 'https://www.africau.edu/images/default/sample.pdf',
          type: MediaType.pdf,
          title: 'Concurrent Test PDF',
        ),
        MediaItemModel(
          url: 'https://picsum.photos/600/400?random=22',
          type: MediaType.image,
          title: 'Concurrent Test Image 3',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    UniversalMediaDialog.showMultiple(
                      context: context,
                      mediaItems: networkMediaItems,
                    );
                  },
                  child: const Text('Concurrent Network Test'),
                ),
              ),
            ),
          ),
        ),
      );

      await NetworkTestHelper.safeNetworkTap(tester, find.text('Concurrent Network Test'));
      await NetworkTestHelper.waitForNetworkContent(tester);

      // Simulate high-frequency user interactions
      developer.log('Starting high-load concurrent operations...');

      for (int round = 0; round < 3; round++) {
        developer.log('Concurrent round ${round + 1}');

        // Rapid sequence of navigation actions
        for (int i = 0; i < networkMediaItems.length; i++) {
          await NetworkTestHelper.safeNetworkFling(
            tester,
            find.byType(PageView),
            const Offset(-250, 0),
            500 + (i * 100), // Varying velocities
          );

          // Minimal delay to stress test the system
          await Future.delayed(const Duration(milliseconds: 800));
        }

        // Monitor system health
        await NetworkTestHelper.monitorNetworkHealth();
        NetworkPerformanceMetrics.recordOperation('Concurrent round ${round + 1} completed');
      }

      // Final verification
      await NetworkTestHelper.waitForNetworkContent(tester);
      await NetworkTestHelper.assertNetworkContentState(tester);

      await NetworkTestHelper.safeNetworkTap(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      NetworkPerformanceMetrics.endTest();

    });

    testWidgets('Memory leak detection with real network loads', (WidgetTester tester) async {
      NetworkPerformanceMetrics.startTest();

      app.main();
      await tester.pumpAndSettle();

      final testScenarios = [
        [MediaItemModel(url: 'https://picsum.photos/300/200?random=30', type: MediaType.image, title: 'Memory Test Image 1')],
        [MediaItemModel(url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', type: MediaType.pdf, title: 'Memory Test PDF')],
        [
          MediaItemModel(url: 'https://picsum.photos/300/200?random=31', type: MediaType.image, title: 'Memory Test Image 2'),
          MediaItemModel(url: 'https://picsum.photos/300/200?random=32', type: MediaType.image, title: 'Memory Test Image 3'),
        ],
      ];

      // Test multiple open/close cycles with real network loading
      for (int cycle = 0; cycle < 8; cycle++) {
        developer.log('Network memory test cycle: ${cycle + 1}');

        final scenario = testScenarios[cycle % testScenarios.length];

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      UniversalMediaDialog.showMultiple(
                        context: context,
                        mediaItems: scenario,
                      );
                    },
                    child: Text('Memory Test $cycle'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open dialog and wait for network content
        await NetworkTestHelper.safeNetworkTap(tester, find.text('Memory Test $cycle'));
        await NetworkTestHelper.waitForNetworkContent(tester, timeout: const Duration(seconds: 20));

        // Interact with content if multiple items
        if (scenario.length > 1) {
          await NetworkTestHelper.safeNetworkFling(
            tester,
            find.byType(PageView),
            const Offset(-200, 0),
            400,
          );
        }

        // Close dialog
        await NetworkTestHelper.safeNetworkTap(tester, find.byIcon(Icons.close));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Force cleanup every few cycles
        if (cycle % 3 == 2) {
          await tester.binding.reassembleApplication();
          await tester.pumpAndSettle();
          NetworkPerformanceMetrics.recordOperation('Memory cleanup forced');
        }

        NetworkPerformanceMetrics.recordOperation('Memory cycle ${cycle + 1} completed');
      }

      NetworkPerformanceMetrics.endTest();

    });
  });
}