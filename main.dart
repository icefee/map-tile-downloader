import 'dart:math';
import 'dart:io';
import './tool/map.dart';
import './tool/tile.dart';
import './tool/downloader.dart';

int thread = 20;

void main(List<String> args) {
  // var point = MapTool.lngLatToTile(113.238831, 23.281719, 14);
  // print('${point.x}, ${point.y}');

  // String url = 'http://wallpaperswide.com/download/cute_anime_girl_2-wallpaper-3554x1999.jpg';
  // downloadFile(url);
  // Future.wait([randomInt(2), randomInt(5)]).then((value) => print(value));
  downloadTiles(parseLocationArg(args[0]), parseLocationArg(args[1]),
      parseRangeArg(args[2]),
      types: args.length > 3 ? parseMapType(args[3]) : null);
}

Location parseLocationArg(String arg) {
  List<String> location = arg.split(',');
  return Location(double.parse(location.first), double.parse(location.last));
}

List<int> parseRangeArg(String arg) {
  List<String> range = arg.split(',');
  return range.map((e) => int.parse(e)).toList();
}

List<MapTileType> parseMapType(String arg) {
  List<String> argTypes = arg.split(',');
  return argTypes.map((String type) {
    if (type == MapTileType.Normal.value) {
      return MapTileType.Normal;
    } else if (type == MapTileType.Sate.value) {
      return MapTileType.Sate;
    } else if (type == MapTileType.Mix.value) {
      return MapTileType.Mix;
    }
    throw ArgumentError('地图类型错误');
  }).toList();
}

Future<int> randomInt(int seconds) async {
  var random = Random();
  await Future.delayed(Duration(seconds: seconds));
  return random.nextInt(1200);
}

Future<void> downloadFile(String url) async {
  await Downloader.downloadFile(url, onProcess: (double v) {
    print('process: ${v * 100} %');
  });
}

List<Tile> getTiles(Location loc1, Location loc2, int zoom) {
  Tile leftBottom = MapTool.lngLatToTile(loc1.lng, loc1.lat, zoom);
  Tile rightTop = MapTool.lngLatToTile(loc2.lng, loc2.lat, zoom);
  return [leftBottom, rightTop];
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
    print('create $currentPath');
    dir.create();
  }
  return dir.path;
}

Future<void> loopDownloadTile(String url, String fileName) async {
  try {
    await Downloader.downloadFile(url, fileName: fileName);
  } catch (err) {
    print('$url 下载失败, 重试中...');
    return loopDownloadTile(url, fileName);
  }
}

Future<void> downloadTile(int x, int y, int z,
    {List<MapTileType>? types}) async {
  print('pending { x: $x, y: $y, z: $z }');
  await Future.wait<void>(
      (types ?? [MapTileType.Normal, MapTileType.Sate, MapTileType.Mix])
          .map((MapTileType mapType) {
    String fileName = loopCreateDir('tiles/${mapType.value}/$z/$x');
    return loopDownloadTile(
        MapTile.getTileUrl(mapType, x: x, y: y, z: z), fileName + '/$y.png');
  }));
}

Future<void> downloadTiles(Location loc1, Location loc2, List<int> range,
    {List<MapTileType>? types}) async {
  for (int z = range[0]; z <= range[1]; z++) {
    List<Tile> tiles = getTiles(loc1, loc2, z);
    for (int x = tiles[0].x; x <= tiles[1].x; x++) {
      int start = tiles[0].y, end = tiles[1].y;
      for (int i = 0; i <= ((end - start) / thread).floor(); i++) {
        int from = start + i * thread,
            to = min(end, start + (i + 1) * thread - 1);
        await Future.wait<void>(List.generate(to - from + 1,
            (int s) => downloadTile(x, from + s, z, types: types)));
        // await threadFeature(start + i * thread, min(end, start + (i + 1) * thread - 1));
      }
    }
  }
}
