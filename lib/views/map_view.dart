import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Geolocator geolocator = Geolocator();
  Position? _position;
  late StreamSubscription<Position> positionStream;
  CameraPosition _cameraPosition = const CameraPosition(
    zoom: 14.7,
    target: LatLng(37.43296265331129, -122.08832357078792),
  );
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      log('Location permissions are permanently denied');
    }
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      log(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
      setState(
        () {
          _cameraPosition = CameraPosition(
            zoom: 10,
            target: LatLng(position!.latitude, position.longitude),
          );
          markers.add(
            Marker(
              markerId: const MarkerId('value'),
              position: LatLng(position.latitude, position.longitude),
            ),
          );
        },
      );
      _controller.future.then(
        (value) => value.animateCamera(
          CameraUpdate.newCameraPosition(
            _cameraPosition,
          ),
        ),
      );
    });
    // _position = await Geolocator.getCurrentPosition();
    // log(_position!.latitude.toString());
    // log(_position!.longitude.toString());
    // setState(() {
    //   _cameraPosition = CameraPosition(
    //     zoom: 5,
    //     target: LatLng(positionStream.la, _position!.longitude),
    //   );
    // });
  }

  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    _position = await Geolocator.getCurrentPosition();
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _position!.latitude,
            _position!.longitude,
          ),
          zoom: 10.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToTheLake(),
        child: const Icon(Icons.location_searching),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                zoomControlsEnabled: false,
                onTap: (latlng) async {
                  try {
                    List<Placemark> placemarks = await placemarkFromCoordinates(
                      latlng.latitude,
                      latlng.longitude,
                    );
                    log(placemarks[0].name!);
                    log(placemarks[0].country!);
                  } catch (e) {
                    log(e.toString());
                  }
                },
                markers: markers.toSet(),
                initialCameraPosition: _cameraPosition,
                onMapCreated: (controller) {
                  _controller.complete(controller);
                },
              ),
            ),
            Container(
              alignment: Alignment.center,
              height: 100,
              width: double.maxFinite,
              color: Colors.blueAccent,
              child: const Text('Map View'),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }
}
