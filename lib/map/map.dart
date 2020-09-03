import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:koye_kos/camp/camp_utils.dart';
import 'package:koye_kos/map/map_detail.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/db.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';
import '../utils.dart';

class MapFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            selected: mapModel.tentSelcted,
            label: Text('Tent', style: TextStyle(color: mapModel.tentSelcted ? Colors.white : Colors.black),),
            onSelected: (value) => mapModel.onFilterChipSelected(value, CampFeature.Tent),
            backgroundColor: Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            checkmarkColor: Colors.white,
            elevation: 1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

          ),
          SizedBox(width: 4),
          FilterChip(
            selected: mapModel.hammockSelcted,
            label: Text('Hammock', style: TextStyle(color: mapModel.hammockSelcted ? Colors.white : Colors.black),),
            onSelected: (value) => mapModel.onFilterChipSelected(value, CampFeature.Hammock),
            backgroundColor: Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            checkmarkColor: Colors.white,
            elevation: 1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],),
    );
  }
}


class Map extends StatefulWidget {
  @override
  State createState() => MapState();
}

class MapState extends State<Map> {
  MapboxMapController _mapController;
  StreamSubscription _symbolsSubscription;

  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: 'pk.eyJ1Ijoic2FtdWRldiIsImEiOiJja2R4aTd5aTgzMzF0MzBwYXh5bjV0M3k2In0.DZiALUfM4GMSMqYOlnn6Ug',
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: const CameraPosition(
                target: LatLng(63.4, 10.23), zoom: 11.0),
            onMapLongClick: _onMapLongClick,
            onMapClick: _onMapClick,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            myLocationEnabled: mapModel.locationTracking,
            myLocationTrackingMode: mapModel.trackingMode,
            compassEnabled: false,
            styleString: mapModel.mapStyle,
            trackCameraPosition: true,
          ),
          Padding(
            padding: EdgeInsets.only(top: Scaffold.of(context).appBarMaxHeight),
            child: MapFilter(),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        visible: mapModel.dialVisible,
        overlayColor: Colors.transparent,
        overlayOpacity: 0,
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(child: GpsButtonWidget()),
          SpeedDialChild(child: MapStyleButtonWidget()),
        ],
      ),
    );
  }

  void _onMapLongClick(_, LatLng coordinates) {
    print('longclick');
    final mapModel = context.read<MapModel>();
    if (mapModel.clickState == ClickState.LongClick) {
      _mapController.removeSymbol(mapModel.longCLickSymbol);
    }
    SymbolOptions symbolOptions = mapModel.onMapLongClick(coordinates);
    _mapController.addSymbol(symbolOptions).then(mapModel.setLongClickSymbol);
    _showBottomSheetBuilder(coordinates.toPoint());
  }

  void _onMapClick(_, LatLng coordinates) {
    print('click');
    final mapModel = context.read<MapModel>();
    if (mapModel.clickState == ClickState.LongClick) {
      _mapController.removeSymbol(mapModel.longCLickSymbol);
    }
    mapModel.onMapClick(coordinates);
    // TODO: does not work until symbol tap is consumed before propogating here
    //Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  // TODO: disable propagation.
  void _onSymbolTapped(Symbol symbol) {
    print('symbol tapped');
    final mapModel = context.read<MapModel>();
    mapModel.onSymbolTapped();
    if (!symbol.data.containsKey('id')) return;
    final String campId = symbol.data['id'] as String;
    final Camp camp = mapModel.getCamp(campId);
    showBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return OpenContainerCamp(
          camp,
          closedScreen: MarkerBottomSheet(),
        );
      },
    );
  }

  void _onStyleLoaded() {
    // Subscribe to stream events
    _symbolsSubscription =
        context.read<MapModel>().streamController.stream.listen((element) {
          _mapController.clearSymbols();

          // TODO: batch add with addSymbols
          element.forEach((element) {
            _mapController.addSymbol(element.options, {'id': element.id});
          });
        });
    //print(MediaQueryData.fromWindow(WidgetsBinding.instance.window).devicePixelRatio);
    addImageFromAsset('marker-red', 'assets/symbols/location_red.png');
    addImageFromAsset('marker-black', 'assets/symbols/location_black.png');
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    return _mapController.addImage(name, list);
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    // TODO: disable tap event propagating to mapCLick listener https://github.com/tobrun/flutter-mapbox-gl/pull/381
    _mapController.onSymbolTapped.add(_onSymbolTapped);
    //_mapController.addListener(() {print('map changed.');});
  }


  void _showBottomSheetBuilder(Point<double> coordinates) {
    showBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Provider<Point<double>>.value(
        value: coordinates,
        child: PointBottomSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    _symbolsSubscription?.cancel();
    super.dispose();
  }
}

class GpsButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return SizedBox(
      width: 50,
      height: 50,
      child: FloatingActionButton(
        onPressed: mapModel.onGpsClick,
        backgroundColor: Colors.grey.shade50,
        child: Icon(
          Icons.gps_fixed,
          color: mapModel.locationTracking ? Colors.blue : Colors.black87,
        ),
      ),
    );
  }
}

class MapStyleButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Material(
      type: MaterialType.circle,
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      color: Colors.grey.shade50,
      child: SizedBox(
        width: 35,
        height: 35,
        child: PopupMenuButton<MapStyle>(
          child: Icon(
            Icons.layers,
            size: 20,
            color: Colors.black87,
          ),
          onSelected: mapModel.onStyleSelected,
          itemBuilder: (context) => <PopupMenuEntry<MapStyle>>[
            PopupMenuItem<MapStyle>(
              value: MapStyle.Outdoors,
              child: Text('Outdoor'),
            ),
            PopupMenuItem<MapStyle>(
              value: MapStyle.Satellite,
              child: Text('Satellite'),
            ),
          ],
        ),
      ),
    );
  }
}
