import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HttpLogView extends StatelessWidget {
  const HttpLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: HttpLogModel.instance,
        builder: (context, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: HttpLogModel.instance.httpLogs.length,
            itemBuilder: (context, index) {
              final log = HttpLogModel.instance.httpLogs[index];
              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(log.method,
                              style: TextStyle(
                                color: _getMethodColor(log.method),
                                fontWeight: FontWeight.w700,
                              )),
                          _buildStatusCodeTag(log.statusCode),
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                final text = _dioRequestToCurl(log.request);
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text.rich(
                                      TextSpan(children: [
                                        const TextSpan(text: "Copy cURL "),
                                        TextSpan(
                                          text: text,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Copy as cURL")),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            log.uri.path.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: log.uri.toString()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text.rich(
                                      TextSpan(children: [
                                        const TextSpan(text: "Copy "),
                                        TextSpan(
                                            text: log.uri.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Copy")),
                        ],
                      ),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: _formatIntoHHMMSSmmm(log.startTime)),
                          const TextSpan(text: '\t'),
                          if (log.endTime != null)
                            TextSpan(
                              text:
                                  '${(log.endTime!.difference(log.startTime)).inMilliseconds}ms',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ]),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  String _formatIntoHHMMSSmmm(DateTime date) {
    return "${date.hour}:${date.minute}:${date.second}.${date.millisecond}";
  }

  Widget _buildStatusCodeTag(int? statusCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: (statusCode == null ? Colors.grey : Colors.green),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusCode?.toString() ?? "Sending",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class HttpLogModel with ChangeNotifier {
  static final instance = HttpLogModel();
  final List<HttpLog> _httpLogs = [];

  List<HttpLog> get httpLogs => _httpLogs;

  void add(HttpLog httpLog) {
    _httpLogs.add(httpLog);
    notifyListeners();
  }
}

class HttpLog {
  final String method;
  final DateTime startTime = DateTime.now();
  final Uri uri;
  DateTime? endTime;
  int? statusCode;
  RequestOptions request;
  Map<String, dynamic>? response;
  Exception? error;

  HttpLog({required this.method, required this.uri, required this.request});
}

class HttpLogInterceptor extends Interceptor {
  final int maxRecords;

  HttpLogInterceptor({this.maxRecords = 500});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final log =
        HttpLog(method: options.method, uri: options.uri, request: options);
    options.extra["log"] = log;
    HttpLogModel.instance.add(log);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final log = response.requestOptions.extra["log"] as HttpLog?;
    if (log == null) {
      handler.next(response);
      return;
    } else {
      log.endTime = DateTime.now();
      log.statusCode = response.statusCode;
      log.response = response.data as Map<String, dynamic>?;
      handler.next(response);
    }
  }

  @override
  void onError(err, ErrorInterceptorHandler handler) {
    final log = err.requestOptions.extra["log"] as HttpLog?;
    if (log == null) {
      handler.next(err);
      return;
    } else {
      log.endTime = DateTime.now();
      log.statusCode = err.response?.statusCode;
      log.error = err;
      handler.next(err);
    }
  }
}

Color _getMethodColor(String method) {
  switch (method) {
    case "GET":
      return Colors.green;
    case "POST":
      return Colors.blue;
    case "PUT":
      return Colors.orange;
    case "DELETE":
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _dioRequestToCurl(RequestOptions options) {
  final method = options.method;
  final uri = options.uri;
  final headers = options.headers;
  final data = options.data;
  final buffer = StringBuffer();
  buffer.write("curl -X $method ");
  headers.forEach((key, value) {
    buffer.write("-H '$key: $value' ");
  });
  if (data != null) {
    buffer.write("-d '$data' ");
  }
  buffer.write(uri.toString());
  return buffer.toString();
}
