import 'dart:math';
import 'dart:io';
import 'package:console/console.dart';
import './tool/map.dart';
import './tool/tile.dart';
import './tool/downloader.dart';

void main(List<String> args) {
  print('''
    
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      │                                           │
      │         map tile downloader v1.2          │
      │             build 2023.01.12              │
      │         https://map-tile.surge.sh         │
      │                                           │
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
      
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
        如果你对参数不熟悉, 请尽量通过生成的批处理文件(.bat)下载.
        访问: https://map-tile.surge.sh 生成
        备用地址: https://code-in-life.stormkit.dev/maptile
        确保生成的批处理文件跟本程序在同一目录, 且本程序的名称为 tile.exe
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
      
    ''');

  if (args.isEmpty) {
    print('''
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
    
            当前已进入手动下载模式, 需要手动指定参数
        
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
    ''');
    /*
    var shell = ShellPrompt();
    shell.loop().listen((line) {
      shell.stop();
    });
     */
    getInputArgs();
  } else {
    downloadTiles(parseLocationArg(args[0]), parseLocationArg(args[1]),
        parseRangeArg(args[2]), parseMapType(args[3]), parseThread(args[4]));
  }
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

Future<void> getInputArgs() async {
  double lng = await readInputValue<double>(
      '输入中心点经度(lng): ', (s) => s != null && s.abs() < 180, double.tryParse,
      errorMessage: '输入的经度不合法, 应该介于 -180 ~ 180');
  double lat = await readInputValue<double>(
      '输入中心点纬度(lat): ', (s) => s != null && s.abs() < 90, double.tryParse,
      errorMessage: '输入的经度不合法, 应该介于 -90 ~ 90');
  double radius = await readInputValue<double>(
      '输入地图范围(km): ', (s) => s != null && s.abs() > .5, double.tryParse,
      errorMessage: '输入的值不合法, 必需大于0.5');
  List<String> types = ['n', 's', 's'];
  String mapTypes = await readInputValue<String>(
      '输入需要下载的地图类型(n: 常规, s: 卫星, m: 混合), 用逗号(,)隔开: ',
      (s) => s != null && validateMapTypes(s, types),
      (s) => s,
      errorMessage: '非法的地图类型, 只接受n,s,m三种类型');
  String parsedMapTypes =
      mapTypes.replaceAllMapped(RegExp(r'[nsm]'), (Match m) {
    if (m[0] == 'n') {
      return 'normal';
    } else if (m[0] == 's') {
      return 'sate';
    } else if (m[0] == 'm') {
      return 'mix';
    }
    throw ArgumentError('地图类型错误');
  });
  double lngInKm = .009696868273018407;
  double latInKm = .00899937224408571;
  await downloadTiles(
      Location(lng - lngInKm * radius, lat - latInKm * radius),
      Location(lng + lngInKm * radius, lat + latInKm * radius),
      [3, 19],
      parseMapType(parsedMapTypes),
      40);
  print('''
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
    
            如果没有更多的下载任务, 请关闭窗口
            或者重新指定参数开始下载
        
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
    ''');
  getInputArgs();
}

typedef InputValidator<T> = bool Function(T? input);
typedef NumberParser<T> = T? Function(String input);

Future<T> readInputValue<T>(
    String message, InputValidator<T> validator, NumberParser<T> parser,
    {String? errorMessage}) async {
  String input = await readInput(message);
  var value = parser(input);
  bool valid = validator(value);
  if (valid) {
    return value!;
  }
  if (errorMessage != null) {
    print(errorMessage);
  }
  return readInputValue<T>(message, validator, parser,
      errorMessage: errorMessage);
}

bool validateMapTypes(String input, List<String> types) {
  List<String> argTypes = input.split(',');
  return !argTypes.every((s) => !types.contains(s));
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
  // print('pending { x: $x, y: $y, z: $z }');
  await Future.wait<void>(types.map((MapTileType mapType) {
    String fileName = loopCreateDir('tiles/${mapType.value}/$z/$x');
    return loopDownloadTile(
        MapTile.getTileUrl(mapType, x: x, y: y, z: z), fileName + '/$y.png');
  }));
}

Future<void> downloadTiles(Location loc1, Location loc2, List<int> range,
    List<MapTileType> types, int thread) async {
  for (int z = range.first; z <= range.last; z++) {
    List<Tile> tiles = getTiles(loc1, loc2, z);
    print('下载层级: $z / ${range.last}');
    var progress = ProgressBar(
        complete: (tiles.last.x - tiles.first.x + 1) *
            (tiles.last.y - tiles.first.y + 1));
    for (int x = tiles.first.x; x <= tiles.last.x; x++) {
      int start = tiles.first.y, end = tiles.last.y;
      for (int i = 0; i <= ((end - start) / thread).floor(); i++) {
        int from = start + i * thread,
            to = min(end, start + (i + 1) * thread - 1);
        int parts = to - from + 1;
        await Future.wait<void>(List.generate(
            parts, (int s) => downloadTile(x, from + s, z, types)));
        progress.update(progress.current + parts);
      }
    }
  }
  print('''
  
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      
             指定范围的地图已下载完成.
             
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
     
  ''');
}
