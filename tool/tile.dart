enum MapTileType {
  Normal(value: 'normal'),
  Sate(value: 'sate'),
  Mix(value: 'mix');

  const MapTileType({required this.value});
  final String value;
}

abstract class MapTile {
  static String getBaseUrl(int x) {
    return 'http://maponline${x % 4}.bdimg.com';
  }

  static String getTileUrl(MapTileType type, { required int x, required int y, required int z }) {
    final String baseUrl = getBaseUrl(x);
    Map<MapTileType, String> templateMap = {
      MapTileType.Normal:
          '$baseUrl/tile/?qt=vtile&x=$x&y=$y&z=$z&styles=pl&scaler=1&udt=20220317&from=jsapi3_0',
      MapTileType.Sate:
          '$baseUrl/starpic/?qt=satepc&u=x=$x;y=$y;z=$z;v=009;type=sate&fm=46&udt=20220317',
      MapTileType.Mix:
          '${baseUrl}/tile/?qt=vtile&x=$x&y=$y&z=$z&styles=sl&udt=20220317'
    };
    return templateMap[type]!;
  }
}
