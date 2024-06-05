import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For formatting timestamp

import 'MapProvider.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: provider.fetchHistory(), // Fetching history
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching history')); // Error message
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No history found')); // No data message
          }

          List<Map<String, dynamic>> history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length, // Number of items
            itemBuilder: (context, index) {
              var item = history[index];
              GeoPoint pointA = item['pointA'];
              GeoPoint pointB = item['pointB'];
              GeoPoint pointC = item['pointC'];
              Timestamp timestamp = item['timestamp'];

              return GestureDetector(
                onTap: () {
                  provider.setPointA(LatLng(pointA.latitude, pointA.longitude), context); // Set point A
                  provider.setPointB(LatLng(pointB.latitude, pointB.longitude), context); // Set point B
                  provider.setPointC(LatLng(pointC.latitude, pointC.longitude), context); // Set point C
                  provider.calculateRoute(); // Calculate route
                  Navigator.pop(context); // Navigate back
                },
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  elevation: 4.0, // Card elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Card padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align start
                      children: [
                        Text(
                          'A: (${pointA.latitude}, ${pointA.longitude})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.0), // Spacing
                        Text(
                          'B: (${pointB.latitude}, ${pointB.longitude})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.0), // Spacing
                        Text(
                          'C: (${pointC.latitude}, ${pointC.longitude})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.0), // Spacing
                        Text(
                          'Time: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}', // Formatted timestamp
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
