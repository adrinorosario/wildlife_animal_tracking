import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {

final Completer<GoogleMapController> _controller = Completer();

  //  Initial Position 
  static const LatLng _initialCenter = LatLng(12.658833, 75.604339);

//this is where the pins should live. this is a mock pin for now
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('test_pin_1'),
      position: _initialCenter,
      infoWindow: const InfoWindow(
        title: 'Elephant Sighting',
        snippet: 'Spotted near the river',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
  };

  @override
Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: EdgeInsets.only(top: 100),
          initialCameraPosition: const CameraPosition(
            target: _initialCenter,
            zoom: 15.0,
          ),
          mapType: MapType.satellite, // Satellite view
          myLocationEnabled: true,    // Shows the blue dot for user location
          myLocationButtonEnabled: true, // We'll build a custom one later
          compassEnabled: true,
          markers: _markers,          // Displays  pins
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        
        // 3. Optional Overlay UI 
        Positioned(
          top: 50,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                onPressed: () => _zoomToUser(),
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to move camera to user 
  Future<void> _zoomToUser() async {
    final GoogleMapController controller = await _controller.future;
    // For now, just centers on the initial point
    controller.animateCamera(CameraUpdate.newLatLngZoom(_initialCenter, 17));
  }
}

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Wildlife Tracker Map'),
//         backgroundColor: Colors.transparent,
//       ),
//       // backgroundColor: Colors.yellow,
//       body: Center(child: Text('Map will go here!')),
//     );
//   }
// }
