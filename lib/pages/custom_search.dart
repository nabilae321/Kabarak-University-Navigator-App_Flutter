import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navigator/components/my_drawer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum TtsState { playing, stopped, paused, continued }

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
  Completer<GoogleMapController>? _controller;
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  final LatLng _center = const LatLng(-0.16703, 35.96601);
  String _originQuery = '';
  String _destinationQuery = '';
  MapType _currentMapType = MapType.normal;
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
    CustomPlace(
      title: 'kabuo',
      description: 'Near zarepath mess',
      position: LatLng(-0.1658, 35.9651),
    ),
    CustomPlace(
      title: 'Klaw 5',
      description: 'Near convocation hall',
      position: LatLng(-0.1699, 35.9645),
    ),
  ];

  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  late Position _currentPosition;
  List<LatLng> _routeCoordinates = [];

  @override
  void initState() {
    super.initState();
    _controller = Completer();
    flutterTts = FlutterTts();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

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

  Future<List<LatLng>> _fetchRouteCoordinates(
      LatLng origin, LatLng destination) async {
    final apiKey = 'YOUR_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List<dynamic> routes = decodedResponse['routes'];
        if (routes.isNotEmpty) {
          final String points = routes[0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          return decodedPoints;
        }
      } else {
        print('Failed to fetch route. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return [];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> decodedCoordinates = [];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latLngScale = 1 / 1e5;
      double latitude = lat * latLngScale;
      double longitude = lng * latLngScale;
      decodedCoordinates.add(LatLng(latitude, longitude));
    }
    return decodedCoordinates;
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
              icon: place.title
                      .toLowerCase()
                      .contains(_destinationQuery.toLowerCase())
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
            ))
        .toSet();
  }

  Future<Set<Polyline>> _drawRoute() async {
    if (_originQuery.isNotEmpty && _destinationQuery.isNotEmpty) {
      CustomPlace? originPlace = _customPlaces.firstWhereOrNull(
          (place) => place.title.toLowerCase() == _originQuery.toLowerCase());
      CustomPlace? destinationPlace = _customPlaces.firstWhereOrNull((place) =>
          place.title.toLowerCase() == _destinationQuery.toLowerCase());

      if (originPlace != null && destinationPlace != null) {
        LatLng origin = originPlace.position;
        LatLng destination = destinationPlace.position;

        _routeCoordinates = await _fetchRouteCoordinates(origin, destination);

        // Fetch distance matrix
        _fetchDistanceMatrix(origin, destination);

        return {
          Polyline(
            polylineId: PolylineId('route'),
            points: _routeCoordinates,
            color: Colors.blue,
            width: 3,
          ),
        };
      }
    }
    return {};
  }

  Future<void> _fetchDistanceMatrix(LatLng origin, LatLng destination) async {
    final apiKey = 'YOUR_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final rows = decodedResponse['rows'];
        if (rows.isNotEmpty) {
          final elements = rows[0]['elements'];
          if (elements.isNotEmpty) {
            final distanceText = elements[0]['distance']['text'];
            final durationText = elements[0]['duration']['text'];
            _showDistanceAndDurationAlert(distanceText, durationText);
            _speakDistanceAndDuration(distanceText, durationText);
          }
        }
      } else {
        print(
            'Failed to fetch distance matrix. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching distance matrix: $e');
    }
  }

  void _showDistanceAndDurationAlert(
      String distanceText, String durationText) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Distance and Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance: $distanceText'),
              Text('Duration: $durationText'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _speakDistanceAndDuration(
      String distanceText, String durationText) async {
    try {
      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(1.0);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(
          'The distance is $distanceText and the duration is $durationText');
    } catch (e) {
      print("Error speaking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KABARAK UNIVERSITY MAP"),
        backgroundColor: Color.fromARGB(255, 116, 31, 31),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: MyDrawer(),
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
            child: FutureBuilder<Set<Polyline>>(
              future: _drawRoute(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      if (_controller == null) {
                        _controller = Completer<GoogleMapController>();
                        _controller!.complete(controller);
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 18.0,
                    ),
                    mapType: _currentMapType,
                    markers: _getFilteredMarkers(),
                    polylines: snapshot.data!,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onCameraMove: (position) {
                      // Do something on camera move
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.centerRight,
        child: FloatingActionButton(
          onPressed: () {
            _showMapTypeSelectionDrawer(context);
          },
          child: Icon(Icons.layers),
        ),
      ),
    );
  }

  void _showMapTypeSelectionDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 150,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Normal'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.normal;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Hybrid'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.hybrid;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Satellite'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.satellite;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
