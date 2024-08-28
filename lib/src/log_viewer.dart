import 'package:flutter/material.dart';
import 'package:log_viewer/src/tab_views/http_log_view.dart';

class LogViewer extends StatelessWidget {
  static final pageView = OverlayEntry(
    builder: (context) => const LogViewer(),
  );

  static void showDebugButton(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = OverlayEntry(builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Navigator.of(context).overlay?.insert(pageView),
          child: const Banner(
            message: 'LOG',
            textDirection: TextDirection.ltr,
            location: BannerLocation.topEnd,
          ),
        );
      });
      Overlay.of(context).insert(overlay);
    });
  }

  const LogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => pageView.remove(),
          ),
          title: const Text("Log Viewer"),
        ),
        body: const DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Text("HTTP"),
                  Text("Socket"),
                  Text("Log"),
                ],
              ),
              Expanded(
                  child: TabBarView(children: [
                HttpLogView(),
                HttpLogView(),
                HttpLogView(),
              ]))
            ],
          ),
        ),
      ),
    );
  }
}
