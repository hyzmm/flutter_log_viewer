import 'package:flutter/material.dart';
import 'package:log_viewer/utils/format_date.dart';
import 'package:logger/logger.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: LogViewModel.instance,
        builder: (context, snapshot) {
          final outputs = LogViewModel.instance.outputs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Level.off,
                    Level.trace,
                    Level.debug,
                    Level.info,
                    Level.warning,
                    Level.error,
                    Level.fatal
                  ]
                      .map(
                        (level) => ChoiceChip(
                            selected: LogViewModel.instance.hasFilter(level),
                            label:
                                Text(level == Level.off ? "ALL" : level.name),
                            onSelected: (value) {
                              if (value) {
                                LogViewModel.instance.addFilter(level);
                              } else {
                                LogViewModel.instance.removeFilter(level);
                              }
                            }),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemBuilder: (context, index) {
                      final item = outputs[index];
                      return Card(
                        child: ListTile(
                          horizontalTitleGap: 0,
                          visualDensity: VisualDensity.compact,
                          dense: true,
                          leading: Text(
                            item.level.name[0].toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(item.level)),
                          ),
                          title: Text(item.origin.message.toString()),
                          subtitle: Text(formatIntoHHMMSSmmm(item.origin.time)),
                        ),
                      );
                    },
                    itemCount: outputs.length,
                  ),
                ),
              ),
            ],
          );
        });
  }
}

class LogViewOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    LogViewModel.instance.addOutput(event);
  }
}

class LogViewModel extends ChangeNotifier {
  static const kMaxOutputs = 1000;

  static final LogViewModel instance = LogViewModel();
  final List<OutputEvent> _outputs = <OutputEvent>[];
  Set<Level> filters = {Level.off};

  void addFilter(Level level) {
    filters.add(level);
    notifyListeners();
  }

  void removeFilter(Level level) {
    // 如果只有 ALL 选中了，那么不允许取消
    if (level == Level.off &&
        filters.length == 1 &&
        filters.single == Level.off) {
      return;
    }
    filters.remove(level);
    notifyListeners();
  }

  bool hasFilter(Level level) {
    return filters.contains(level);
  }

  void addOutput(OutputEvent output) {
    _outputs.add(output);
    if (_outputs.length > kMaxOutputs) {
      _outputs.removeAt(0);
    }
    notifyListeners();
  }

  void removeOutput(OutputEvent output) {
    _outputs.remove(output);
    notifyListeners();
  }

  void clearOutputs() {
    _outputs.clear();
    notifyListeners();
  }

  List<OutputEvent> get outputs => _outputs.where((element) {
        if (filters.contains(Level.off)) {
          return true;
        }
        return filters.contains(element.level);
      }).toList();

  void clear() {
    _outputs.clear();
    notifyListeners();
  }
}

Color _getLevelColor(Level level) {
  if (level == Level.trace) {
    return Colors.grey;
  }
  if (level == Level.debug) {
    return Colors.blue;
  }
  if (level == Level.info) {
    return Colors.green;
  }
  if (level == Level.warning) {
    return Colors.orange;
  }
  if (level == Level.error) {
    return Colors.red;
  }
  if (level == Level.fatal) {
    return Colors.purple;
  }
  return Colors.black;
}
