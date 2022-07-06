import 'dart:io';

abstract class Downloader {
  static Future<void> downloadFile(String url, { String? fileName, Function(double p)? onProcess }) async {
    HttpClient client = HttpClient();
    Uri target = Uri.parse(url);
    HttpClientRequest request = await client.getUrl(target);
    HttpClientResponse response = await request.close();
    int contentLength = response.contentLength;
    List<int> data = [];
    int downloaded = 0;
    response.listen((List<int> event) {
      data = [...data, ...event];
      downloaded += event.length;
      onProcess?.call(downloaded / contentLength);
    }, onError: (err) {
      throw err;
    }, onDone: () {
      File(fileName ?? target.pathSegments.last).writeAsBytes(data);
    });
  }
}
