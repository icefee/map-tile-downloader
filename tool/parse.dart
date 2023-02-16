part of tool;

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
