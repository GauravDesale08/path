import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'HistoryScreen.dart';
import 'MapProvider.dart';
import 'main.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Maps'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map widget
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
                provider.setPointA(position, context);
                provider.setSelectedPoint('B');
              } else if (provider.selectedPoint == 'B') {
                provider.setPointB(position, context);
                provider.setSelectedPoint('C');
              } else if (provider.selectedPoint == 'C') {
                provider.setPointC(position, context);
                provider.calculateRoute();
                provider.setSelectedPoint('A');
              }
            },
          ),
          // Buttons for selecting points
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('A');
                  },
                  child: Text('Select A'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('B');
                  },
                  child: Text('Select B'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    provider.setSelectedPoint('C');
                  },
                  child: Text('Select Z'),
                ),
              ],
            ),
          ),
          // Instructions and current selection
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
      // Floating action button for calculating route
      floatingActionButton: FloatingActionButton(
        onPressed: provider.calculateRoute,
        child: Icon(Icons.directions),
        backgroundColor: Colors.teal,
        tooltip: 'Calculate Route',
      ),
    );
  }
}
