import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navigator/components/my_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  TextEditingController _searchController = TextEditingController();

  static const LatLng _kabarak = LatLng(-0.16703, 35.96601);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KABARAK UNIVERSITY MAP"),
        backgroundColor: Color.fromARGB(255, 116, 31, 31),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: 'Search by city'),
                ),
              ),
              IconButton(
                onPressed: () async {
                  String searchTerm = _searchController.text;
                  if (searchTerm.isNotEmpty) {
                    await _moveToLocation(searchTerm);
                  }
                },
                icon: Icon(Icons.search),
              )
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _kabarak,
                zoom: 18,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: {
                Marker(
                  markerId: MarkerId("_sourcelocation"),
                  infoWindow: InfoWindow(title: 'Kabarak University'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _kabarak,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToLocation(String searchTerm) async {
    // You need to implement the logic to fetch coordinates based on the search term
    // For demonstration purposes, let's assume you have a method that does this
    print("this is the search term" + searchTerm);
    LatLng? location = await _fetchLocationCoordinates(searchTerm);
    if (location != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 28,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found')),
      );
    }
  }

  // This is a placeholder method, you need to implement the logic to fetch coordinates from a Places API
  Future<LatLng?> _fetchLocationCoordinates(String searchTerm) async {
    // Here you should implement the logic to fetch coordinates from a Places API
    // For demonstration purposes, I'll return a fixed location based on search term
    if (searchTerm.toLowerCase() == 'lecture room 5') {
      return LatLng(-0.16739720273813738, 35.96616969685804);
    } else if (searchTerm.toLowerCase() == 'kabarak university') {
      return LatLng(-0.16703, 35.96601);
    } else {
      return null;
    }
  }
}
