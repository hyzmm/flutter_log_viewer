import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:log_viewer/src/tab_views/http_log_view.dart';
import 'package:log_viewer/utils/format_date.dart';

final jsonViewTheme = JsonViewTheme(
    openIcon: const Text("➡️", style: TextStyle(color: Colors.white)),
    closeIcon: const Text("⬅️", style: TextStyle(color: Colors.white)),
    errorBuilder: (context, value) {
      if (value == null) {
        return const Text("null", style: TextStyle(color: Colors.white));
      }
      return const Text("Error");
    });

class HttpRequestDetailPage extends StatelessWidget {
  final HttpLog log;

  const HttpRequestDetailPage(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Detail")),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [
              Text("Request"),
              Text("Response"),
            ]),
            Expanded(
                child: TabBarView(children: [
              _RequestTab(log: log),
              _ResponseTab(log: log),
            ]))
          ],
        ),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final HttpLog log;

  const _RequestTab({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatus(theme),
          _buildRequestUri(theme),
          Headers(headers: log.request.headers),
          _buildParams(theme),
          _buildBody(),
        ],
      ),
    );
  }

  Card _buildStatus(ThemeData theme) {
    final duration = log.endTime?.difference(log.startTime).inMilliseconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(log.method,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: getRequestMethodColor(log.method))),
                  Text("method", style: theme.textTheme.labelSmall)
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(duration?.toString() ?? '-',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: _getDurationColor(duration))),
                  Text("ms", style: theme.textTheme.labelSmall)
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(log.statusCode.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: _getStatusCodeColor(log.statusCode))),
                  Text("status code", style: theme.textTheme.labelSmall)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestUri(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        showTrailingIcon: false,
        dense: true,
        title: Text(
          log.request.uri.toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: theme.textTheme.titleSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 130, child: Text("Request time")),
                    Text(formatIntoHHMMSSmmm(log.startTime),
                        style: theme.textTheme.titleSmall),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 130, child: Text("Response time")),
                    Text(
                        log.endTime == null
                            ? "Sending"
                            : formatIntoHHMMSSmmm(log.endTime!),
                        style: theme.textTheme.titleSmall),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildParams(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        showTrailingIcon: false,
        enabled: log.request.queryParameters.isNotEmpty,
        title:
            const Text("Params", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                for (final entry in log.request.queryParameters.entries)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child:
                            Text(entry.key, style: theme.textTheme.titleSmall),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(entry.value.toString(),
                            style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildBody() {
    return Card(
      child: ExpansionTile(
        showTrailingIcon: false,
        enabled: log.request.data != null,
        title:
            const Text("Body", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          if (log.request.data != null)
            JsonView.map(
              log.request.data,
              theme: jsonViewTheme,
            ),
        ],
      ),
    );
  }
}

class _ResponseTab extends StatelessWidget {
  final HttpLog log;

  const _ResponseTab({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Headers(headers: log.responseHeaders ?? {}),
        ),
        if (log.response != null) _buildResponseBody(),
      ],
    );
  }

  _buildResponseBody() {
    return JsonView.map(
      log.response!,
      theme: jsonViewTheme,
    );
  }
}

Color _getDurationColor(int? duration) {
  if (duration == null) return Colors.grey;
  if (duration < 100) return Colors.green;
  if (duration < 500) return Colors.orange;
  if (duration < 1000) return Colors.red;
  return Colors.purple;
}

Color _getStatusCodeColor(int? statusCode) {
  if (statusCode == null) return Colors.grey;
  if (statusCode >= 200 && statusCode < 300) return Colors.green;
  if (statusCode >= 300 && statusCode < 400) return Colors.orange;
  if (statusCode >= 400 && statusCode < 500) return Colors.red;
  if (statusCode >= 500) return Colors.purple;
  return Colors.grey;
}

class Headers extends StatelessWidget {
  final Map<String, dynamic> headers;

  const Headers({super.key, required this.headers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        showTrailingIcon: false,
        title: const Text("Headers",
            style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Table(
              children: headers.entries.map((e) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(e.key, style: theme.textTheme.titleSmall),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: e.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Copied ${e.value}"),
                            ),
                          );
                        },
                        child: Text(
                          e.value.toString(),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
