import 'package:flutter/material.dart';
import 'package:log_viewer/src/tab_views/http_log_view.dart';

class LogViewer extends StatefulWidget {
  static void showDebugButton(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = OverlayEntry(
          canSizeOverlay: true,
          builder: (context) {
            return Positioned(
              top: 0,
              right: 0,
              width: 60,
              height: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const LogViewer())),
                child: const Banner(
                  message: 'LOG',
                  textDirection: TextDirection.ltr,
                  location: BannerLocation.topEnd,
                ),
              ),
            );
          });
      Overlay.of(context).insert(overlay);
    });
  }

  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    _controller = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HttpLogModel.instance.clear();
          },
          child: const Text("Clear"),
        ),
        appBar: AppBar(
          title: const Text("Log Viewer"),
        ),
        body: Column(
          children: [
            TabBar(
              controller: _controller,
              tabs: const [
                Text("HTTP"),
                Text("Socket"),
                Text("Log"),
              ],
            ),
            Expanded(
                child: TabBarView(controller: _controller, children: const [
              HttpLogView(),
              HttpLogView(),
              HttpLogView(),
            ]))
          ],
        ),
      ),
    );
  }
}
