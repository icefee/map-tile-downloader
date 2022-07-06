import 'dart:math';

class Point {
  late double x;
  late double y;
  Point(this.x, this.y);
}

class Tile {
  late int x;
  late int y;
  Tile(this.x, this.y);
}

class Location {
  late double lng;
  late double lat;
  Location(this.lng, this.lat);
}

abstract class MapTool {

  static final List<int> Wm = [75, 60, 45, 30, 15, 0];
  static final List<List<double>> bv = [
    [0.0015702102444, 111320.7020616939, 1704480524535203, -10338987376042340, 26112667856603880, -35149669176653700, 26595700718403920, -10725012454188240, 1800819912950474, 82.5],
    [8.277824516172526E-4, 111320.7020463578, 6.477955746671607E8, -4.082003173641316E9, 1.077490566351142E10, -1.517187553151559E10, 1.205306533862167E10, -5.124939663577472E9, 9.133119359512032E8, 67.5],
    [0.00337398766765, 111320.7020202162, 4481351.045890365, -2.339375119931662E7, 7.968221547186455E7, -1.159649932797253E8, 9.723671115602145E7, -4.366194633752821E7, 8477230.501135234, 52.5],
    [0.00220636496208, 111320.7020209128, 51751.86112841131, 3796837.749470245, 992013.7397791013, -1221952.21711287, 1340652.697009075, -620943.6990984312, 144416.9293806241, 37.5],
    [-3.441963504368392E-4, 111320.7020576856, 278.2353980772752, 2485758.690035394, 6070.750963243378, 54821.18345352118, 9540.606633304236, -2710.55326746645, 1405.483844121726, 22.5],
    [-3.218135878613132E-4, 111320.7020701615, 0.00369383431289, 823725.6402795718, 0.46104986909093, 2351.343141331292, 1.58060784298199, 8.77738589078284, 0.37238884252424, 7.45]
  ];

  static Point pointToPixel(Point pt, int zoom) {
    return Point((pt.x * pow(2, zoom - 18)).truncateToDouble(), (pt.y * pow(2, zoom - 18)).truncateToDouble());
  }

  static Tile pixelToTile(pt) {
    return Tile((pt.x * 1.0 / 256).truncate(), (pt.y * 1.0 / 256).truncate());
  }

  static lngLatToPoint(lng, lat) {
    Location point = Location(
        ft(lng, -180, 180),
        lt(lat, -74, 74)
    );

    late List<double> c;
    for(int d = 0; d < Wm.length; d ++) {
      if(point.lat > Wm[d]) {
        c = bv[d];
        break;
      }
    }
    if(c.isEmpty) {
      for(int d = Wm.length; d >= 0; d --) {
        if(point.lat <= -Wm[d]) {
          c = bv[d];
          break;
        }
      }
    }

    Point fpt = Sx(point, c);
    return Point(fixedToDouble(fpt.x), fixedToDouble(fpt.y));
  }

  static double fixedToDouble(double num, [int fractionDigits = 2]) {
    return double.parse(num.toStringAsFixed(2));
  }

  static Tile lngLatToTile(double lng, double lat, int zoom) {
    return pixelToTile(pointToPixel(lngLatToPoint(lng, lat), zoom));
  }

  static Point Sx(Location a, List<double> b) {
    double c = b[0] + b[1] * a.lng.abs();
    double d = a.lat.abs() / b[9];
    double e = b[2] + b[3] * d + b[4] * d * d + b[5] * d * d * d + b[6] * d * d * d * d + b[7] * d * d * d * d * d + b[8] * d * d * d * d * d * d;
    return Point(c * (0 > a.lng ? -1 : 1), e * (0 > a.lat ? -1 : 1));
  }

  static double ft(double a, double b, double c) {
    for (; a > c; ) a -= c - b;
    for (; a < b; ) a += c - b;
    return a;
  }

  static double lt(double a, double b, double c) {
    return max<double>(min<double>(a, c), b);
  }
}
