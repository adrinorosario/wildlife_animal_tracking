import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

// 1. Model for our sightings
class WildlifeSighting {
  final LatLng position;
  final String title;
  final String imagePath;

  WildlifeSighting({
    required this.position, 
    required this.title, 
    required this.imagePath
  });
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Initial Position: Coorg/Western Ghats region
  static const LatLng _initialCenter = LatLng(12.658833, 75.604339);

  // 2. The SINGLE source of truth for markers
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

  void addExternalMarker(double lat, double lng, String title) async {
  final markerId =
      MarkerId(DateTime.now().millisecondsSinceEpoch.toString());

  setState(() {
    _markers.add(
      Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    );
  });

   print("Marker added at: $lat , $lng");
  print("Total markers now: ${_markers.length}");

  final controller = await _controller.future;
  controller.animateCamera(
    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17),
  );
}


  // 3. UI Method to show the photo preview
  void _showPhotoPreview(WildlifeSighting sighting) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sighting.title, 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text("Location: ${sighting.position.latitude}, ${sighting.position.longitude}"),
          ],
        ),
      ),
    );
  }

  // 4. Logic to add a new pin to the UI
  void _addSightingToMap(WildlifeSighting sighting) {
    final markerId = MarkerId(DateTime.now().millisecondsSinceEpoch.toString());
    
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: sighting.position,
          infoWindow: InfoWindow(
            title: sighting.title,
            snippet: 'Tap to view photo',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () {
            _showPhotoPreview(sighting);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Map Layer
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialCenter,
            zoom: 15.0,
          ),
          padding: const EdgeInsets.only(top: 90.0, right: 2.0),
          mapType: MapType.satellite,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          markers: _markers, // Points to the Set at line 26
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        
        // The Simulation Button Layer
        // Positioned(
        //   bottom: 120, // Positioned above the bottom nav bar
        //   right: 20,
        //   child: FloatingActionButton(
        //     backgroundColor: Colors.orange,
        //     child: const Icon(Icons.camera_enhance, color: Colors.white),
        //     onPressed: () {
        //       // Simulating the "Take Photo" result
        //       _addSightingToMap(WildlifeSighting(
        //         position: const LatLng(12.6595, 75.6055), // Slightly offset from center
        //         title: "New Tiger Sighting",
        //         imagePath: "temp_path",
        //       ));
        //     },
        //   ),
        // ),
      ],
    );
  }

  // Camera Helper
  Future<void> _zoomToUser() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_initialCenter, 17));
  }
}