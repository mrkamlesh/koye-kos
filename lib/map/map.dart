import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:koye_kos/camp/camp_utils.dart';
import 'package:koye_kos/map/map_detail.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'map_actions.dart';
import 'map_filter.dart';
import 'map_model.dart';
import '../utils.dart';

class Map extends StatefulWidget {
  @override
  State createState() => MapState();
}

class MapState extends State<Map> with SingleTickerProviderStateMixin {
  MapboxMapController _mapController;
  StreamSubscription _symbolsSubscription;
  AnimationController _filterAnimationController;

  @override
  void initState() {
    _filterAnimationController = AnimationController(
      value: 1.0,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 75),
      vsync: this,
    )..addStatusListener(context.read<MapModel>().onAnimationStatusChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken:
                'pk.eyJ1Ijoic2FtdWRldiIsImEiOiJja2R4aTd5aTgzMzF0MzBwYXh5bjV0M3k2In0.DZiALUfM4GMSMqYOlnn6Ug',
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition:
                const CameraPosition(target: LatLng(63.4, 10.23), zoom: 11.0),
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
            child: AnimatedBuilder(
              animation: _filterAnimationController,
              builder: (context, child) {
                return FadeScaleTransition(
                  animation: _filterAnimationController,
                  child: child,
                );
              },
              child: Visibility(
                visible: mapModel.animationNotDismissed,
                child: MapFilter(),
              ),
            ),
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
    if (mapModel.animationRunningForwardOrComplete) {
      _filterAnimationController.reverse();
    } else {
      _filterAnimationController.forward();
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
        context.read<MapModel>().campSymbolStream.listen((element) {
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
    _filterAnimationController?.dispose();
    super.dispose();
  }
}
