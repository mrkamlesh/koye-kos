
import 'package:mapbox_gl/mapbox_gl.dart';


enum MapStyle { Outdoors, Satellite }

class MapBoxMapStyle {
  static const OUTDOORS =
      'mapbox://styles/samudev/ckdxjbopx44gj1aorm1eumxo6'; /*MapboxStyles.OUTDOORS;*/
  static const SATELLITE = MapboxStyles.SATELLITE;

  static String getMapStyle(MapStyle style) {
    switch (style) {
      case MapStyle.Outdoors:
        return OUTDOORS;
      case MapStyle.Satellite:
        return SATELLITE;
      default:
        return OUTDOORS;
    }
  }
}