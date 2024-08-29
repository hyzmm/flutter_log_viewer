import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:log_viewer/src/pages/http_request_detail_page.dart';
import 'package:logger/logger.dart';

class SocketView extends StatelessWidget {
  const SocketView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
        listenable: SocketViewModel.instance,
        builder: (context, child) {
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: SocketViewModel.instance.outputs.length,
              itemBuilder: (context, index) {
                final item = SocketViewModel.instance.outputs[index];
                final (time, logType, dataType, data, tag) = item;

                return Card(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        logType == SocketLogType.up ? '↑' : '↓',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: logType == SocketLogType.up
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (tag != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 4, right: 16, bottom: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      tag,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateTimeFormat.onlyTime(time),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: theme.hintColor),
                                    )
                                  ],
                                ),
                              ),
                            if (data != null)
                              dataType == SocketDataType.text
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                          right: 16, bottom: 8),
                                      child: Text((data as String).trim()),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: JsonView.map(
                                        data,
                                        theme: JsonViewTheme(
                                            errorBuilder:
                                                jsonViewTheme.errorBuilder,
                                            closeIcon: jsonViewTheme.closeIcon,
                                            openIcon: jsonViewTheme.openIcon,
                                            defaultTextStyle:
                                                const TextStyle(fontSize: 12)),
                                      ),
                                    )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
  }
}

enum SocketLogType {
  up,
  down,
}

enum SocketDataType {
  text,
  json,
  binary,
}

// SocketLogType, SocketDataType, Data, External Tag
typedef RecordType = (
  DateTime,
  SocketLogType,
  SocketDataType,
  dynamic,
  String?
);

class SocketViewModel extends ChangeNotifier {
  static const kMaxRecords = 1000;
  static final instance = SocketViewModel();

  final List<RecordType> _outputs = [];

  List<RecordType> get outputs => _outputs;

  void addRecord(RecordType output) {
    _outputs.add(output);
    if (_outputs.length > kMaxRecords) {
      _outputs.removeAt(0);
    }

    assert(() {
      // ignore: avoid_print
      print(
          "[Socket] ${output.$2 == SocketLogType.down ? "↓" : '↑'} [${DateTimeFormat.onlyTime(output.$1)}] ${output.$5} ${output.$4}");
      return true;
    }());

    notifyListeners();
  }

  void clear() {
    _outputs.clear();
    notifyListeners();
  }
}
