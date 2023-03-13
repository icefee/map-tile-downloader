import 'dart:io';
import './tool/tool.dart';

void main(List<String> args) {
  print('''
    
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      │                                           │
      │         map tile downloader v1.3.1        │
      │             build 2023.03.13              │
      │         https://map-tile.surge.sh         │
      │                                           │
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
      
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
      
        如果你对参数不熟悉, 请尽量通过生成的批处理文件(.bat)下载.
        访问: https://map-tile.surge.sh 生成
        备用地址: https://c.stormkit.dev/maptile
        确保生成的批处理文件跟本程序在同一目录, 且本程序的名称为 tile.exe
        
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
      
    ''');

  if (args.isEmpty) {
    print('''
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
    
            当前已进入手动下载模式, 需要手动指定参数
        
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
    ''');

    File file = File('./map.xml');
    try {
      if (file.existsSync()) {
        print('发现配置文件map.xml, 读取参数中..');
        Location? location = readConfigFromXml(file);
        if (location != null) {
          int radius = 10;
          print('参数读取成功, 矩形选定范围 $radius km, 开始下载.');
          Location leftTop = Location(
              location.lng - lngInKm * radius, location.lat - latInKm * radius);
          Location rightBottom = Location(
              location.lng + lngInKm * radius, location.lat + latInKm * radius);
          downloadTiles(DownloadConfig(leftTop, rightBottom,
              range: [3, 19],
              types: parseMapType('normal,sate,mix'),
              thread: 40));
        } else {
          throw Exception('经纬度读取失败');
        }
      } else {
        throw Exception('配置文件读取失败');
      }
    } catch (err) {
      print(err);
      print('读取参数失败, 请手动指定参数');
      getInputArgs();
    }
  } else {
    downloadTiles(DownloadConfig(
        parseLocationArg(args[0]), parseLocationArg(args[1]),
        range: parseRangeArg(args[2]),
        types: parseMapType(args[3]),
        thread: parseThread(args[4])));
  }
}
