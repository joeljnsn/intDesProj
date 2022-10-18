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
  })  : _mapController = mapController,
        _markerLat = markerLat,
        _markerLng = markerLng,
        _goalCoordinates = goalCoordinates,
        _startZoneCoordinates = startZoneCoordinates,
        super(key: key);

  final MapController _mapController;
  final BuildContext context;
  final double _markerLat;
  final double _markerLng;
  final List<LatLng> _goalCoordinates;
  final List<LatLng> _startZoneCoordinates;

  @override
  Widget build(BuildContext context) {
    ImageProvider mapBackground =
        const Image(image: AssetImage('Assets/MapBackground.png')).image;

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
                  [
                    Marker(
                      point: LatLng(_markerLat, _markerLng), //User marker
                      width: 20,
                      height: 20,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6)),
                      ),
                    )
                  ],
            ),
            PolygonLayer(
              polygonCulling: false,
              polygons: [
                Polygon(
                  points: _goalCoordinates,
                  color: const Color.fromRGBO(0, 255, 0, .4),
                  isFilled: true,
                ),
                Polygon(
                  points: _startZoneCoordinates,
                  color: const Color.fromRGBO(0, 0, 255, .4),
                  isFilled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
