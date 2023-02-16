part of tool;

Location? readConfigFromXml(File file) {
  String xml = file.readAsStringSync();
  try {
    XmlDocument document = XmlDocument.parse(xml);
    XmlElement configNode = document.findElements('config').first;
    String getAttr(String attr) => configNode.findElements(attr).first.children.first.text;
    return Location(
        double.parse(getAttr('lng')),
        double.parse(getAttr('lat'))
    );
  }
  catch (err) {
    return null;
  }
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

Future<void> getInputArgs() async {
  double lng = await readInputValue<double>(
      '输入中心点经度(lng): ', (s) => s != null && s.abs() <= 180, double.tryParse,
      errorMessage: '输入的经度不合法, 应该介于 -180 ~ 180');
  double lat = await readInputValue<double>(
      '输入中心点纬度(lat): ', (s) => s != null && s.abs() <= 90, double.tryParse,
      errorMessage: '输入的纬度不合法, 应该介于 -90 ~ 90');
  double radius = await readInputValue<double>(
      '输入地图范围(km): ', (s) => s != null && s >= .5 && s <= 200, double.tryParse,
      errorMessage: '输入的范围不合法, 应该介于 0.5 ~ 200');
  List<String> types = ['n', 's', 's'];
  String mapTypes = await readInputValue<String>(
      '输入需要下载的地图类型(n: 常规, s: 卫星, m: 混合), 用逗号(,)隔开: ',
          (s) => s != null && validateMapTypes(s, types),
          (s) => s,
      errorMessage: '输入的地图类型不合法, 只能接受n,s,m三种类型');
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
  await downloadTiles(
      DownloadConfig(
          Location(lng - lngInKm * radius, lat - latInKm * radius),
          Location(lng + lngInKm * radius, lat + latInKm * radius),
          range: [3, 19],
          types: parseMapType(parsedMapTypes),
          thread: 40
      )
  );
  print('''
      ┏┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┓
    
            如果没有更多的下载任务, 请关闭窗口
            或者重新指定参数开始下载
        
      ┗┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┛
    ''');
  getInputArgs();
}

bool validateMapTypes(String input, List<String> types) {
  List<String> argTypes = input.split(',');
  return !argTypes.every((s) => !types.contains(s));
}
