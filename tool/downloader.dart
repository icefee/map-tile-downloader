part of tool;

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

String loopCreateDir(String path, {String basePath = '.'}) {
  List<String> pathSplit = path.split('/');
  String currentPath = basePath;
  late Directory dir;
  for (int i = 0; i < pathSplit.length; i++) {
    currentPath += '/' + pathSplit[i];
    dir = Directory(currentPath);
    if (dir.existsSync()) {
      continue;
    }
    dir.createSync();
  }
  return dir.path;
}

Future<void> loopDownloadTile(String url, String fileName) async {
  try {
    await Downloader.downloadFile(url, fileName: fileName);
  } catch (err) {
    // print('$url 下载失败, 重试中...');
    return loopDownloadTile(url, fileName);
  }
}

Future<void> downloadTile(int x, int y, int z, List<MapTileType> types) async {
  await Future.wait<void>(types.map((MapTileType mapType) {
    String fileName = loopCreateDir('tiles/${mapType.value}/$z/$x');
    return loopDownloadTile(
        MapTile.getTileUrl(mapType, x: x, y: y, z: z), fileName + '/$y.png');
  }));
}

class DownloadConfig {
  final Location leftTop;
  final Location rightBottom;
  final List<int> range;
  final List<MapTileType> types;
  final int thread;

  const DownloadConfig(
      this.leftTop,
      this.rightBottom,
      {
        required this.range,
        required this.types,
        this.thread = 20
      }
  );
}

Future<void> downloadTiles(DownloadConfig config) async {
  for (int z = config.range.first; z <= config.range.last; z++) {
    List<Tile> tiles = getTiles(config.leftTop, config.rightBottom, z);
    print('下载层级: $z / ${config.range.last}');
    var progress = ProgressBar(
        complete: (tiles.last.x - tiles.first.x + 1) *
            (tiles.last.y - tiles.first.y + 1));
    for (int x = tiles.first.x; x <= tiles.last.x; x++) {
      int start = tiles.first.y, end = tiles.last.y;
      for (int i = 0; i <= ((end - start) / config.thread).floor(); i++) {
        int from = start + i * config.thread,
            to = min(end, start + (i + 1) * config.thread - 1);
        int parts = to - from + 1;
        await Future.wait<void>(List.generate(
            parts, (int s) => downloadTile(x, from + s, z, config.types)));
        progress.update(progress.current + parts);
      }
    }
  }
  showCompleteLog();
}

void showCompleteLog() {
  print('''
  
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      
             指定范围的地图已下载完成.
             
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
     
  ''');
}
