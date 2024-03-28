import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navigator/components/my_drawer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class CustomPlace {
  final String title;
  final String description;
  final LatLng position;

  CustomPlace({
    required this.title,
    required this.description,
    required this.position,
  });
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  final LatLng _center = const LatLng(-0.16703, 35.96601);
  String _originQuery = '';
  String _destinationQuery = '';
  List<CustomPlace> _customPlaces = [
    CustomPlace(
      title: 'Lecture room 5',
      description: 'First room in the East wing left side of Admin Block',
      position: LatLng(-0.167338, 35.966310),
    ),
    CustomPlace(
      title: 'Physics Lab 2',
      description: 'Near physics lab 1',
      position: LatLng(-0.167776, 35.965688),
    ),
    CustomPlace(
      title: 'General Bio Lab',
      description: 'General Biology Lab',
      position: LatLng(-0.167481, 35.966121),
    ),
    // Add more custom places as needed
  ];

  void _onOriginSearchSubmitted(String query) {
    setState(() {
      _originQuery = query;
    });
  }

  void _onDestinationSearchSubmitted(String query) {
    setState(() {
      _destinationQuery = query;
    });
  }

  Set<Marker> _getFilteredMarkers() {
    return _customPlaces
        .where((place) =>
            place.title.toLowerCase().contains(_originQuery.toLowerCase()) ||
            place.title.toLowerCase().contains(_destinationQuery.toLowerCase()))
        .map((place) => Marker(
              markerId: MarkerId(place.title),
              position: place.position,
              infoWindow: InfoWindow(
                title: place.title,
                snippet: place.description,
              ),
            ))
        .toSet();
  }

  Set<Polyline> _drawRoute() {
    if (_originQuery.isNotEmpty && _destinationQuery.isNotEmpty) {
      // Here, you can implement logic to fetch route coordinates
      // For demonstration purposes, let's draw a polyline between two custom places
      LatLng origin = _customPlaces
          .firstWhere((place) =>
              place.title.toLowerCase() == _originQuery.toLowerCase())
          .position;
      LatLng destination = _customPlaces
          .firstWhere((place) =>
              place.title.toLowerCase() == _destinationQuery.toLowerCase())
          .position;

      return {
        Polyline(
          polylineId: PolylineId('route'),
          points: [origin, destination],
          color: Colors.blue,
          width: 3,
        ),
      };
    } else {
      return {};
    }
  }

  //void _drawRoute() {
  // TODO: Implement route drawing logic using Polyline
  // You can use the _originQuery and _destinationQuery to get the origin and destination
  //}

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
                  controller: _originController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: 'Origin'),
                  onChanged: _onOriginSearchSubmitted,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Handle origin search button click
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _destinationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: 'Destination'),
                  onChanged: _onDestinationSearchSubmitted,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Handle destination search button click
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 18.0,
              ),
              markers: _getFilteredMarkers(),
              polylines: _drawRoute(),
            ),
          ),
        ],
      ),
    );
  }
}
