import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider extends ChangeNotifier {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  LatLng? _pointA;
  LatLng? _pointB;
  LatLng? _pointC; // Point C is the destination
  String _selectedPoint = 'A'; // Tracks which point is being selected
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  GoogleMapController? get controller => _controller;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  String get selectedPoint => _selectedPoint;

  // Set the GoogleMapController
  void setController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  // Calculate the distance between two LatLng points in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) *
            cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  // Set Point A
  void setPointA(LatLng point, BuildContext context) {
    _pointA = point;
    _markers.add(Marker(markerId: MarkerId('A'), position: point));
    notifyListeners();
  }

  // Set Point B, ensuring it's within 500 meters of Point A
  void setPointB(LatLng point, BuildContext context) {
    if (_pointA != null && _calculateDistance(_pointA!, point) <= 0.5) {
      _pointB = point;
      _markers.add(Marker(markerId: MarkerId('B'), position: point));
      notifyListeners();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Point B must be within 500m of Point A')),
      );
    }
  }

  // Set Point C, ensuring it's within 10 kilometers of Point B
  void setPointC(LatLng point, BuildContext context) {
    if (_pointB != null && _calculateDistance(_pointB!, point) <= 10.0) {
      _pointC = point;
      _markers.add(Marker(markerId: MarkerId('Z'), position: point));
      _saveHistory(); // Save history when Point C is set
      notifyListeners();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Point Z must be within 10km of Point B')),
      );
    }
  }

  // Set the currently selected point (A, B, or C)
  void setSelectedPoint(String point) {
    _selectedPoint = point;
    notifyListeners();
  }

  // Add a polyline to the map
  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  // Calculate and display the route between points A, B, and C
  Future<void> calculateRoute() async {
    if (_pointA == null || _pointB == null || _pointC == null) return;

    _polylineCoordinates.clear();
    _polylines.clear();

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> points = [];

    // Get route from A to B
    PolylineResult result1 = await polylinePoints.getRouteBetweenCoordinates(
      apitoken, // Replace with your actual API token
      PointLatLng(_pointA!.latitude, _pointA!.longitude),
      PointLatLng(_pointB!.latitude, _pointB!.longitude),
    );

    if (result1.points.isNotEmpty) {
      for (var point in result1.points) {
        points.add(LatLng(point.latitude, point.longitude));
      }
    }

    // Get route from B to C
    PolylineResult result2 = await polylinePoints.getRouteBetweenCoordinates(
      apitoken, // Replace with your actual API token
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

  // Save the history of points A, B, and C to Firestore
  void _saveHistory() {
    if (_pointA != null && _pointB != null && _pointC != null) {
      _firestore.collection('history').add({
        'pointA': GeoPoint(_pointA!.latitude, _pointA!.longitude),
        'pointB': GeoPoint(_pointB!.latitude, _pointB!.longitude),
        'pointC': GeoPoint(_pointC!.latitude, _pointC!.longitude),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Fetch the history from Firestore
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => {
      'pointA': doc['pointA'],
      'pointB': doc['pointB'],
      'pointC': doc['pointC'],
      'timestamp': doc['timestamp'],
    })
        .toList();
  }
}
