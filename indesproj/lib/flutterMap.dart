import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:indesproj/firebase_communication.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

const double borderRadius = 25;
BoxDecoration mapDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(borderRadius),
  boxShadow: const [
    BoxShadow(color: Colors.black, spreadRadius: 6),
  ],
);

class flutterMap extends StatelessWidget {
  const flutterMap({
    Key? key,
    required MapController mapController,
    required this.context,
    required double markerLat,
    required double markerLng,
    required List<LatLng> goalCoordinates,
    required List<LatLng> startZoneCoordinates,
    required List<LatLng> crystalCoordinates,
    required List<List<LatLng>> powerUpCoordinates,
  })  : _mapController = mapController,
        _markerLat = markerLat,
        _markerLng = markerLng,
        _goalCoordinates = goalCoordinates,
        _startZoneCoordinates = startZoneCoordinates,
        _crystalCoordinates = crystalCoordinates,
        _powerUpCoordinates = powerUpCoordinates,
        super(key: key);

  final MapController _mapController;
  final BuildContext context;
  final double _markerLat;
  final double _markerLng;
  final List<LatLng> _goalCoordinates;
  final List<LatLng> _startZoneCoordinates;
  final List<LatLng> _crystalCoordinates;
  final List<List<LatLng>> _powerUpCoordinates;

  @override
  Widget build(BuildContext context) {
    ImageProvider mapBackground =
        const Image(image: AssetImage('assets/MapBackground.png')).image;

    //List<Polygon> powerUpPolygons = [];
    List<Marker> powerUpMarkers = [];

    for (List<LatLng> powerUpCoordinate in _powerUpCoordinates) {
      // powerUpPolygons.add(
      //   Polygon(
      //     points: powerUpCoordinate,
      //     color: const Color.fromRGBO(123, 0, 255, 0.4),
      //     isFilled: false,
      //     borderColor: const Color.fromRGBO(123, 0, 255, 0.4),
      //     borderStrokeWidth: 2,
      //   )
      // );

      double centerPowerUpLat =
          (powerUpCoordinate[0].latitude + powerUpCoordinate[3].latitude) / 2;
      double centerPowerUpLng =
          (powerUpCoordinate[0].longitude + powerUpCoordinate[1].longitude) / 2;

      powerUpMarkers.add(Marker(
        point: LatLng(centerPowerUpLat, centerPowerUpLng),
        width: 40,
        height: 40,
        builder: (context) => Image.asset(
          "assets/buttons/png/powerup.png",
          width: 40,
          height: 40,
        ),
      ));
    }

    return Container(
      decoration: mapDecoration,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
        ),
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(57.70630741457879,
                11.940503180030372), // set map center to LatLng(0, 0),
            zoom: 17.5,
            interactiveFlags: InteractiveFlag.none,
          ),
          mapController: _mapController,
          /*nonRotatedChildren: [
            AttributionWidget.defaultWidget(
              source: 'OpenStreetMap contributors',
              onSourceTapped: null,
            ),
          ],*/
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //userAgentPackageName: 'com.example.app',
            ),
            OverlayImageLayer(overlayImages: [
              OverlayImage(
                  opacity: 1,
                  bounds: LatLngBounds(
                      //Här vill vi ha mapController.bounds, men den är late
                      LatLng(57.707322920657525, 11.942013102927401),
                      LatLng(57.70529635967982, 11.938978529834595)),
                  imageProvider: mapBackground)
            ]),
            MarkerLayer(
              markers: Provider.of<FirebaseConnection>(context).userMarkers +
                  powerUpMarkers +
                  [
                    Marker(
                      point: LatLng(_markerLat, _markerLng), //User marker
                      width: 24,
                      height: 24,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 4,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              )
                            ]),
                      ),
                    ),
                    Marker(
                      point: LatLng(
                          ((_goalCoordinates[0].latitude +
                                  _goalCoordinates[3].latitude) /
                              2),
                          ((_goalCoordinates[0].longitude +
                                  _goalCoordinates[1].longitude) /
                              2)),
                      width: 50,
                      height: 51,
                      builder: (context) => Image.asset(
                        "assets/buttons/png/Coin.png",
                        width: 50,
                        height: 51,
                      ),
                    ),
                    Marker(
                      point: (_crystalCoordinates.isNotEmpty)
                          ? LatLng(
                              ((_crystalCoordinates[0].latitude +
                                      _crystalCoordinates[3].latitude) /
                                  2),
                              ((_crystalCoordinates[0].longitude +
                                      _crystalCoordinates[1].longitude) /
                                  2))
                          : LatLng(0, 0),
                      width: 81,
                      height: 84,
                      builder: (context) => Image.asset(
                        "assets/buttons/png/futureCoin.png",
                        width: 81,
                        height: 84,
                      ),
                    ),
                    Marker(
                      point: LatLng(
                          ((_startZoneCoordinates[0].latitude +
                                  _startZoneCoordinates[3].latitude) /
                              2),
                          ((_startZoneCoordinates[0].longitude +
                                  _startZoneCoordinates[1].longitude) /
                              2)),
                      width: 80,
                      height: 80,
                      builder: (context) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(77, 157, 224, .4),
                          border: Border.all(
                            color: const Color.fromRGBO(77, 157, 224, 1),
                            width: 6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
            ),
            // PolygonLayer(polygonCulling: false, polygons: [
            //   Polygon(
            //     points: _goalCoordinates,
            //     color: const Color.fromRGBO(0, 255, 0, .4),
            //     isFilled: true,
            //   ),
            //   Polygon(
            //     points: _startZoneCoordinates,
            //     color: const Color.fromRGBO(77, 157, 224, .4),
            //     borderColor: const Color.fromRGBO(77, 157, 224, 1),
            //     borderStrokeWidth: 5,
            //     isFilled: true,
            //   ),
            //   Polygon(
            //     points: _crystalCoordinates,
            //     color: const Color.fromRGBO(255, 255, 0, .4),
            //     isFilled: true,
            //   ),
            // ] //+ powerUpPolygons,
            //     ),
          ],
        ),
      ),
    );
  }
}
