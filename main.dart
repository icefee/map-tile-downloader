import 'dart:math';
import 'dart:io';
import 'package:console_bars/console_bars.dart';
import './tool/map.dart';
import './tool/tile.dart';
import './tool/downloader.dart';

void main(List<String> args) {
  downloadTiles(parseLocationArg(args[0]), parseLocationArg(args[1]),
      parseRangeArg(args[2]), parseMapType(args[3]), parseThread(args[4]));
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

int parseThread(String arg) {
  List<String> params = arg.split('=');
  return int.parse(params.last);
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
    // print('create $currentPath');
    dir.create();
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
  // print('pending { x: $x, y: $y, z: $z }');
  await Future.wait<void>(types.map((MapTileType mapType) {
    String fileName = loopCreateDir('tiles/${mapType.value}/$z/$x');
    return loopDownloadTile(
        MapTile.getTileUrl(mapType, x: x, y: y, z: z), fileName + '/$y.png');
  }));
}

Future<void> downloadTiles(Location loc1, Location loc2, List<int> range,
    List<MapTileType> types, int thread) async {

  print(
    '''
    
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      │                                           │
      │             离线地图下载工具v1.0              │
      │         https://map-tile.surge.sh         │
      │                                           │
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
      
    '''
  );

  FillingBar fillingBar = FillingBar(
      desc: '地图下载中',
      total: range.last - range.first + 1,
      time: true,
      percentage: true,
      space: '-',
      fill: '=',
      width: 20
  );
  for (int z = range.first; z <= range.last; z ++) {
    List<Tile> tiles = getTiles(loc1, loc2, z);
    for (int x = tiles.first.x; x <= tiles.last.x; x ++) {
      int start = tiles.first.y, end = tiles.last.y;
      for (int i = 0; i <= ((end - start) / thread).floor(); i ++) {
        int from = start + i * thread,
            to = min(end, start + (i + 1) * thread - 1);
        await Future.wait<void>(List.generate(
            to - from + 1, (int s) => downloadTile(x, from + s, z, types)));
      }
    }
    fillingBar.increment();
  }
  print('地图下载完成.');
}
