import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationPickerMap extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialPosition;

  const LocationPickerMap({
    super.key,
    this.initialAddress,
    this.initialPosition,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  final MapController? _mapController = MapController();
  LatLng _selectedPosition = LatLng(7.3697, 125.6517); // Default: Panabo City
  String _selectedAddress = '';
  bool _isLoading = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      _getAddressFromPosition(widget.initialPosition!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      Position position = await _locationService.getCurrentPosition();
      final newPosition = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedPosition = newPosition;
      });
      
      _mapController?.move(newPosition, 15);
      
      await _getAddressFromPosition(newPosition);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromPosition(LatLng position) async {
    try {
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _selectedAddress = address;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromPosition(position);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'position': _selectedPosition,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoading ? null : _getCurrentLocation,
            tooltip: 'Use current location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 15,
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.declutter.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Address Display Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, 
                          color: Color(0xFF4CAF50), 
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress.isEmpty 
                        ? 'Tap on map to select location' 
                        : _selectedAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Confirm Button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _selectedAddress.isEmpty ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
