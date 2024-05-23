import 'package:flutter/material.dart';
import 'package:google_map/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MapProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      home: MapScreen(),
    );
  }
}

class MapProvider extends ChangeNotifier {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  LatLng? _pointA;
  LatLng? _pointB;
  LatLng? _pointC; // Point C is the destination
  String _selectedPoint = 'A'; // Tracks which point is being selected

  GoogleMapController? get controller => _controller;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  String get selectedPoint => _selectedPoint;

  void setController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  void setPointA(LatLng point) {
    _pointA = point;
    _markers.add(Marker(markerId: MarkerId('A'), position: point));
    notifyListeners();
  }

  void setPointB(LatLng point) {
    _pointB = point;
    _markers.add(Marker(markerId: MarkerId('B'), position: point));
    notifyListeners();
  }

  void setPointC(LatLng point) {
    _pointC = point;
    _markers.add(Marker(markerId: MarkerId('Z'), position: point));
    notifyListeners();
  }

  void setSelectedPoint(String point) {
    _selectedPoint = point;
    notifyListeners();
  }

  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  Future<void> calculateRoute() async {
    if (_pointA == null || _pointB == null || _pointC == null) return;

    _polylineCoordinates.clear();
    _polylines.clear();

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> points = [];

    PolylineResult result1 = await polylinePoints.getRouteBetweenCoordinates(
      apitoken,
      PointLatLng(_pointA!.latitude, _pointA!.longitude),
      PointLatLng(_pointB!.latitude, _pointB!.longitude),
    );

    if (result1.points.isNotEmpty) {
      for (var point in result1.points) {
        points.add(LatLng(point.latitude, point.longitude));
      }
    }

    PolylineResult result2 = await polylinePoints.getRouteBetweenCoordinates(
      apitoken,
      PointLatLng(_pointB!.latitude, _pointB!.longitude),
      PointLatLng(_pointC!.latitude, _pointC!.longitude),
    );

    if (result2.points.isNotEmpty) {
      for (var point in result2.points) {
        points.add(LatLng(point.latitude, point.longitude));
      }
    }

    _polylineCoordinates.addAll(points);
    addPolyline(Polyline(
      polylineId: PolylineId('route'),
      points: _polylineCoordinates,
      color: Colors.blue,
      width: 5,
    ));
  }
}

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Maps'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(20.5937, 78.9629), // Default to India
              zoom: 5,
            ),
            markers: provider.markers,
            polylines: provider.polylines,
            onMapCreated: (controller) {
              provider.setController(controller);
            },
            onTap: (LatLng position) {
              if (provider.selectedPoint == 'A') {
                provider.setPointA(position);
                provider.setSelectedPoint('B');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Point A selected')),
                );
              } else if (provider.selectedPoint == 'B') {
                provider.setPointB(position);
                provider.setSelectedPoint('C');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Point B selected')),
                );
              } else if (provider.selectedPoint == 'C') {
                provider.setPointC(position);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Point Z selected')),
                );
              }
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue, // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // rounded corners
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('A');
                  },
                  child: Text('Select A'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green, // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // rounded corners
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('B');
                  },
                  child: Text('Select B'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red, // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // rounded corners
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('Z');
                  },
                  child: Text('Select Z'),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.3,
            builder: (context, scrollController) {
              return Container(
                color: Colors.white,
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      title: Text('Current Selection: ${provider.selectedPoint}'),
                      subtitle: Text(
                          'Tap on the map to set the location for Point ${provider.selectedPoint}'),
                    ),
                    ListTile(
                      title: Text('Instructions'),
                      subtitle: Text(
                          '1. Select Point A, B, and C by tapping the buttons and then the map.\n'
                              '2. Click the Calculate Route button to see the route.'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.calculateRoute,
        child: Icon(Icons.directions),
        backgroundColor: Colors.teal,
        tooltip: 'Calculate Route',
      ),
    );
  }
}
